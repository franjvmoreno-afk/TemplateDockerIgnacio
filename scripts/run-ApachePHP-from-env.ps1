# Cargar variables de entorno desde el archivo
$envFile = ".\env\dev.apachephp.env"
$envVars = @{}

if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^\s*([^=]+)=(.*)$') {
            $envVars[$matches[1]] = $matches[2]
        }
    }
}
else {
    Write-Error "Archivo $envFile no encontrado"
    exit 1
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