Param(
    [string]$envFile = ".\env\dev.apachephp.env"
)
# Cargar variables de entorno desde el archivo
$envVars = @{}

if (-not (Test-Path $envFile)) {
    Write-Error "Archivo de entorno '$envFile' no encontrado."
    exit 1
}


Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*([^=]+)=(.*)$') {
        $envVars[$matches[1]] = $matches[2]
    }
}

# Configurar variables
$servername = $envVars['SERVER_NAME'] 
$containerName = $envVars['CONTAINER_NAME'] 
$portMapping = $envVars['PORT_MAPPING'] 
$volumePath = $envVars['VOLUME_PATH']
$imageName = $envVars['IMAGE_NAME']
$networkName = $envVars['NETWORK_NAME']
$ip = $envVars['SERVER_IP']

# Eliminar contenedor si existe
if (docker ps -a --filter "name=^${containerName}$" --format "{{.Names}}" | Select-Object -First 1) {
    Write-Host "Eliminando contenedor existente: $containerName"
    docker stop $containerName 2>$null
    docker rm $containerName 2>$null
}

# Ejecutar el contenedor Docker
$dockerCmd = @(
    "docker run -d",
    "--name $containerName",
    "-p $portMapping",
    "-v ${volumePath}:/var/www/${servername}",
    "-v .\logs\apachephp:/var/log/apache2",
    "--env-file $envFile",
    "--hostname $containerName",
    "--network $networkName",
    "--ip $ip"
    $imageName
) -join ' '

Write-Host "Ejecutando: $dockerCmd"
Invoke-Expression $dockerCmd