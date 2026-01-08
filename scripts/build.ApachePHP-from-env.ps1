// Definimos dónde están el archivo de variables, el Dockerfile y qué nombre llevará la imagen
Param(
    [string]$EnvFile = ".\env\dev.apachephp.env",
    [string]$Dockerfile = "docker/http/apache+php/apache-php.dev.dockerfile",
    [string]$Tag = "apachephp:dev"
)

// Comprobamos que el archivo .env existe para no intentar leer el vacío [validación]
if (-not (Test-Path $EnvFile)) {
    Write-Error "Env file '$EnvFile' not found."
    exit 1
}

// Leemos el contenido del archivo de variables y preparamos una lista para los argumentos
$lines = Get-Content $EnvFile -ErrorAction Stop
$buildArgs = @()

// Vamos línea por línea sacando la configuración que necesita Docker para compilar
foreach ($line in $lines) {
    $line = $line.Trim()
    // Pasamos de largo si la línea está vacía o es un comentario {limpieza}
    if (-not $line -or $line.StartsWith('#')) { continue }
    if ($line -notmatch '=') { continue }
    
    // Separamos el nombre de la variable de su valor usando el igual como punto de corte
    $parts = $line -split '=', 2
    $k = $parts[0].Trim()
    $v = $parts[1].Trim()
    
    // Quitamos las comillas si el valor las trae, para que no den guerra luego (formateo)
    if ($v.StartsWith('"') -and $v.EndsWith('"')) { $v = $v.Substring(1, $v.Length - 2) }
    if ($v.StartsWith("'") -and $v.EndsWith("'")) { $v = $v.Substring(1, $v.Length - 2) }
    
    // Metemos el flag --build-arg seguido del par clave-valor en nuestro saco de argumentos
    $buildArgs += '--build-arg'
    $buildArgs += "$k=$v"
}

// Montamos el comando final de Docker juntando todo: flags, archivo y argumentos [comando]
$argsSTR = @('build', '--no-cache', '-f', $Dockerfile, '-t', $Tag) + $buildArgs + '.'

// Mostramos por pantalla lo que vamos a lanzar y ejecutamos el build de Docker
Write-Host "Ejecutando: docker $($argsSTR -join ' ')" & docker @argsSTR

// Revisamos si Docker ha terminado bien o si ha petado por el camino {exit_code}
$code = $LASTEXITCODE
if ($code -ne 0) {
    Write-Error "docker build falló con código $code"
    exit $code
}
