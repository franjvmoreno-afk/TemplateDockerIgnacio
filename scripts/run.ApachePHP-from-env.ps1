# Ruta por defecto del archivo de configuración para levantar el entorno web
Param(
    [string]$envFile = ".\env\dev.apachephp.env"
)
# Cargamos un diccionario vacío para volcar los ajustes del .env
$envVars = @{}

# Si el fichero de entorno se ha movido o no existe, cortamos el grifo [error]
if (-not (Test-Path $envFile)) {
    Write-Error "Archivo de entorno '$envFile' not found."
    exit 1
}

# Leemos el .env y mapeamos cada línea para separar la clave del valor {parsing}
Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*([^=]+)=(.*)$') {
        $envVars[$matches[1]] = $matches[2]
    }
}

# Asignamos a variables locales los valores que necesita Docker para el despliegue
$imageName = $envVars['IMAGE_NAME']
$containerName = $envVars['CONTAINER_NAME'] 
$ip = $envVars['SERVER_IP']
$serverport = $envVars['SERVER_PORT']
$volumepath = $envVars['VOLUME_PATH']
$foldername = $envVars['FOLDER_NAME']
$datavolume = $envVars['DATA_VOLUME']
$datafolder = $envVars['DATA_FOLDER']

$phpinfovolumepath = $envVars['PHPINFO_VOLUME_PATH']
$phpinfofoldername = $envVars['PHPINFO_FOLDER_NAME']

$apachelogpath = $envVars['APACHE_LOG_PATH']

# Verificamos si la red existe; si no, la creamos con su subred y puerta de enlace (network)
if (
        $envVars['NETWORK_NAME'] -and `
        $envVars['NETWORK_SUBNET'] -and `
        $envVars['NETWORK_SUBNET_GATEWAY'] -and `
        $envVars['SERVER_IP'] -and `
        -not (docker network ls --filter "name=^${envVars['NETWORK_NAME]}$" --format "{{.Name}}")
    ) {
        $networkName = $envVars['NETWORK_NAME']
        $networksubnet = $envVars['NETWORK_SUBNET']
        $networksubnetgateway = $envVars['NETWORK_SUBNET_GATEWAY']
        $networkDriver = $envVars['NETWORK_DRIVER']
        
        Write-Host "Creando red: $networkName"
        docker network create $networkName --driver=$networkDriver --subnet=$networksubnet --gateway=$networksubnetgateway
    }else{
        Write-Warning "La red Docker ya existe o faltan parámetros en el env."
    }

# Si ya hay un contenedor con el mismo nombre, lo paramos y lo borramos para que no choque {cleanup}
if (docker ps -a --filter "name=^${containerName}$" --format "{{.Names}}" | Select-Object -First 1) {
    Write-Host "Eliminando contenedor existente: $containerName"
    docker stop $containerName 2>$null
    docker rm $containerName 2>$null
}

# Vaciamos la carpeta de logs local para que no se nos mezclen fallos antiguos [logs]
if (Test-Path $apachelogpath) {
    Write-Host "Limpiando contenido de: $apachelogpath"
    Remove-Item "$apachelogpath\*" -Force -Recurse
}

# Montamos el comando de ejecución con todos los volúmenes, la red y la IP fija
$dockerCmd = @(
    "docker run -d",
    "--name ${containerName}",
    "-p ${serverport}:80",
    "-v ${phpinfovolumepath}:${phpinfofoldername}",
    "-v ${volumepath}:${foldername}",
    "-v ${datavolume}:${datafolder}",
    "-v ${apachelogpath}:/var/log/apache2",
    "--env-file $envFile",
    "--hostname $containerName",
    "--network $networkName",
    "--ip $ip",
    $imageName
) -join ' '

# Soltamos el comando por consola y lo ejecutamos de golpe {docker_run}
Write-Host "Ejecutando: $dockerCmd"
Invoke-Expression $dockerCmd
