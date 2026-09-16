param(
    [string]$BaseUrl = "http://localhost:8000"
)

$ErrorActionPreference = "Stop"

Write-Host "=== Login ==="

$loginBody = @{
    email = "demo@adaii.local"
    contrasena = "Demo123!"
} | ConvertTo-Json

$login = Invoke-RestMethod `
    -Method Post `
    -Uri "$BaseUrl/auth/login" `
    -ContentType "application/json" `
    -Body $loginBody

$headers = @{
    Authorization = "Bearer $($login.access_token)"
}

Write-Host "JWT obtenido."

try {
    Invoke-RestMethod -Method Delete -Uri "$BaseUrl/compras/demo@adaii.local/1" -Headers $headers | Out-Null
} catch {}

try {
    Invoke-RestMethod -Method Delete -Uri "$BaseUrl/compras/demo@adaii.local/2" -Headers $headers | Out-Null
} catch {}

Write-Host ""
Write-Host "=== Polimorfismo: costo normal sobre base 100 ==="

$normalBody = @{
    email_persona = "demo@adaii.local"
    id_juego = 1
    costo_base = 100
    politica = "normal"
} | ConvertTo-Json

Invoke-RestMethod `
    -Method Post `
    -Uri "$BaseUrl/compras" `
    -Headers $headers `
    -ContentType "application/json" `
    -Body $normalBody | ConvertTo-Json

Write-Host ""
Write-Host "=== Polimorfismo: descuento de invierno sobre base 100 ==="

$inviernoBody = @{
    email_persona = "demo@adaii.local"
    id_juego = 2
    costo_base = 100
    politica = "invierno"
} | ConvertTo-Json

Invoke-RestMethod `
    -Method Post `
    -Uri "$BaseUrl/compras" `
    -Headers $headers `
    -ContentType "application/json" `
    -Body $inviernoBody | ConvertTo-Json

Write-Host ""
Write-Host "=== Aspecto: ultimas lineas de auditoria ==="

Invoke-RestMethod `
    -Method Get `
    -Uri "$BaseUrl/auditoria" `
    -Headers $headers | ConvertTo-Json -Depth 5

Write-Host ""
Write-Host "Archivo persistente dentro del volumen:"
docker exec fastapi_app tail -n 20 /app/logs/operaciones.txt
