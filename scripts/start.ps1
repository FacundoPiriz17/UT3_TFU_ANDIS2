$ErrorActionPreference = "Stop"

if (-not (Test-Path ".env")) {
    Copy-Item ".env.example" ".env"
    Write-Host "Se creo .env a partir de .env.example"
}

New-Item -ItemType Directory -Force ".deploy" | Out-Null
New-Item -ItemType Directory -Force "deployment_logs" | Out-Null

& "$PSScriptRoot/build_version.ps1" -Version "1.0" -ForceUnhealthy "false"

if ($LASTEXITCODE -ne 0) {
    throw "No se pudo construir la imagen api:1.0."
}

$env:API_IMAGE = "api:1.0"
docker compose up -d

if ($LASTEXITCODE -ne 0) {
    throw "No se pudieron iniciar los servicios."
}

$Status = "starting"

for ($i = 0; $i -lt 30; $i++) {
    $Status = (docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' fastapi_app 2>$null).Trim()

    if ($Status -eq "healthy") {
        break
    }

    if ($Status -eq "unhealthy") {
        docker compose logs web
        throw "La API no supero la comprobacion de salud."
    }

    Start-Sleep -Seconds 2
}

if ($Status -ne "healthy") {
    docker compose logs web
    throw "La API no alcanzo el estado saludable (estado final: $Status)."
}

Set-Content ".deploy/current_version" "1.0"

Write-Host ""
Write-Host "API iniciada en http://localhost:8000"
Write-Host "Swagger: http://localhost:8000/docs"
Write-Host "Usuario demo: demo@adaii.local / Demo123!"
