param(
    [string]$DbName = $(if ($env:DB_NAME) { $env:DB_NAME } else { 'routing' }),
    [string]$DbUser = $(if ($env:DB_USER) { $env:DB_USER } else { 'routing' }),
    [SecureString]$DbPassword = $(if ($env:DB_PASSWORD) { ConvertTo-SecureString $env:DB_PASSWORD -AsPlainText -Force } else { ConvertTo-SecureString 'routing' -AsPlainText -Force }),
    [string]$PostgresContainerName = 'rivo-postgres',
    [string]$Osm2pgsqlImage = 'rivo-osm2pgsql-local:latest',
    [string]$PbfPath,
    [int]$CacheMb = 4096,
    [int]$Processes = 4
)

$ErrorActionPreference = 'Stop'

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
if (-not $PbfPath) {
    $PbfPath = Join-Path $projectRoot 'src\main\resources\osm\south-america-latest.osm.pbf'
}
$stylePath = Join-Path $projectRoot 'infra\osm2pgsql\osm2pgsql-flex.lua'
$dockerfilePath = Join-Path $projectRoot 'infra\osm2pgsql\Dockerfile'

if (-not (Test-Path $PbfPath)) {
    throw "PBF not found: $PbfPath"
}
if (-not (Test-Path $stylePath)) {
    throw "Lua style not found: $stylePath"
}
if (-not (Test-Path $dockerfilePath)) {
    throw "Dockerfile not found: $dockerfilePath"
}
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw 'docker not found. Install Docker Desktop or add docker to PATH.'
}

$pbfFullPath = (Resolve-Path $PbfPath).Path
$styleFullPath = (Resolve-Path $stylePath).Path
$dockerfileFullPath = (Resolve-Path $dockerfilePath).Path

$containerRunning = (& docker inspect -f '{{.State.Running}}' $PostgresContainerName 2>$null).Trim()
if ($LASTEXITCODE -ne 0 -or $containerRunning -ne 'true') {
    throw "Docker container $PostgresContainerName is not running. Start it with: docker compose up -d postgres"
}

$dockerNetwork = (& docker inspect -f '{{range $k, $v := .NetworkSettings.Networks}}{{println $k}}{{end}}' $PostgresContainerName 2>$null | Select-Object -First 1).Trim()
if (-not $dockerNetwork) {
    throw "Could not resolve Docker network for container $PostgresContainerName."
}

$imageExists = (& docker image ls $Osm2pgsqlImage --format '{{.Repository}}:{{.Tag}}' | Out-String).Trim()
if (-not $imageExists) {
    Write-Host "Building local osm2pgsql image $Osm2pgsqlImage from $dockerfileFullPath..."
    & docker build -t $Osm2pgsqlImage -f $dockerfileFullPath (Split-Path $dockerfileFullPath -Parent)
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to build Docker image $Osm2pgsqlImage."
    }
}

$bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($DbPassword)
try {
    $dbPasswordPlain = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
} finally {
    [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
}

Write-Host "Ensuring required PostgreSQL extensions exist in Docker container $PostgresContainerName..."
& docker exec -e "PGPASSWORD=$dbPasswordPlain" $PostgresContainerName psql -U $DbUser -d $DbName -c "CREATE EXTENSION IF NOT EXISTS postgis; CREATE EXTENSION IF NOT EXISTS pg_trgm;"
if ($LASTEXITCODE -ne 0) {
    throw 'Failed to enable PostgreSQL extensions inside Docker PostgreSQL.'
}

Write-Host "Importing $pbfFullPath with $styleFullPath into Docker PostgreSQL ${DbName}@${PostgresContainerName}:5432 via Docker network $dockerNetwork"
& docker run --rm `
    --network $dockerNetwork `
    -e "PGPASSWORD=$dbPasswordPlain" `
    -v "${pbfFullPath}:/data/input.osm.pbf:ro" `
    -v "${styleFullPath}:/data/osm2pgsql-flex.lua:ro" `
    $Osm2pgsqlImage `
    --create `
    --output=flex `
    --style=/data/osm2pgsql-flex.lua `
    --database=$DbName `
    --host=$PostgresContainerName `
    --port=5432 `
    --user=$DbUser `
    --cache=$CacheMb `
    --number-processes=$Processes `
    --log-progress=true `
    /data/input.osm.pbf

if ($LASTEXITCODE -ne 0) {
    throw 'osm2pgsql import failed inside Docker.'
}

Write-Host 'OSM local import completed successfully with Docker-only tooling.'
