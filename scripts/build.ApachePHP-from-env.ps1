# Seteamos las rutas por defecto para el env, el dockerfile y el nombre de la imagen
Param(
    [string]$EnvFile = ".\env\dev.apachephp.env",
    [string]$Dockerfile = "docker/http/apache+php/apache-php.dev.dockerfile",
    [string]$Tag = "apachephp:dev"
)

# Miramos si el archivo .env está en su sitio para no leer a ciegas [validación]
if (-not (Test-Path $EnvFile)) {
    Write-Error "Env file '$EnvFile' not found."
    exit 1
}

# Sacamos el texto del .env y preparamos un array para los argumentos del build
$lines = Get-Content $EnvFile -ErrorAction Stop
$buildArgs = @()

# Escaneamos el archivo buscando las variables que necesita Docker para compilar
foreach ($line in $lines) {
    $line = $line.Trim()
    # Si la línea está vacía o es un comentario, pasamos de ella {limpieza}
    if (-not $line -or $line.StartsWith('#')) { continue }
    if ($line -notmatch '=') { continue }
    
    # Partimos la línea por el igual para separar la clave del contenido
    $parts = $line -split '=', 2
    $k = $parts[0].Trim()
    $v = $parts[1].Trim()
    
    # Limpiamos las comillas (simples o dobles) para que Docker no se raye [formateo]
    if ($v.StartsWith('"') -and $v.EndsWith('"')) { $v = $v.Substring(1, $v.Length - 2) }
    if ($v.StartsWith("'") -and $v.EndsWith("'")) { $v = $v.Substring(1, $v.Length - 2) }
    
    # Añadimos el flag --build-arg con su par clave=valor a la lista de argumentos
    $buildArgs += '--build-arg'
    $buildArgs += "$k=$v"
}

# Creamos el comando final de Docker uniendo todas las piezas {build_string}
$argsSTR = @('build', '--no-cache', '-f', $Dockerfile, '-t', $Tag) + $buildArgs + '.'

# Escupimos por consola el comando que vamos a lanzar y ejecutamos el build
Write-Host "Ejecutando: docker $($argsSTR -join ' ')" & docker @argsSTR

# Chequeamos si el build ha ido bien o si ha saltado algún error de Docker (status_code)
$code = $LASTEXITCODE
if ($code -ne 0) {
    Write-Error "docker build falló con código $code"
    exit $code
}
