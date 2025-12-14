# Define parameters with default values
param(
    [string]$envFile = ".\env\dev.mysql.env"
)
$envVars = @{}

if (-not (Test-Path $envFile)) {
    Write-Error "Env file '$envFile' not found."
    exit 1
} 
Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*([^=]+)=(.*)$') {
        $envVars[$matches[1]] = $matches[2]
    }
}


# Configurar variables

$containerName = $envVars['DB_CONTAINER_NAME']
#$dbName = $envVars['DB_NAME']
#$dbUSer = $envVars['DB_USER']
#$dbPass = $envVars['DB_PASS']
#$dbRootPass = $envVars['DB_ROOT_PASS']
$dbDataDir = $envVars['DB_DATADIR']
$dbLogDir = $envVars['DB_LOG_DIR']
$portMapping = $envVars['DB_PORT_MAPPING'] 
$imageName = $envVars['DB_IMAGE_NAME']
$networkName = $envVars['DB_NETWORK_NAME']
$ip = $envVars["DB_IP"]



# Eliminar contenedor si existe
if (docker ps -a --filter "name=^${containerName}$" --format "{{.Names}}" | Select-Object -First 1) {
    Write-Host "Eliminando contenedor existente: $containerName"
    docker stop $containerName 2>$null
    docker rm $containerName 2>$null
}

# Construir y ejecutar comando docker
$dockerCmd = @(
    "docker run -d",
    "--name $containerName",
    "-p $portMapping",
    "-v .\mysql_data:$dbDataDir",
    "-v .\logs\mysql:$dbLogDir",
    "--env-file $envFile",
    "--hostname $containerName",
    "--network $networkName",
    "--ip $ip",
    $imageName
) -join ' '

Write-Host "Ejecutando: $dockerCmd"
Invoke-Expression $dockerCmd