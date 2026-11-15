#!/usr/bin/env bash
set -euo pipefail

WINDOW="${WINDOW:-2m}"
THRESHOLD="${THRESHOLD:-5}"

if [[ -n "${LOG_FILE:-}" ]]; then
    if [[ ! -r "$LOG_FILE" ]]; then
        echo "ERROR: Cannot read log file: $LOG_FILE"
        exit 2
    fi
    LOGS=$(cat "$LOG_FILE")
else
    LOGS=$(kubectl logs -n ingress-nginx \
        deployment/ingress-nginx-controller \
        --since="$WINDOW")
fi

printf '%s\n' "$LOGS" | awk -v threshold="$THRESHOLD" '
{
    status = $9

    if (status ~ /^[0-9][0-9][0-9]$/) {
        total++
        if (status >= 500 && status < 600) {
            errors++
        }
    }
}
END {
    if (total == 0) {
        print "NO DATA: No HTTP requests found in the selected window."
        exit 0
    }

    rate = (errors / total) * 100

    printf "Requests analysed: %d\n", total
    printf "HTTP 5xx errors: %d\n", errors
    printf "5xx error rate: %.2f%%\n", rate
    printf "Alert threshold: %s%%\n", threshold

    if (rate > threshold) {
        print "ALERT: 5xx error rate is above threshold."
        exit 1
    }

    print "OK: 5xx error rate is within threshold."
}'
