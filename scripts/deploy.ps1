param(
    [Parameter(Mandatory = $true)]
    [string]$Version
)

$ErrorActionPreference = "Stop"

$Image = "api:$Version"

New-Item -ItemType Directory -Force ".deploy" | Out-Null
New-Item -ItemType Directory -Force "deployment_logs" | Out-Null

docker image inspect $Image *> $null
if ($LASTEXITCODE -ne 0) {
    Write-Host "No existe la imagen $Image."
    Write-Host "Construyela antes con:"
    Write-Host "  .\scripts\build_version.ps1 -Version $Version"
    exit 2
}

$PreviousVersion = "1.0"

if (Test-Path ".deploy/current_version") {
    $PreviousVersion = (Get-Content ".deploy/current_version" -Raw).Trim()
}

$PreviousImage = "api:$PreviousVersion"
$LogFile = "deployment_logs/deployment.log"

function Write-DeployLog([string]$Message) {
    $line = "$(Get-Date -Format o) | $Message"
    Write-Host $line
    Add-Content -Path $LogFile -Value $line
}

Write-DeployLog "DEPLOY_START previous=$PreviousImage new=$Image"

$env:API_IMAGE = $Image
docker compose up -d --no-deps web

$Status = "starting"

for ($i = 0; $i -lt 15; $i++) {
    $Status = (docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' fastapi_app 2>$null).Trim()

    if ($Status -eq "healthy") {
        Set-Content ".deploy/current_version" $Version
        Write-DeployLog "DEPLOY_SUCCESS current=$Image"
        exit 0
    }

    if ($Status -eq "unhealthy") {
        break
    }

    Start-Sleep -Seconds 2
}

Write-DeployLog "DEPLOY_FAILED image=$Image health=$Status"
Write-DeployLog "ROLLBACK_START target=$PreviousImage"

docker image inspect $PreviousImage *> $null
if ($LASTEXITCODE -ne 0) {
    Write-DeployLog "ROLLBACK_FAILED missing_image=$PreviousImage"
    exit 1
}

$env:API_IMAGE = $PreviousImage
docker compose up -d --no-deps web

for ($i = 0; $i -lt 15; $i++) {
    $Status = (docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' fastapi_app 2>$null).Trim()

    if ($Status -eq "healthy") {
        Set-Content ".deploy/current_version" $PreviousVersion
        Write-DeployLog "ROLLBACK_SUCCESS current=$PreviousImage"
        exit 1
    }

    Start-Sleep -Seconds 2
}

Write-DeployLog "ROLLBACK_FAILED target=$PreviousImage health=$Status"
exit 1
