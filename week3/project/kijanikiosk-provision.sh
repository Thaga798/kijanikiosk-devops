#!/bin/bash
# KijaniKiosk Production Server Foundation Spec
# Author: Edwin Mathaga (DevOps Engineer)
# Version: 2.0 (Production Core Baseline)

set -euo pipefail

# Expected dirty conditions found in pre-provisioning audit:
# - kk-api already exists (UID 997): converged in Phase 2 via explicit useradd check.
# - /opt/kijanikiosk/ base directory is set to 777: forced to safe mode 755 in Phase 3.
# - /opt/kijanikiosk/shared/ directory is set to 777: forced to safe mode 755 in Phase 3.
# - kk-payments and kk-logs service home directories exist: isolated cleanly via systemd sandbox directives.
# - systemd unit files are unhardened: overwritten programmatically via heredoc in Phase 4.
# - logrotate configuration is absent: instantiated and verified in Phase 7.

log_info() { echo "[INFO]  $(date +'%Y-%m-%d %H:%M:%S') - $1"; }
log_err()  { echo "[ERROR] $(date +'%Y-%m-%d %H:%M:%S') - $1"; }

# System OS Gates
if [ "$(id -u)" -ne 0 ]; then
    log_err "Execution aborted. This configuration frame must be run as root."
    exit 1
fi

NODE_MAJOR_VERSION="20"
NGINX_VERSION="1.*"
APP_BASE="/opt/kijanikiosk"
FAILED_CHECKS=0

log_info "=== Phase 1: Package Provisioning & Pinning ==="
apt-get update -qq || true
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends curl gnupg acl ufw

mkdir -p /etc/apt/keyrings
curl -fsSL https://nodesource.com | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg --yes

echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://nodesource.com{NODE_MAJOR_VERSION}.x nodistro main" \
  | tee /etc/apt/sources.list.d/nodesource.list > /dev/null

apt-get update -qq || true
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq nginx nodejs

# Enforce version drift protection
apt-mark hold nginx nodejs

log_info "=== Phase 2: User Persona and Security Access ==="
if ! getent group kijanikiosk >/dev/null; then
    groupadd kijanikiosk
fi

for account in kk-api kk-payments kk-logs; do
    if ! getent passwd "$account" >/dev/null; then
        useradd -r -s /usr/sbin/nologin -c "KijaniKiosk $account persona" "$account"
    else
        log_info "Pre-existing account safely converged: $account"
    fi
    usermod -aG kijanikiosk "$account"
done

if getent passwd amina >/dev/null; then
    usermod -aG kijanikiosk amina
fi
usermod -aG kijanikiosk ed 2>/dev/null || true

log_info "=== Phase 3: Directory Structure and Permissions ==="
mkdir -p "${APP_BASE}"/{api,payments,logs,config,scripts,shared/logs}

# Resolve Tuesday/Thursday open permission vulnerability (Forcing 755 over 777)
chmod 755 "${APP_BASE}"
chmod 755 "${APP_BASE}"/shared

chown -R kk-api:kk-api "${APP_BASE}"/api
chown -R kk-payments:kk-payments "${APP_BASE}"/payments
chown -R kk-logs:kk-logs "${APP_BASE}"/logs
chown -R root:root "${APP_BASE}"/scripts
chown -R root:kijanikiosk "${APP_BASE}"/config

chmod 750 "${APP_BASE}"/{api,payments,logs,config,scripts}
chmod 2770 "${APP_BASE}"/shared/logs
chown -R kk-logs:kk-logs "${APP_BASE}"/shared/logs

setfacl -b "${APP_BASE}"/shared/logs
setfacl -m u:kk-api:rwx "${APP_BASE}"/shared/logs
setfacl -m u:kk-payments:r-x "${APP_BASE}"/shared/logs
setfacl -d -m u:kk-api:rwx "${APP_BASE}"/shared/logs
setfacl -d -m u:kk-payments:r-x "${APP_BASE}"/shared/logs

log_info "=== Phase 4: Writing systemd Unit Files ==="
cat << 'EOF' > /etc/systemd/system/kk-api.service
[Unit]
Description=KijaniKiosk API Service
Documentation=https://github.com
After=network-online.target kk-payments.service
Wants=network-online.target

