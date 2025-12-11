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
$hostEntry = $envVars['HOST_ENTRY'] 
# Ejecutar el contenedor Docker
$dockerCmd = @(
    "docker run -d",
    "--name $containerName",
    "-p $portMapping",
    "-v ${volumePath}:/var/www/${servername}",
    "--env-file $envFile",
    "--add-host=$hostEntry",
    "--hostname $containerName",
    $imageName
) -join ' '

Write-Host "Ejecutando: $dockerCmd"
Invoke-Expression $dockerCmd