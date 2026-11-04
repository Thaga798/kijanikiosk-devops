#!/usr/bin/env bash
set -Eeuo pipefail

BASE_DIR="/opt/kijanikiosk"
ACTIVE_ENV_STATE="${BASE_DIR}/.active-env"
PREVIOUS_ENV_STATE="${BASE_DIR}/.previous-env"
NGINX_CONFIG="/etc/nginx/kijanikiosk-active-env.conf"
PROXY_URL="http://127.0.0.1/health"

log() {
    printf '[%s] %s\n' "$(date -u +%H:%M:%S)" "$*"
}

fail() {
    local code="$1"
    shift
    printf '[FAIL] %s\n' "$*" >&2
    exit "$code"
}

[[ "$EUID" -eq 0 ]] || fail 1 "Run this script with sudo."
[[ $# -eq 1 ]] || fail 1 "Usage: $0 blue|green"
[[ -f "$ACTIVE_ENV_STATE" ]] || fail 1 "Active environment state file is missing."

TARGET="$1"
case "$TARGET" in
    blue)  PORT=3000; SERVICE="kk-api-blue" ;;
    green) PORT=3001; SERVICE="kk-api-green" ;;
    *) fail 1 "Invalid environment. Use blue or green." ;;
esac

CURRENT="$(cat "$ACTIVE_ENV_STATE")"
case "$CURRENT" in
    blue|green) ;;
    *) fail 1 "Invalid current environment state: $CURRENT" ;;
esac

log "Current environment: $CURRENT"
log "Target environment:  $TARGET"

if [[ "$CURRENT" == "$TARGET" ]]; then
    log "Traffic is already on $TARGET."
    exit 0
fi

log "Step 1: Verifying $TARGET is healthy on port $PORT..."

HEALTH="$(curl --fail --silent --show-error --max-time 5 \
    "http://127.0.0.1:${PORT}/health" 2>/dev/null)" ||
    fail 1 "Pre-switch health check FAILED: $TARGET (port $PORT) is not responding"

grep -Fq "\"port\":${PORT}" <<< "$HEALTH" ||
    fail 1 "Pre-switch health check FAILED: incorrect health response from $TARGET"

log "Pre-switch health check passed: $TARGET is healthy"

log "Step 2: Writing new nginx active-env configuration..."

TEMP_CONFIG="$(mktemp /etc/nginx/kijanikiosk-active-env.XXXXXX)" ||
    fail 2 "Could not create temporary Nginx configuration."

cat > "$TEMP_CONFIG" <<CONFIG
# Active environment: ${SERVICE}.service
upstream kijanikiosk_backend {
    server 127.0.0.1:${PORT};
}
CONFIG

chmod 0644 "$TEMP_CONFIG" || fail 2 "Could not set Nginx configuration permissions."
mv "$TEMP_CONFIG" "$NGINX_CONFIG" || fail 2 "Could not install Nginx configuration."

log "Step 3: Validating nginx configuration..."

nginx -t || fail 2 "Nginx configuration validation failed."

log "Nginx configuration is valid."

# Record the previous environment BEFORE reloading Nginx.
TEMP_STATE="${PREVIOUS_ENV_STATE}.tmp"
printf '%s\n' "$CURRENT" > "$TEMP_STATE" ||
    fail 2 "Could not write previous environment state."
chown root:kijanikiosk "$TEMP_STATE" || fail 2 "Could not set previous state ownership."
chmod 0640 "$TEMP_STATE" || fail 2 "Could not set previous state permissions."
mv "$TEMP_STATE" "$PREVIOUS_ENV_STATE" ||
    fail 2 "Could not save previous environment state."

log "Recorded previous environment: $CURRENT"

log "Step 4: Reloading nginx..."

systemctl reload nginx || fail 2 "Nginx reload failed."

# Record the target as active so automatic rollback knows where to return from.
TEMP_ACTIVE="${ACTIVE_ENV_STATE}.tmp"
printf '%s\n' "$TARGET" > "$TEMP_ACTIVE" ||
    fail 2 "Could not write active environment state."
chown root:kijanikiosk "$TEMP_ACTIVE" || fail 2 "Could not set active state ownership."
chmod 0640 "$TEMP_ACTIVE" || fail 2 "Could not set active state permissions."
mv "$TEMP_ACTIVE" "$ACTIVE_ENV_STATE" ||
    fail 2 "Could not save active environment state."

log "nginx reloaded. Traffic now routing to $TARGET."

log "Step 5: Confirming switch via proxy health check..."

PROXY_HEALTH=""
for attempt in $(seq 1 5); do
    PROXY_HEALTH="$(curl --fail --silent "$PROXY_URL" 2>/dev/null || true)"
    if grep -Fq "\"port\":${PORT}" <<< "$PROXY_HEALTH"; then
        log "Post-switch confirmation passed: proxy is routing to $TARGET (port $PORT)"
        log "Proxy health: $PROXY_HEALTH"
        log "=== Switch to $TARGET complete ==="
        exit 0
    fi
    sleep 1
done

fail 3 "Post-switch proxy verification failed. Automatic rollback is required."
