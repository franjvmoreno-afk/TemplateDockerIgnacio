# Definimos los parámetros obligatorios para que el script no pete por falta de info
param(
    # Nombre que le vamos a poner al submódulo (ej. un plugin de Moodle)
    [Parameter(Mandatory=$true)]
    [string]$SubmoduleName,
    
    # El enlace de GitHub de donde vamos a sacar el código fuente
    [Parameter(Mandatory=$true)]
    [string]$GitHubUrl,
    
    # La carpeta de nuestro proyecto donde queremos que caigan los archivos {destino}
    [Parameter(Mandatory=$true)]
    [string]$DestinationPath
)

# Abrimos un bloque de "intento" para controlar si algo falla a mitad [try-catch]
try {
    # Chivatos por consola para saber qué se está bajando y hacia dónde va
    Write-Host "Adding submodule: $SubmoduleName"
    Write-Host "From: $GitHubUrl"
    Write-Host "To: $DestinationPath"
    
    # Ejecutamos el comando real de Git que vincula el repositorio externo
    git submodule add $GitHubUrl $DestinationPath
    
    # Miramos si el comando de Git ha terminado sin errores (código de salida 0)
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Submodule added successfully!" -ForegroundColor Green
    } else {
        # Si Git da problemas, lanzamos un aviso en rojo y paramos el proceso [error]
        Write-Host "Error adding submodule" -ForegroundColor Red
        exit 1
    }
}
# Si ocurre una excepción inesperada de PowerShell, la capturamos aquí {pánico}
catch {
    Write-Host "Exception: $_" -ForegroundColor Red
    exit 1
}
