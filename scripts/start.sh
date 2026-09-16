#!/usr/bin/env bash
set -euo pipefail

if [ ! -f .env ]; then
  cp .env.example .env
  echo "Se creo .env a partir de .env.example"
fi

mkdir -p .deploy deployment_logs

bash ./scripts/build_version.sh 1.0 false

export API_IMAGE="api:1.0"
docker compose up -d

echo "1.0" > .deploy/current_version

echo
echo "API iniciada en http://localhost:8000"
echo "Swagger: http://localhost:8000/docs"
echo "Usuario demo: demo@adaii.local / Demo123!"
