// Parámetro inicial para cargar los ajustes específicos de MySQL
param(
    [string]$envFile = ".\env\dev.mysql.env"
)
$envVars = @{}

// Validamos que el archivo de configuración existe para no lanzar errores vacíos {check}
if (-not (Test-Path $envFile)) {
    Write-Error "Env file '$envFile' not found."
    exit 1
} 

// Extraemos las variables del archivo .env y las metemos en memoria para usarlas después
Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*([^=]+)=(.*)$') {
        $envVars[$matches[1]] = $matches[2]
    }
}

# Pasamos los valores del diccionario a variables locales para que el comando sea legible
$containerName = $envVars['DB_CONTAINER_NAME']
$dbDataDir = $envVars['DB_DATADIR']
$dbLogDir = $envVars['DB_LOG_DIR']
$port = $envVars['DB_PORT'] 
$imageName = $envVars['DB_IMAGE_NAME']
$networkName = $envVars['DB_NETWORK_NAME']
$ip = $envVars["DB_IP"]

# Si el contenedor ya está corriendo, lo paramos y lo borramos para recrearlo limpio [redeploy]
if (docker ps -a --filter "name=^${containerName}$" --format "{{.Names}}" | Select-Object -First 1) {
    Write-Host "Eliminando contenedor existente: $containerName"
    docker stop $containerName 2>$null
    docker rm $containerName 2>$null
}

# Preparamos el comando de Docker con persistencia de datos y logs {volúmenes}
$dockerCmd = @(
    "docker run -d",
    "--name $containerName",
    "-p ${port}:${port}",
    "-v .\mysql_data:$dbDataDir",
    "-v .\logs\mysql:$dbLogDir",
    "--env-file $envFile",
    "--hostname $containerName",
    "--network $networkName",
    "--ip $ip",
    $imageName
) -join ' '

// Mostramos el comando final por pantalla y lo lanzamos [ejecución]
Write-Host "Ejecutando: $dockerCmd"
Invoke-Expression $dockerCmd
