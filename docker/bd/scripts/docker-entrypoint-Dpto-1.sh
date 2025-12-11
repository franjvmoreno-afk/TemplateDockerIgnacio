#!/bin/sh
set -e

# Inicializar datadir si está vacío
if [ ! -d "${DB_DATADIR}/mysql" ]; then
    echo "Inicializando base de datos..."
    mariadb-install-db --user=${DB_USER} --datadir=${DB_DATADIR}
fi

# Arrancar MariaDB en segundo plano
echo "Arrancando MariaDB..."
mysqld_safe --user=${DB_USER} --datadir=${DB_DATADIR} &
PID=$!

# Esperar a que el servidor esté listo
sleep 10

mysql -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASS}';
CREATE DATABASE ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'%';
FLUSH PRIVILEGES;
EOF

# Ejecutar todos los scripts SQL en /entrysql
if [ -d "/entrypointsql" ]; then
    for f in /entrypointsql/*.sql; do
        if [ -f "$f" ]; then
            echo "Ejecutando $f..."
            mysql -u root -p"${DB_ROOT_PASS}" < "$f"
        fi
    done
fi

# Mantener el proceso principal
wait $PID
