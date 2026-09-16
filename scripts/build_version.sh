#!/usr/bin/env bash
set -euo pipefail

VERSION="${1:-1.0}"
FORCE_UNHEALTHY="${2:-false}"

echo "Construyendo api:${VERSION} (FORCE_UNHEALTHY=${FORCE_UNHEALTHY})"

docker build \
  -f dockerfile \
  --build-arg API_VERSION="${VERSION}" \
  --build-arg FORCE_UNHEALTHY="${FORCE_UNHEALTHY}" \
  -t "api:${VERSION}" \
  .
