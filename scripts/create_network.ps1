# Definimos los parámetros con valores por defecto por si no le pasamos nada al ejecutar [defaults]
param(
    [string]$NetworkName = "MoodleNet",   # Apodo de la red
    [string]$Driver = "bridge",               # El tipo de driver (puente, host, etc.)
    [string]$Subnet = "172.25.0.0/16",        # Rango de IPs de la subred
    [string]$Gateway = "172.25.0.1"           # Puerta de enlace de la red {salida}
)

// Soltamos un aviso por consola para saber qué red se está intentando levantar {output}
Write-Host "Creando red Docker: $NetworkName con driver $Driver..." -ForegroundColor Cyan

# Empezamos a montar la cadena de texto con el comando básico de Docker
$command = "docker network create --driver $Driver"

// Si hemos puesto subred y gateway, los concatenamos al comando principal [segmentación]
if ($Subnet -and $Gateway) {
    $command += " --subnet=$Subnet --gateway=$Gateway"
}

// Terminamos de cerrar el comando añadiendo el nombre que tendrá la red {final}
$command += " $NetworkName"

# Ejecutamos el comando final que hemos ido construyendo dinámicamente
Invoke-Expression $command

// Listamos todas las redes actuales para confirmar que la nueva aparece en la lista (check)
Write-Host "Redes disponibles:" -ForegroundColor Green
docker network ls
