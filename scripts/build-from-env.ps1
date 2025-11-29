Param(
    [string]$EnvFile = ".\env\dev.env",
    [string]$Dockerfile = "docker/http/apache+php/apache-php.dev.dockerfile",
    [string]$Tag = "apachephp:dev"
)

if (-not (Test-Path $EnvFile)) {
    Write-Error "Env file '$EnvFile' not found."
    exit 1
}

$lines = Get-Content $EnvFile -ErrorAction Stop
$buildArgs = @()

foreach ($line in $lines) {
    $line = $line.Trim()
    if (-not $line -or $line.StartsWith('#')) { continue }
    if ($line -notmatch '=') { continue }
    $parts = $line -split '=', 2
    $k = $parts[0].Trim()
    $v = $parts[1].Trim()
    if ($v.StartsWith('"') -and $v.EndsWith('"')) { $v = $v.Substring(1, $v.Length - 2) }
    if ($v.StartsWith("'") -and $v.EndsWith("'")) { $v = $v.Substring(1, $v.Length - 2) }
    $buildArgs += '--build-arg'
    $buildArgs += "$k=$v"
}

$argsSTR = @('build', '-f', $Dockerfile, '-t', $Tag) + $buildArgs + '.'

Write-Host "Ejecutando: docker $($argsSTR -join ' ')" & docker @argsSTR
$code = $LASTEXITCODE
if ($code -ne 0) {
    Write-Error "docker build falló con código $code"
    exit $code
}

# Ejemplos:
# .\scripts\build-from-env.ps1                          # usa valores por defecto
# .\scripts\build-from-env.ps1 -EnvFile .\env\dev.env -Dockerfile docker/http/apache+php/apache-php.dev.dockerfile -Tag myimage:dev