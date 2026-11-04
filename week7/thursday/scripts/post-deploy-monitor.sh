#!/usr/bin/env bash
# Monitors the active KijaniKiosk environment after a traffic switch.
# Automatically invokes rollback.sh when health thresholds are breached.

set -euo pipefail

CONFIDENCE_WINDOW="${1:-120}"
POLL_INTERVAL=5
MAX_CONSECUTIVE_FAILURES=3
MAX_ERRORS_PER_WINDOW=2
LATENCY_THRESHOLD=2.0
SLOW_THRESHOLD_COUNT=3

ACTIVE_ENV_STATE="/opt/kijanikiosk/.active-env"
PROXY_HEALTH_URL="http://127.0.0.1:80/health"
SCRIPTS_DIR="$(dirname "$(readlink -f "$0")")"

log()      { echo "[$(date -u +%H:%M:%S)] [MONITOR] $*"; }
log_warn() { echo "[$(date -u +%H:%M:%S)] [MONITOR WARN] $*"; }
log_fail() { echo "[$(date -u +%H:%M:%S)] [MONITOR FAIL] $*" >&2; }

trigger_rollback() {
    local reason="$1"
    local rb_exit=0

    log_fail "ROLLBACK TRIGGERED: ${reason}"
    log_fail "Calling rollback.sh..."

    if bash "${SCRIPTS_DIR}/rollback.sh"; then
        log "Rollback completed successfully."
    else
        rb_exit=$?
        log_fail "Rollback script exited with code ${rb_exit}."
        log_fail "Manual intervention required."
    fi

    exit 1
}

main() {
    local active_env
    active_env=$(cat "${ACTIVE_ENV_STATE}" 2>/dev/null || echo "unknown")

    log "=== Post-deployment monitoring: ${active_env} environment ==="
    log "Confidence window: ${CONFIDENCE_WINDOW}s | Poll interval: ${POLL_INTERVAL}s"

    local elapsed=0
    local consecutive_failures=0
    local errors_in_window=0
    local poll_count=0
    local slow_count=0
    local response_time
    local http_code
    local result

    local -a recent_slow=()

    while [ "${elapsed}" -lt "${CONFIDENCE_WINDOW}" ]; do
        poll_count=$((poll_count + 1))

        if result=$(curl -sS --max-time 5 \
            --write-out "%{http_code} %{time_total}" \
            --output /dev/null "${PROXY_HEALTH_URL}" 2>/dev/null); then
            read -r http_code response_time <<< "${result}"
        else
            http_code="000"
            response_time="0"
        fi

        http_code="${http_code:-000}"
        response_time="${response_time:-0}"

        log "Poll ${poll_count}: HTTP ${http_code} | ${response_time}s | elapsed: ${elapsed}s"

        # Availability and HTTP error tracking.
        if [[ "${http_code}" != 2* ]]; then
            consecutive_failures=$((consecutive_failures + 1))
            errors_in_window=$((errors_in_window + 1))
            log_warn "Health check failed (consecutive: ${consecutive_failures}, window errors: ${errors_in_window})"
        else
            consecutive_failures=0
        fi

        # Track slow responses over the latest five polls.
        if awk -v value="${response_time}" -v threshold="${LATENCY_THRESHOLD}" \
            'BEGIN { exit !(value > threshold) }'; then
            recent_slow+=(1)
            log_warn "Slow response: ${response_time}s"
        else
            recent_slow+=(0)
        fi

        if [ "${#recent_slow[@]}" -gt 5 ]; then
            recent_slow=("${recent_slow[@]:1}")
        fi

        slow_count=0
        for value in "${recent_slow[@]}"; do
            slow_count=$((slow_count + value))
        done

        # Evaluate rollback thresholds before resetting the 10-poll window.
        if [ "${consecutive_failures}" -ge "${MAX_CONSECUTIVE_FAILURES}" ]; then
            trigger_rollback "${consecutive_failures} consecutive health check failures"
        fi

        if [ "${errors_in_window}" -gt "${MAX_ERRORS_PER_WINDOW}" ]; then
            trigger_rollback "error threshold exceeded: ${errors_in_window} errors in 10-poll window"
        fi

        if [ "${slow_count}" -ge "${SLOW_THRESHOLD_COUNT}" ]; then
            trigger_rollback "latency threshold exceeded: ${slow_count} slow responses in last 5 polls"
        fi

        # Start a fresh error window after every 10 polls.
        if [ $((poll_count % 10)) -eq 0 ]; then
            errors_in_window=0
        fi

        sleep "${POLL_INTERVAL}"
        elapsed=$((elapsed + POLL_INTERVAL))
    done

    log "=== Confidence window passed: ${active_env} deployment declared healthy ==="
    exit 0
}

main "$@"
