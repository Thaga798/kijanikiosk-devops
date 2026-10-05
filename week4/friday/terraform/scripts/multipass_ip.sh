#!/bin/bash
set -euo pipefail

VM_NAME="$1"

IP=$(multipass info "$VM_NAME" | awk '/IPv4/ {print $2; exit}')

if [ -z "$IP" ]; then
  echo "No IPv4 address found for $VM_NAME" >&2
  exit 1
fi

printf '{"ip":"%s"}\n' "$IP"
