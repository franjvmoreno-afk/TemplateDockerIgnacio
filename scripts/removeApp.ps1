# Script de limpieza total para dejar el repositorio sin rastro de submódulos externos
# Ignacio: este script limpia .gitmodules, .git/config, .git/modules y el working tree

# Mensaje inicial para confirmar que el script ha empezado a trabajar
Write-Host "Detectando submódulos..." -ForegroundColor Cyan

# Guardamos la ruta del archivo donde Git anota qué submódulos tiene el proyecto [config]
$gitmodules = ".gitmodules"

# Comprobamos si el archivo existe; si no está, es que no hay nada que borrar {validación}
if (!(Test-Path $gitmodules)) {
    Write-Host "No existe .gitmodules. No hay submódulos que eliminar." -ForegroundColor Yellow
    exit
}

# Buscamos dentro del archivo la ruta de cada carpeta que Git gestiona como externa
$submodules = Select-String -Path $gitmodules -Pattern "path = " | ForEach-Object {
    ($_ -split "path = ")[1].Trim()
}

# Si el archivo está pero no tiene rutas, paramos el script porque no hay faena (lista vacía)
if ($submodules.Count -eq 0) {
    Write-Host "No se encontraron submódulos en .gitmodules." -ForegroundColor Yellow
    exit
}

# Listado por pantalla de los módulos que se van a ir al pozo
Write-Host "Submódulos detectados:" -ForegroundColor Green
$submodules | ForEach-Object { Write-Host " - $_" }

# Empezamos a recorrer la lista para ir borrándolos uno a uno [bucle]
foreach ($sub in $submodules) {

    Write-Host "`nEliminando submódulo: $sub" -ForegroundColor Cyan

    # Desvinculamos el submódulo de la configuración local de Git para que no de guerra
    git submodule deinit -f $sub | Out-Null

    # Quitamos el rastro del submódulo del índice de Git para que deje de trackearlo {index}
    git rm -f $sub | Out-Null

    # Borramos la carpeta física con todo su contenido para liberar espacio en disco
    if (Test-Path $sub) {
        Remove-Item -Recurse -Force $sub
        Write-Host "Carpeta eliminada: $sub"
    }

    # Localizamos y fulminamos la caché interna que guarda Git en su carpeta oculta (limpieza profunda)
    $modulePath = ".git/modules/$sub"
    if (Test-Path $modulePath) {
        Remove-Item -Recurse -Force $modulePath
        Write-Host "Carpeta interna eliminada: $modulePath"
    }
}

# Eliminamos el archivo de configuración global de submódulos porque ya no tiene sentido
Remove-Item -Force ".gitmodules"
Write-Host "`nArchivo .gitmodules eliminado." -ForegroundColor Green

# Preparamos todos los cambios del borrado y cerramos el commit para dejarlo registrado [git_commit]
git add -A
git commit -m "Remove all submodules" | Out-Null

# Confirmación final de que el repositorio está impoluto y sin dependencias externas
Write-Host "`n✅ Todos los submódulos han sido eliminados completamente." -ForegroundColor Green
