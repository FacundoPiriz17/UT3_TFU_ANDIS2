$ErrorActionPreference = "Stop"

if (-not (Test-Path ".env")) {
    Copy-Item ".env.example" ".env"
}

New-Item -ItemType Directory -Force ".deploy" | Out-Null
New-Item -ItemType Directory -Force "deployment_logs" | Out-Null

Write-Host "=== 1. Construir y desplegar version estable 1.0 ==="
& "$PSScriptRoot/build_version.ps1" -Version "1.0" -ForceUnhealthy "false"

$env:API_IMAGE = "api:1.0"
docker compose up -d
Set-Content ".deploy/current_version" "1.0"

Write-Host "Esperando API estable..."
for ($i = 0; $i -lt 20; $i++) {
    $status = (docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' fastapi_app 2>$null).Trim()
    if ($status -eq "healthy") {
        break
    }
    Start-Sleep -Seconds 2
}

Write-Host ""
Write-Host "=== 2. Construir version defectuosa 2.0-broken ==="
& "$PSScriptRoot/build_version.ps1" -Version "2.0-broken" -ForceUnhealthy "true"

Write-Host ""
Write-Host "=== 3. Intentar desplegarla: debe activar rollback ==="
& "$PSScriptRoot/deploy.ps1" -Version "2.0-broken"
# deploy.ps1 devuelve 1 cuando el nuevo deploy falla aunque el rollback sea exitoso.
$global:LASTEXITCODE = 0

Write-Host ""
Write-Host "=== 4. Version que quedo ejecutandose ==="
docker exec fastapi_app python -c "import urllib.request; print(urllib.request.urlopen('http://localhost:8000/version').read().decode())"

Write-Host ""
Write-Host "=== 5. Trazabilidad del despliegue ==="
Get-Content "deployment_logs/deployment.log" -Tail 20
