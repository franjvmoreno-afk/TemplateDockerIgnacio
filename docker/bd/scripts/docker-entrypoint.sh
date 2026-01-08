#!/bin/sh

# Inicializa el directorio de datos si MySQL aún no existe
if [ ! -d "${DB_DATADIR}/mysql" ]; then
    echo "Inicializando base de datos..."
    mariadb-install-db --user=${DB_USER} --datadir=${DB_DATADIR}  # Crea estructura inicial de MariaDB
fi

# Arranca MariaDB en segundo plano
echo "Arrancando MariaDB..."
mariadbd-safe --user=${DB_USER} --datadir=${DB_DATADIR} &         # Inicio seguro del servidor
PID=$!                                                           # Guarda el PID del proceso

# Espera a que MariaDB esté disponible
sleep 10                                                         # Tiempo de arranque del servicio

/usr/bin/mariadb -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASS}';   -- Establece contraseña de root
CREATE DATABASE ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci; -- BD para Moodle
CREATE USER '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASS}';         -- Usuario de la aplicación
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'%';        -- Permisos completos sobre la BD
FLUSH PRIVILEGES;                                                -- Aplica los cambios
EOF

# Ejecuta scripts SQL personalizados si existen
if [ -d "/entrypointsql" ]; then
    for f in /entrypointsql/*.sql; do
        if [ -f "$f" ]; then
            echo "Ejecutando $f..."
            /usr/bin/mariadb -u root -p"${DB_ROOT_PASS}" < "$f"   # Importa script SQL
        fi
    done
fi

# Mantiene vivo el proceso principal
wait $PID                                                        # Evita que el contenedor se cierre
