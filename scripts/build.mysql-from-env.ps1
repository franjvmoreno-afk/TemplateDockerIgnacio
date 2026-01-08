# Parámetro de entrada con la ruta del archivo de configuración de MySQL
param(
    [string]$envFile = ".\env\dev.mysql.env"
)
# Creamos un diccionario vacío para guardar las variables que leamos (hash table)
$envVars = @{}

# Si el archivo de entorno no está donde debería, cortamos el proceso [validación]
if (-not (Test-Path $envFile)) {
    Write-Error "Env file '$envFile' not found."
    exit 1
} 

# Leemos el archivo y usamos una expresión regular para separar clave y valor {mapeo}
Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*([^=]+)=(.*)$') {
        $envVars[$matches[1]] = $matches[2]
    }
}

# Sacamos del diccionario la ruta del Dockerfile y el nombre de la imagen [labels]
$Dockerfile = $envVars['DB_DOCKERFILE']
$Tag = $envVars['DB_IMAGE_NAME']

# Montamos el churro de argumentos que le pasaremos a Docker (passwords, puertos, etc.)
$buildArgsSTR = @(
    "--build-arg DB_USER=" + $envVars['DB_USER'],
    "--build-arg DB_PASS=" + $envVars['DB_PASS'],
    "--build-arg DB_ROOT_PASS=" + $envVars['DB_ROOT_PASS'],
    "--build-arg DB_DATADIR=" + $envVars['DB_DATADIR'],
    "--build-arg DB_PORT=" + $envVars['DB_PORT'],
    "--build-arg DB_NAME=" + $envVars['DB_NAME'],
    "--build-arg DB_LOG_DIR=" + $envVars['DB_LOG_DIR']
) -join ' '

# Juntamos todas las piezas para formar el comando de construcción final (docker build)
$cmddockerSTR = @('docker build', '--no-cache', '-f', $Dockerfile, '-t', $Tag, $buildArgsSTR, '.') -join ' '

# Imprimimos por consola el comando resultante y lo lanzamos de inmediato {exec}
Write-Host "Ejecutando: docker $cmddockerSTR" 
Invoke-Expression $cmddockerSTR

# Capturamos el resultado del comando para avisar si la compilación ha fallado (exit_code)
$code = $LASTEXITCODE
if ($code -ne 0) {
    Write-Error "docker build falló con código $code"
    exit $code
}
