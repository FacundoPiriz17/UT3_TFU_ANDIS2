#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:8000}"

echo "=== Login ==="
LOGIN_RESPONSE="$(curl -sS \
  -X POST "${BASE_URL}/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"demo@adaii.local","contrasena":"Demo123!"}')"

TOKEN="$(python -c \
  'import json,sys; print(json.loads(sys.stdin.read())["access_token"])' \
  <<< "${LOGIN_RESPONSE}")"

echo "JWT obtenido."

curl -sS -o /dev/null \
  -X DELETE "${BASE_URL}/compras/demo@adaii.local/1" \
  -H "Authorization: Bearer ${TOKEN}" || true

curl -sS -o /dev/null \
  -X DELETE "${BASE_URL}/compras/demo@adaii.local/2" \
  -H "Authorization: Bearer ${TOKEN}" || true

echo
echo "=== Polimorfismo: costo normal sobre base 100 ==="
curl -sS \
  -X POST "${BASE_URL}/compras" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "email_persona":"demo@adaii.local",
    "id_juego":1,
    "costo_base":100,
    "politica":"normal"
  }'
echo

echo
echo "=== Polimorfismo: descuento de invierno sobre base 100 ==="
curl -sS \
  -X POST "${BASE_URL}/compras" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "email_persona":"demo@adaii.local",
    "id_juego":2,
    "costo_base":100,
    "politica":"invierno"
  }'
echo

echo
echo "=== Aspecto: ultimas lineas de auditoria ==="
curl -sS \
  "${BASE_URL}/auditoria" \
  -H "Authorization: Bearer ${TOKEN}"
echo

echo
echo "Archivo persistente dentro del volumen:"
docker exec fastapi_app tail -n 20 /app/logs/operaciones.txt
