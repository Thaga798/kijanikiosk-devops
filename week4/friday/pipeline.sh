#!/bin/bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$ROOT_DIR/terraform"
ANSIBLE_DIR="$ROOT_DIR/ansible"

echo "========================================"
echo " KijaniKiosk Full IaC Pipeline"
echo "========================================"

echo
echo "[1/3] Running Terraform apply..."
cd "$TERRAFORM_DIR"
terraform apply -auto-approve

echo
echo "[2/3] Extracting Terraform outputs..."
API_IP=$(terraform output -raw api_server_ip)
PAYMENTS_IP=$(terraform output -raw payments_server_ip)
LOGS_IP=$(terraform output -raw logs_server_ip)

if [[ -z "$API_IP" || -z "$PAYMENTS_IP" || -z "$LOGS_IP" ]]; then
    echo "ERROR: One or more Terraform IP outputs are empty."
    exit 1
fi

echo "API IP:      $API_IP"
echo "Payments IP: $PAYMENTS_IP"
echo "Logs IP:     $LOGS_IP"

cat > "$ANSIBLE_DIR/inventory.ini" <<INVENTORY
[kijanikiosk]
api-staging ansible_host=$API_IP
payments-staging ansible_host=$PAYMENTS_IP
logs-staging ansible_host=$LOGS_IP
INVENTORY

echo
echo "Generated Ansible inventory:"
cat "$ANSIBLE_DIR/inventory.ini"

echo
echo "[3/3] Running Ansible..."
cd "$ANSIBLE_DIR"
ansible-playbook -i inventory.ini kijanikiosk.yml

echo
echo "========================================"
echo " Pipeline completed successfully"
echo "========================================"
