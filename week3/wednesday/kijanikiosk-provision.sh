#!/bin/bash
# KijaniKiosk Automated System Provisioning Architecture
# Author: Edwin Mathaga (DevOps Engineer)

set -euo pipefail

# Structured Logging Directives
log_info() { echo "[INFO]  $(date +'%Y-%m-%d %H:%M:%S') - $1"; }
log_warn() { echo "[WARN]  $(date +'%Y-%m-%d %H:%M:%S') - $1"; }
log_err()  { echo "[ERROR] $(date +'%Y-%m-%d %H:%M:%S') - $1"; }

# Phase 0: System OS & Validation Gates
if [ "$(id -u)" -ne 0 ]; then
    log_err "Execution aborted. This provisioning frame must be run as root."
    exit 1
fi

if [ ! -f /etc/os-release ] || ! grep -q "Ubuntu" /etc/os-release; then
    log_err "Execution aborted. This baseline targets Ubuntu Linux systems exclusively."
    exit 1
fi

NODE_MAJOR_VERSION="20"
NGINX_VERSION="1.*"
APP_BASE="/opt/kijanikiosk"
FAILED_CHECKS=0

# Phase 1: Package Provisioning & Repository Pinning
log_info "=== Phase 1: Package Provisioning ==="
apt-get update -qq || true

# Install prerequisite tools quietly without recommended packages overhead
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends curl gnupg acl ufw

# Import NodeSource signing keys idempotently
mkdir -p /etc/apt/keyrings
curl -fsSL https://nodesource.com | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg --yes

echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://nodesource.com{NODE_MAJOR_VERSION}.x nodistro main" \
  | tee /etc/apt/sources.list.d/nodesource.list > /dev/null

apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq nginx="${NGINX_VERSION}" nodejs

# Force version lock rules against package update drift
apt-mark hold nginx nodejs
log_info "Software holds successfully applied for Nginx and Node.js."

# Phase 2: Service Persona Group Hardening
log_info "=== Phase 2: User Persona and Security Access ==="
if ! getent group kijanikiosk >/dev/null; then
    groupadd kijanikiosk
    log_info "Created shared group: kijanikiosk"
else
    log_info "Group already exists: kijanikiosk"
fi

for account in kk-api kk-payments kk-logs; do
    if ! getent passwd "$account" >/dev/null; then
        useradd -r -s /usr/sbin/nologin -c "KijaniKiosk $account service persona" "$account"
        log_info "Created service account user: $account"
    else
        log_info "Already exists: $account"
    fi
    usermod -aG kijanikiosk "$account"
done

if getent passwd amina >/dev/null; then
    usermod -aG kijanikiosk amina
    log_info "Associated engineer amina with shared service access group."
fi

# Phase 3: Directory Topologies and POSIX ACLs
log_info "=== Phase 3: Directory Structure and Permissions ==="
mkdir -p "${APP_BASE}"/{api,payments,logs,config,scripts,shared/logs}

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

provision_logging() {
  log_info "=== Phase: Logging Configuration ==="

  # Enable persistent journal storage
  mkdir -p /var/log/journal
  systemd-tmpfiles --create --prefix /var/log/journal

  # Configure size caps to prevent journal from filling disk
  mkdir -p /etc/systemd/journald.conf.d
  cat > /etc/systemd/journald.conf.d/kijanikiosk.conf << 'CONF'
[Journal]
Storage=persistent
Compress=yes
SystemMaxUse=500M
SystemMaxFileSize=50M
CONF

  systemctl reload systemd-journald
  log_info "Persistent journal configured (max 500MB)"
}

provision_logging

provision_logging() {
  log_info "=== Phase: Logging Configuration ==="
  mkdir -p /var/log/journal
  systemd-tmpfiles --create --prefix /var/log/journal

  # Enforce programmatic daily log rotation profiles to avoid disk I/O saturation failures
  cat > /etc/logrotate.d/kijanikiosk << 'EOF'
/opt/kijanikiosk/shared/logs/*.log {
    daily
    rotate 7
    compress
    missingok
    notifempty
    create 0660 kk-logs kijanikiosk
}
EOF

  # Configure size caps for systemd-journald
  mkdir -p /etc/systemd/journald.conf.d
  cat > /etc/systemd/journald.conf.d/kijanikiosk.conf << 'CONF'
[Journal]
Storage=persistent
Compress=yes
SystemMaxUse=500M
SystemMaxFileSize=50M
CONF

  systemctl reload systemd-journald
  log_info "Persistent journal configured (max 500MB) with daily logrotate structures."
}


# Phase 4: Programmatic Systemd Configuration Deployment
log_info "=== Phase 4: Writing systemd Unit Files Programmatically ==="
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

# Hardening Sandboxes
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
log_info "Engine component validated and configured for system boot sequence."

# Phase 5: Firewall Custom Layer Rules
log_info "=== Phase 5: Firewall Configuration ==="
if command -v ufw >/dev/null; then
    ufw --force reset > /dev/null
    ufw default deny incoming > /dev/null
    ufw default allow outgoing > /dev/null
    
    # FIX: Explicitly allow loopback connection interfaces to prevent trigger freezes
    ufw allow in on lo > /dev/null
    ufw allow out on lo > /dev/null

    # SECURITY POLICY GUARDRAIL: Never inject a global 'deny 3001/tcp' parameter.
# Doing so breaks systemic internal system load balancer health checking loops,
# triggering false cascading 502 gateway routing timeouts.
    # CRITICAL: Structural Ordering Rule - Port 22 Allowed Prior to Activation
    ufw allow 22/tcp comment 'SSH inbound clearance' > /dev/null
    ufw allow 80/tcp comment 'HTTP network listener' > /dev/null
    ufw --force enable > /dev/null
    log_info "Firewall state active. Restricted matrix configurations successfully mounted."
else
    log_err "UFW software stack missing. Skipping network rules configuration."
    ((FAILED_CHECKS++))
fi

# Phase 6: System State Audit Check Assertions
log_info "=== Phase 6: Verification ==="
for user in kk-api kk-payments kk-logs; do
    getent passwd "$user" >/dev/null || { log_err "Assertion Failed: User profile missing - $user"; ((FAILED_CHECKS++)); }
done

for folder in api payments logs config scripts shared/logs; do
    [ -d "${APP_BASE}/$folder" ] || { log_err "Assertion Failed: Folder path missing - $folder"; ((FAILED_CHECKS++)); }
done

if [ "$(find "${APP_BASE}" -perm /4000 | wc -l)" -ne 0 ]; then
    log_err "Assertion Failed: Unauthorized structural SUID descriptor found inside base directory layout."
    ((FAILED_CHECKS++))
fi

apt-mark showhold | grep -q "nginx" || { log_err "Assertion Failed: Nginx release hold status unconfirmed."; ((FAILED_CHECKS++)); }
apt-mark showhold | grep -q "nodejs" || { log_err "Assertion Failed: Node.js release hold status unconfirmed."; ((FAILED_CHECKS++)); }

if [ "$(systemctl is-enabled kk-api.service)" != "enabled" ]; then
    log_err "Assertion Failed: Service execution configuration missing from system daemon runtime list."
    ((FAILED_CHECKS++))
fi

if [ "$FAILED_CHECKS" -gt 0 ]; then
    log_err "Triage Complete. $FAILED_CHECKS system integrity errors detected during verification analysis."
    exit 1
else
    log_info "Verification checks clear. All KijaniKiosk core provisioning guardrails pass cleanly."
    exit 0
fi
