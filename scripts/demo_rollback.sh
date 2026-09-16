#!/usr/bin/env bash
set -euo pipefail

if [ ! -f .env ]; then
  cp .env.example .env
fi

mkdir -p .deploy deployment_logs

echo "=== 1. Construir y desplegar version estable 1.0 ==="
bash ./scripts/build_version.sh 1.0 false
export API_IMAGE="api:1.0"
docker compose up -d

echo "1.0" > .deploy/current_version

echo "Esperando API estable..."
for _ in $(seq 1 20); do
  STATUS="$(docker inspect     --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}'     fastapi_app 2>/dev/null || echo missing)"

  if [ "${STATUS}" = "healthy" ]; then
    break
  fi

  sleep 2
done

echo
echo "=== 2. Construir version defectuosa 2.0-broken ==="
bash ./scripts/build_version.sh 2.0-broken true

echo
echo "=== 3. Intentar desplegarla: debe activar rollback ==="
bash ./scripts/deploy.sh 2.0-broken || true

echo
echo "=== 4. Version que quedo ejecutandose ==="
docker exec fastapi_app python -c   "import urllib.request; print(urllib.request.urlopen('http://localhost:8000/version').read().decode())"

echo
echo "=== 5. Trazabilidad del despliegue ==="
tail -n 20 deployment_logs/deployment.log