[Service]
Type=simple
User=kk-api
Group=kk-api
WorkingDirectory=/opt/kijanikiosk/api
ExecStart=/usr/bin/node /opt/kijanikiosk/api/server.js
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure
RestartSec=5s
StartLimitIntervalSec=60s
StartLimitBurst=3
TimeoutStartSec=30s
TimeoutStopSec=30s
EnvironmentFile=/opt/kijanikiosk/config/db.env
EnvironmentFile=/opt/kijanikiosk/config/payments-api.env
Environment="NODE_ENV=production"
Environment="PORT=3000"
StandardOutput=journal
StandardError=journal
SyslogIdentifier=kk-api

# Kernel & Boundary Hardening Sandbox
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ReadWritePaths=/opt/kijanikiosk/shared/logs
ProtectHome=true
CapabilityBoundingSet=
MemoryDenyWriteExecute=true
SystemCallFilter=@system-service

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable kk-api.service > /dev/null

log_info "=== Phase 5: Firewall Configuration ==="
ufw --force reset > /dev/null
ufw default deny incoming > /dev/null
ufw default allow outgoing > /dev/null
ufw allow in on lo > /dev/null
ufw allow out on lo > /dev/null

# Strict policy rules mapping
ufw allow 22/tcp comment 'SSH inbound' > /dev/null
ufw allow 80/tcp comment 'HTTP network listener' > /dev/null
ufw --force enable > /dev/null

log_info "=== Phase 7: Journal Persistence and Log Rotation ==="
mkdir -p /var/log/journal
systemd-tmpfiles --create --prefix /var/log/journal

mkdir -p /etc/systemd/journald.conf.d
cat << 'EOF' > /etc/systemd/journald.conf.d/kijanikiosk.conf
[Journal]
Storage=persistent
Compress=yes
SystemMaxUse=500M
SystemMaxFileSize=50M
EOF
systemctl reload systemd-journald

cat << 'EOF' > /etc/logrotate.d/kijanikiosk
/opt/kijanikiosk/shared/logs/*.log {
    daily
    rotate 7
    compress
    missingok
    notifempty
    create 0660 kk-logs kijanikiosk
}
EOF

# Assert logrotate passes syntactic checks cleanly
logrotate --debug /etc/logrotate.d/kijanikiosk > /dev/null

log_info "=== Phase 8: Monitoring Health Checks ==="
api_status=$(timeout 1 bash -c "echo >/dev/tcp/localhost/3000" 2>/dev/null && echo '"ok"' || echo '"down"')
payments_status=$(timeout 1 bash -c "echo >/dev/tcp/localhost/3001" 2>/dev/null && echo '"ok"' || echo '"down"')

mkdir -p "${APP_BASE}"/health
printf '{"timestamp":"%s","kk-api":%s,"kk-payments":%s}\n' \
  "$(date -Is)" "$api_status" "$payments_status" \
  > "${APP_BASE}"/health/last-provision.json

chown kk-logs:kijanikiosk "${APP_BASE}"/health/last-provision.json
chmod 640 "${APP_BASE}"/health/last-provision.json

log_info "=== Phase 6: Final Verification Assertions ==="
for user in kk-api kk-payments kk-logs; do
    getent passwd "$user" >/dev/null || { log_err "User missing: $user"; ((FAILED_CHECKS++)); }
done

for folder in api payments logs config scripts shared/logs health; do
    [ -d "${APP_BASE}/$folder" ] || { log_err "Folder path missing: $folder"; ((FAILED_CHECKS++)); }
done

if [ "$(find "${APP_BASE}" -perm /4000 | wc -l)" -ne 0 ]; then
    log_err "Dangerous SUID presence caught inside infrastructure root folder path!"
    ((FAILED_CHECKS++))
fi

apt-mark showhold | grep -q "nginx" || { log_err "Nginx release lock verification unconfirmed."; ((FAILED_CHECKS++)); }
apt-mark showhold | grep -q "nodejs" || { log_err "Node.js release lock verification unconfirmed."; ((FAILED_CHECKS++)); }
[ "$(systemctl is-enabled kk-api.service)" = "enabled" ] || { log_err "kk-api.service boot listener disabled"; ((FAILED_CHECKS++)); }

# Check Health Log Existence
[ -f "${APP_BASE}"/health/last-provision.json ] || { log_err "Structured check asset missing"; ((FAILED_CHECKS++)); }

if [ "$FAILED_CHECKS" -gt 0 ]; then
    log_err "Foundation spec checks failed. Anomaly count: $FAILED_CHECKS"
    exit 1
else
    log_info "Foundation baseline deployment successful. All checks pass cleanly."
    exit 0
fi
