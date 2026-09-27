#!/bin/bash
# KijaniKiosk Complete Multi-Component Access Control Hardening Script
# Author: Edwin Mathaga (DevOps Engineer)
set -e

echo "[+] Task 1: Provisioning Role Persona Environments..."
# 1. Ensure structural system accounts exist under UID 1000 with primary groups
sudo groupadd -f kk-api
sudo groupadd -f kk-payments
sudo groupadd -f kk-logs
sudo groupadd -f kijanikiosk

sudo useradd -r -s /usr/sbin/nologin -g kk-api -c "KijaniKiosk Core API Component" kk-api 2>/dev/null || echo "User kk-api ready."
sudo useradd -r -s /usr/sbin/nologin -g kk-payments -c "KijaniKiosk Payment Handler" kk-payments 2>/dev/null || echo "User kk-payments ready."
sudo useradd -r -s /usr/sbin/nologin -g kk-logs -c "KijaniKiosk Log Aggregator Engine" kk-logs 2>/dev/null || echo "User kk-logs ready."

# 2. Add service personas plus the current user to the shared workspace group
sudo usermod -aG kijanikiosk kk-api
sudo usermod -aG kijanikiosk kk-payments
sudo usermod -aG kijanikiosk kk-logs
sudo usermod -aG kijanikiosk $(whoami)

echo "[+] Task 2: Re-structuring Ownership Boundaries & POSIX ACLs..."
# 1. Enforce strict DAC ownerships and directory modes
sudo chown -R kk-api:kk-api /opt/kijanikiosk/api/
sudo chmod 750 /opt/kijanikiosk/api/

sudo chown -R kk-payments:kk-payments /opt/kijanikiosk/payments/
sudo chmod 750 /opt/kijanikiosk/payments/

sudo chown -R kk-logs:kk-logs /opt/kijanikiosk/logs/
sudo chmod 750 /opt/kijanikiosk/logs/

sudo chown -R root:kijanikiosk /opt/kijanikiosk/config/
sudo chmod 750 /opt/kijanikiosk/config/
sudo chmod 640 /opt/kijanikiosk/config/*

# 2. Configure Shared Log Vault with SGID (Mode 2770)
sudo chown -R kk-logs:kk-logs /opt/kijanikiosk/shared/logs/
sudo chmod 2770 /opt/kijanikiosk/shared/logs/

# 3. Mount Extended Access Control Lists (ACLs)
sudo setfacl -b /opt/kijanikiosk/shared/logs/
sudo setfacl -m u:kk-api:rwx /opt/kijanikiosk/shared/logs/
sudo setfacl -m u:kk-payments:r-x /opt/kijanikiosk/shared/logs/
sudo setfacl -m u:$(whoami):r-x /opt/kijanikiosk/shared/logs/

# Enforce default parameters for future generated file objects
sudo setfacl -d -m u:kk-api:rwx /opt/kijanikiosk/shared/logs/
sudo setfacl -d -m u:kk-payments:r-x /opt/kijanikiosk/shared/logs/
sudo setfacl -d -m u:$(whoami):r-x /opt/kijanikiosk/shared/logs/

# Mount User Read Access on Config
sudo setfacl -m u:$(whoami):r-- /opt/kijanikiosk/config/
sudo setfacl -m u:$(whoami):r-- /opt/kijanikiosk/config/*

echo "[+] Task 3: Mitigating SUID Risks..."
sudo chmod 750 /opt/kijanikiosk/scripts/deploy.sh
sudo chown root:root /opt/kijanikiosk/scripts/deploy.sh

echo "[+] Task 5: Running Verification Audit Assertions..."
echo "--- Service Account Assertions ---"
id kk-api
id kk-payments
getent group kijanikiosk | grep $(whoami)

echo "--- ACL Target Matrix (Shared Logs) ---"
getfacl /opt/kijanikiosk/shared/logs/

echo "--- Global SUID Tree Scan Result (Should Be Empty) ---"
find /opt/kijanikiosk/ -perm /4000

echo "=== Access Architecture Hardening Successfully Deployed ==="
