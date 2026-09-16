#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Uso: bash ./scripts/deploy.sh <version>"
  exit 2
fi

VERSION="$1"
IMAGE="api:${VERSION}"

mkdir -p .deploy deployment_logs

if ! docker image inspect "${IMAGE}" >/dev/null 2>&1; then
  echo "No existe la imagen ${IMAGE}."
  echo "Construyela antes con:"
  echo "  bash ./scripts/build_version.sh ${VERSION} false"
  exit 2
fi

PREVIOUS_VERSION="1.0"

if [ -f .deploy/current_version ]; then
  PREVIOUS_VERSION="$(cat .deploy/current_version)"
fi

PREVIOUS_IMAGE="api:${PREVIOUS_VERSION}"
LOG_FILE="deployment_logs/deployment.log"

log() {
  printf '%s | %s\n' "$(date -Iseconds)" "$1" | tee -a "${LOG_FILE}"
}

log "DEPLOY_START previous=${PREVIOUS_IMAGE} new=${IMAGE}"

API_IMAGE="${IMAGE}" docker compose up -d --no-deps web

STATUS="starting"

for _ in $(seq 1 15); do
  STATUS="$(docker inspect     --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}'     fastapi_app 2>/dev/null || echo missing)"

  if [ "${STATUS}" = "healthy" ]; then
    echo "${VERSION}" > .deploy/current_version
    log "DEPLOY_SUCCESS current=${IMAGE}"
    exit 0
  fi

  if [ "${STATUS}" = "unhealthy" ]; then
    break
  fi

  sleep 2
done

log "DEPLOY_FAILED image=${IMAGE} health=${STATUS}"
log "ROLLBACK_START target=${PREVIOUS_IMAGE}"

if ! docker image inspect "${PREVIOUS_IMAGE}" >/dev/null 2>&1; then
  log "ROLLBACK_FAILED missing_image=${PREVIOUS_IMAGE}"
  exit 1
fi

API_IMAGE="${PREVIOUS_IMAGE}" docker compose up -d --no-deps web

for _ in $(seq 1 15); do
  STATUS="$(docker inspect     --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}'     fastapi_app 2>/dev/null || echo missing)"

  if [ "${STATUS}" = "healthy" ]; then
    echo "${PREVIOUS_VERSION}" > .deploy/current_version
    log "ROLLBACK_SUCCESS current=${PREVIOUS_IMAGE}"
    exit 1
  fi

  sleep 2
done

log "ROLLBACK_FAILED target=${PREVIOUS_IMAGE} health=${STATUS}"
exit 1
