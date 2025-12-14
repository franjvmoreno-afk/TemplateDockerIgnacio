# CrearRedDocker.ps1
# Script para crear una red en Docker usando PowerShell

param(
    [string]$NetworkName = "mi_red_docker",   # Nombre de la red
    [string]$Driver = "bridge",               # Driver de red (bridge, overlay, host, etc.)
    [string]$Subnet = "172.25.0.0/16",        # Subred opcional
    [string]$Gateway = "172.25.0.1"           # Gateway opcional
)

Write-Host "Creando red Docker: $NetworkName con driver $Driver..." -ForegroundColor Cyan

# Construir comando dinámico
$command = "docker network create --driver $Driver"

if ($Subnet -and $Gateway) {
    $command += " --subnet=$Subnet --gateway=$Gateway"
}

$command += " $NetworkName"

# Ejecutar comando
Invoke-Expression $command

# Verificar creación
Write-Host "Redes disponibles:" -ForegroundColor Green
docker network ls
