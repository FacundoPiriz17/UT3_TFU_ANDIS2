param(
    [string]$Version = "1.0",
    [string]$ForceUnhealthy = "false"
)

$ErrorActionPreference = "Stop"

Write-Host "Construyendo api:$Version (FORCE_UNHEALTHY=$ForceUnhealthy)"

docker build `
    -f "dockerfile" `
    --build-arg "API_VERSION=$Version" `
    --build-arg "FORCE_UNHEALTHY=$ForceUnhealthy" `
    -t "api:$Version" `
    .

if ($LASTEXITCODE -ne 0) {
    throw "No se pudo construir la imagen api:$Version."
}
