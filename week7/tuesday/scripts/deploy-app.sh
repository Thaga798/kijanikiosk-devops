#!/usr/bin/env bash
set -Eeuo pipefail

BASE_DIR="/opt/kijanikiosk"
RELEASE_DIR="${BASE_DIR}/releases"

: "${APP_VERSION:?APP_VERSION is required}"
: "${DEPLOY_ENV:?DEPLOY_ENV must be blue or green}"
: "${ARTIFACT_BASE_URL:?ARTIFACT_BASE_URL is required}"

BLUE_PORT="${BLUE_PORT:-3000}"
GREEN_PORT="${GREEN_PORT:-3001}"

case "$DEPLOY_ENV" in
    blue)
        PORT="$BLUE_PORT"
        SERVICE="kk-api-blue.service"
        ;;
    green)
        PORT="$GREEN_PORT"
        SERVICE="kk-api-green.service"
        ;;
    *)
        echo "ERROR: DEPLOY_ENV must be blue or green"
        exit 2
        ;;
esac

if [[ ! "$APP_VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "ERROR: Invalid APP_VERSION: $APP_VERSION"
    exit 2
fi

TARGET="${BASE_DIR}/${DEPLOY_ENV}"
APP_DIR="${TARGET}/app"
ARTIFACT="kk-api-${APP_VERSION}.tar.gz"
ARTIFACT_PATH="${RELEASE_DIR}/${ARTIFACT}"

log() {
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

fail() {
    log "Phase $1 FAILED: $2"
    exit 1
}

# Phase 1: Fetch artifact
log "Phase 1: Fetch artifact ${ARTIFACT}"
mkdir -p "$RELEASE_DIR"

if [[ -s "$ARTIFACT_PATH" ]]; then
    log "Phase 1: Artifact already downloaded; skipping fetch"
else
    if ! curl --fail --silent --show-error --location \
        --connect-timeout 5 --max-time 60 \
        "${ARTIFACT_BASE_URL%/}/${ARTIFACT}" \
        --output "${ARTIFACT_PATH}.part"; then
        rm -f "${ARTIFACT_PATH}.part"
        fail 1 "Could not download ${ARTIFACT}"
    fi

    mv "${ARTIFACT_PATH}.part" "$ARTIFACT_PATH"
    log "Phase 1: Artifact downloaded"
fi

# Phase 2: Validate artifact
log "Phase 2: Validate artifact"

if ! tar -tzf "$ARTIFACT_PATH" > /dev/null; then
    fail 2 "Invalid gzip tar archive"
fi

if ! tar -tzf "$ARTIFACT_PATH" | grep -Fxq 'server.js'; then
    fail 2 "Archive does not contain server.js at its root"
fi

CHECK_DIR="$(mktemp -d "${BASE_DIR}/.validate.XXXXXX")"
trap 'rm -rf "$CHECK_DIR"' EXIT

if ! tar -xzf "$ARTIFACT_PATH" -C "$CHECK_DIR" --no-same-owner; then
    fail 2 "Artifact extraction failed"
fi

if [[ ! -f "$CHECK_DIR/server.js" ]] ||
   ! node --check "$CHECK_DIR/server.js"; then
    fail 2 "server.js is missing or invalid"
fi

rm -rf "$CHECK_DIR"
trap - EXIT

log "Phase 2: Artifact validation passed"

# Phase 3: Deploy artifact
log "Phase 3: Deploy to ${DEPLOY_ENV}"
mkdir -p "$TARGET"

if [[ -f "$TARGET/.version" ]] &&
   [[ "$(cat "$TARGET/.version")" == "$APP_VERSION" ]] &&
   [[ -f "$APP_DIR/server.js" ]]; then
    log "Phase 3: Version already deployed; skipping extraction"
else
    STAGED_APP="${TARGET}/.app-new"
    rm -rf "$STAGED_APP"
    mkdir -p "$STAGED_APP"

    tar -xzf "$ARTIFACT_PATH" -C "$STAGED_APP" --no-same-owner

    if [[ ! -f "$STAGED_APP/server.js" ]]; then
        fail 3 "Extracted application is missing server.js"
    fi

    chown -R kk-api:kk-api "$STAGED_APP"

    rm -rf "${APP_DIR}.previous"

    if [[ -d "$APP_DIR" ]]; then
        mv "$APP_DIR" "${APP_DIR}.previous"
    fi

    if ! mv "$STAGED_APP" "$APP_DIR"; then
        if [[ -d "${APP_DIR}.previous" ]]; then
            mv "${APP_DIR}.previous" "$APP_DIR"
        fi
        fail 3 "Could not install application"
    fi

    printf '%s\n' "$APP_VERSION" > "$TARGET/.version"
    chown kk-api:kk-api "$TARGET/.version"
    log "Phase 3: Application deployed"
fi

# Phase 4: Restart service
log "Phase 4: Restart ${SERVICE}"

if ! systemctl restart "$SERVICE"; then
    fail 4 "Could not restart ${SERVICE}"
fi

log "Phase 4: Service restart succeeded"

# Phase 5: Verify service
log "Phase 5: Verify service on port ${PORT}"

HEALTH_URL="http://127.0.0.1:${PORT}/health"

for attempt in $(seq 1 10); do
    HEALTH="$(curl --fail --silent "$HEALTH_URL" 2>/dev/null || true)"

    if grep -Fq "\"version\":\"${APP_VERSION}\"" <<< "$HEALTH" &&
       grep -Fq "\"port\":${PORT}" <<< "$HEALTH"; then
        log "Phase 5: Verification passed: ${HEALTH}"
        log "Deployment successful: ${APP_VERSION} on ${DEPLOY_ENV}"
        exit 0
    fi

    sleep 2
done

journalctl -u "$SERVICE" -n 30 --no-pager || true
fail 5 "Health check failed for ${APP_VERSION} on port ${PORT}"
