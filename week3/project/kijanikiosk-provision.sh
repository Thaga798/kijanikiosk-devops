#!/bin/bash
# KijaniKiosk Production Server Foundation Spec (Version 3.0)
# Author: Edwin Mathaga (DevOps Engineer)

set -euo pipefail

# Expected dirty conditions found in pre-provisioning audit:
# - kk-api already exists (UID 997): converged in Phase 2 via useradd check.
# - /opt/kijanikiosk/ and /shared directories are set to 777: forced to safe mode 755 in Phase 3.
# - kk-payments and kk-logs service home directories exist: isolated cleanly via systemd sandbox directives.
# - systemd unit files are unhardened: overwritten programmatically via heredoc in Phase 4.
# - logrotate configuration is absent: instantiated and verified in Phase 7.
# - ufw has dirty rulesets: completely flushed and reset in Phase 5.

log_info() { echo "[INFO]  $(date +'%Y-%m-%d %H:%M:%S') - $1"; }
log_err()  { echo "[ERROR] $(date +'%Y-%m-%d %H:%M:%S') - $1"; }
success()  { echo "[PASS]  $(date +'%Y-%m-%d %H:%M:%S') - $1"; }

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
apt-mark hold nginx nodejs

log_info "=== Phase 2: User Persona and Security Access ==="
if ! getent group kijanikiosk >/dev/null; then
    groupadd kijanikiosk
fi

for account in kk-api kk-payments kk-logs; do
    if ! getent passwd "$account" >/dev/null; then
        useradd -r -s /usr/sbin/nologin -c "KijaniKiosk $account service" "$account"
    fi
    usermod -aG kijanikiosk "$account"
done

if getent passwd amina >/dev/null; then
    usermod -aG kijanikiosk amina
fi
usermod -aG kijanikiosk ed 2>/dev/null || true

log_info "=== Phase 3: Directory Structure and Permissions ==="
mkdir -p "${APP_BASE}"/{api,payments,logs,config,scripts,shared/logs}
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

log_info "=== Phase 4: Programmatic Systemd Configuration Deployment ==="

# 1. Core API Service
cat << 'EOF' > /etc/systemd/system/kk-api.service
[Unit]
Description=KijaniKiosk API Service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=kk-api
Group=kk-api
WorkingDirectory=/opt/kijanikiosk/api
ExecStart=/usr/bin/node /opt/kijanikiosk/api/server.js
Restart=on-failure
RestartSec=5s
StartLimitIntervalSec=60s
StartLimitBurst=3
EnvironmentFile=/opt/kijanikiosk/config/db.env
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

# 2. Hardened Financial Payments Service (Exposure Score Target < 2.5)
cat << 'EOF' > /etc/systemd/system/kk-payments.service
[Unit]
Description=KijaniKiosk Financial Payments Service
After=network-online.target kk-api.service
Wants=network-online.target kk-api.service

[Service]
Type=simple
User=kk-payments
Group=kk-payments
WorkingDirectory=/opt/kijanikiosk/payments
ExecStart=/usr/bin/python3 /opt/kijanikiosk/payments/processor.py
Restart=on-failure
RestartSec=5s
StartLimitIntervalSec=60s
StartLimitBurst=3
EnvironmentFile=/opt/kijanikiosk/config/payments-api.env
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ReadWritePaths=/opt/kijanikiosk/shared/logs
ProtectHome=true
CapabilityBoundingSet=
MemoryDenyWriteExecute=true
SystemCallFilter=@system-service
PrivateDevices=true
RestrictRealtime=true

[Install]
WantedBy=multi-user.target
EOF

# 3. Log Aggregator Service
cat << 'EOF' > /etc/systemd/system/kk-logs.service
[Unit]
Description=KijaniKiosk Log Aggregator Service
After=network-online.target

