Param(
    [string]$EnvFile = ".\env\dev.env",
    [string]$Image = "apachephp:dev",
    [string]$HostSrc = ".\src",
    [string]$ContainerName = "ApachePHPContainer",
    [int]$ServerPort
)

if (-not (Test-Path $EnvFile)) {
    Write-Error "Env file '$EnvFile' not found."
    exit 1
}
else {
    Write-Host "Env File : $EnvFile Exists."
}

$lines = Get-Content $EnvFile -ErrorAction Stop
$envVars = @{}
foreach ($line in $lines) {
    $line = $line.Trim()
    if (-not $line -or $line.StartsWith('#')) { continue }
    if ($line -notmatch '=') { continue }
    $parts = $line -split '=', 2
    $k = $parts[0].Trim()
    $v = $parts[1].Trim()
    if ($v.StartsWith('"') -and $v.EndsWith('"')) { $v = $v.Substring(1, $v.Length - 2) }
    if ($v.StartsWith("'") -and $v.EndsWith("'")) { $v = $v.Substring(1, $v.Length - 2) }
    $envVars[$k] = $v
}

if (-not $envVars.ContainsKey('SERVER_NAME')) {
    Write-Error "SERVER_NAME no encontrado en $EnvFile"
    exit 1
}
else {
    Write-Host "SERVER_NAME found in ${EnvFile}: $($envVars['SERVER_NAME'])"
}

$serverName = $envVars['SERVER_NAME']

if ($envVars.ContainsKey('SERVER_PORT')) { 
    $serverPort = $envVars['SERVER_PORT'] 
    Write-Host "SERVER_PORT found in ${EnvFile}: $serverPort"
} 
else { 
    $serverPort = 80
    Write-Host "SERVER_PORT not found in ${EnvFile}, defaulting to: $serverPort"
}

if (-not (Test-Path $HostSrc)) {
    Write-Host "Host source '$HostSrc' no existe — creando..."
    New-Item -ItemType Directory -Path $HostSrc -Force | Out-Null
}
else {
    Write-Host "Host source '$HostSrc' existe."
}

# Resolver HostSrc: si es relativa la combinamos con la carpeta del script, luego obtenemos la ruta absoluta limpia
$hostPathInput = $HostSrc
if (-not [System.IO.Path]::IsPathRooted($hostPathInput)) {
    $hostPathInput = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath $hostPathInput
}
$hostPath = (Resolve-Path -Path $hostPathInput -ErrorAction Stop).ProviderPath.TrimEnd('\')
Write-Host "Resolved host path: $hostPath"

if (-not $ContainerName) { $ContainerName = "web-$serverName" }

# Si existe un contenedor con el mismo nombre lo detenemos y eliminamos
$existing = docker ps -a --filter "name=^/${ContainerName}$" --format "{{.ID}}" 2>$null
if ($existing) {
    Write-Host "Contenedor con nombre $ContainerName ya existe. Parando y eliminando..."
    docker rm -f $ContainerName | Out-Null
}

$argsSTR = @('run', '-d', '--name', $ContainerName, '-v', "${hostPath}:/var/www/$serverName")
$argsSTR += @('-p', $(@($serverPort, 80) -join ':'))
$argsSTR += $Image

Write-Host "Ejecutando: docker $($argsSTR -join ' ')"
& docker @argsSTR
$code = $LASTEXITCODE
if ($code -ne 0) {
    Write-Error "docker run falló con código $code"
    exit $code
}

Write-Host "Contenedor '$ContainerName' creado. Host dir: $hostPath -> /var/www/$serverName"

# Ejemplos:
# .\scripts\run-container-from-env.ps1                       # usa valores por defecto
# .\scripts\run-container-from-env.ps1 -Image myimage:dev    # especificar imagen
# .\scripts\run-container-from-env.ps1 -HostSrc .\src       # cambiar carpeta fuente en host