[Service]
Type=simple
User=kk-logs
Group=kk-logs
WorkingDirectory=/opt/kijanikiosk/logs
ExecStart=/usr/bin/python3 /opt/kijanikiosk/logs/aggregator.py
Restart=on-failure
RestartSec=5s
EnvironmentFile=/opt/kijanikiosk/config/db.env
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
systemctl enable kk-api.service kk-payments.service kk-logs.service > /dev/null

log_info "=== Phase 5: Firewall Intent Re-Configuration ==="
ufw --force reset > /dev/null
ufw default deny incoming > /dev/null
ufw default allow outgoing > /dev/null

# CRITICAL SECURITY COMPLIANCE ORDERING: Allow loopback channels FIRST before appending deny targets
ufw allow in on lo comment 'ALLOW: loopback traffic proxy channel' > /dev/null
ufw allow out on lo comment 'ALLOW: loopback outbound verification' > /dev/null

# Restrict critical endpoints to specific monitoring subnet
ufw allow from 10.0.1.0/24 to any port 22 proto tcp comment 'ALLOW: SSH inbound from monitoring subnet' > /dev/null
ufw allow from 10.0.1.0/24 to any port 80 proto tcp comment 'ALLOW: HTTP traffic from monitoring subnet' > /dev/null

# Explicitly block external probes on the internal service port
ufw deny 3001/tcp comment 'DENY: block external direct vectors to payments engine' > /dev/null
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

# Hardened logrotate create directive matching corporate ACL baseline requirements
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
logrotate --debug /etc/logrotate.d/kijanikiosk > /dev/null

log_info "=== Phase 8: Monitoring Health Checks ==="
mkdir -p "${APP_BASE}"/health
api_status=$(timeout 1 bash -c "echo >/dev/tcp/localhost/3000" 2>/dev/null && echo '"ok"' || echo '"down"')
payments_status=$(timeout 1 bash -c "echo >/dev/tcp/localhost/3001" 2>/dev/null && echo '"ok"' || echo '"down"')

printf '{"timestamp":"%s","kk-api":%s,"kk-payments":%s}\n' \
  "$(date -Is)" "$api_status" "$payments_status" \
  > "${APP_BASE}"/health/last-provision.json
chown kk-logs:kijanikiosk "${APP_BASE}"/health/last-provision.json
chmod 640 "${APP_BASE}"/health/last-provision.json

log_info "=== Phase 6: Programmatic Verification ==="
local_status=$(sudo ufw status)
echo "$local_status" | grep -q "22/tcp.*ALLOW.*10.0.1.0/24" && success "SSH allowed from monitoring subnet" || { log_err "SSH subnet restriction rule missing"; ((FAILED_CHECKS++)); }
echo "$local_status" | grep -q "80/tcp.*ALLOW.*10.0.1.0/24" && success "HTTP allowed from monitoring subnet" || { log_err "HTTP subnet restriction rule missing"; ((FAILED_CHECKS++)); }
echo "$local_status" | grep -q "3001/tcp.*DENY" && success "Port 3001 external deny rule present" || { log_err "Port 3001 external shield missing"; ((FAILED_CHECKS++)); }

# Verify service file exposures metrics levels
score_api=$(sudo systemd-analyze security kk-api.service | grep "Overall exposure level" | awk '{print $4}')
score_pay=$(sudo systemd-analyze security kk-payments.service | grep "Overall exposure level" | awk '{print $4}')

if (( $(echo "$score_api > 3.5" | bc -l) )); then log_err "kk-api security score too high ($score_api)"; ((FAILED_CHECKS++)); fi
if (( $(echo "$score_pay > 2.5" | bc -l) )); then log_err "kk-payments security score too high ($score_pay)"; ((FAILED_CHECKS++)); fi

if [ "$FAILED_CHECKS" -gt 0 ]; then
    log_err "Final verification checks caught $FAILED_CHECKS system configuration errors."
    exit 1
else
    log_info "Foundation baseline deployment completely successful. All criteria passed."
    exit 0
fi
