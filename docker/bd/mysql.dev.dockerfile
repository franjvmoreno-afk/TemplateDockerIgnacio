FROM alpine:latest                      # Imagen base ligera

# Variables de entorno configurables
ARG DB_PORT=${DB_PORT}                  # Puerto de MariaDB
ARG DB_USER=${DB_USER}                  # Usuario de base de datos
ARG DB_PASS=${DB_PASS}                  # Contraseña del usuario
ARG DB_ROOT_PASS=${DB_ROOT_PASS}        # Contraseña de root
ARG DB_NAME=${DB_NAME}                  # Nombre de la base de datos
ARG DB_DATADIR=${DB_DATADIR}            # Directorio de datos
ARG DB_LOG_DIR=${DB_LOG_DIR}            # Directorio de logs

# Variables disponibles en tiempo de ejecución
ENV DB_PORT=${DB_PORT} \
    DB_DATADIR=${DB_DATADIR} \
    DB_ROOT_PASS=${DB_ROOT_PASS} \
    DB_NAME=${DB_NAME} \
    DB_USER=${DB_USER} \
    DB_PASS=${DB_PASS} \
    DB_LOG_DIR=${DB_LOG_DIR}

# Instalación de MariaDB y preparación del sistema
RUN apk update && \
    apk add --no-cache mariadb mariadb-client mariadb-server-utils && \  # Paquetes necesarios
    addgroup -S ${DB_USER} && \                                           # Grupo del servicio
    adduser -S ${DB_USER} -G ${DB_USER} && \                              # Usuario sin login
    mkdir -p ${DB_DATADIR} ${DB_LOG_DIR} /entrypointsql && \              # Directorios requeridos
    chown -R ${DB_USER}:${DB_USER} ${DB_DATADIR} ${DB_LOG_DIR} /entrypointsql && \ # Permisos
    chmod -R 755 ${DB_DATADIR} ${DB_LOG_DIR} /entrypointsql && \          # Acceso controlado
    rm -rf /var/cache/apk/* /tmp/* /var/tmp/* && \                        # Limpieza de imagen
    mariadb-install-db --user=${DB_USER} --datadir=${DB_DATADIR}          # Inicializa la BD

# Scripts y configuración personalizada
COPY ./docker/bd/scripts/docker-entrypoint.sh /entrypoint.sh              # Script de arranque
COPY ./docker/bd/sql/*.sql /entrypointsql/                                # SQL inicial
COPY ./docker/bd/conf/mysql.dev.cnf /etc/my.cnf                           # Configuración MySQL

# Ajustes de permisos y formato
RUN chown -R ${DB_USER}:${DB_USER} /entrypoint* && \
    chmod 755 /entrypoint.sh && \
    ls -la /entrypoint*                                                   # Verificación rápida

RUN dos2unix /entrypoint.sh && chmod 755 /entrypoint.sh                   # Evita errores de formato

# USER ${DB_USER}                                                         # Ejecución sin root (opcional)

# Puerto expuesto del contenedor
EXPOSE ${DB_PORT}

# Script principal del contenedor
ENTRYPOINT ["sh", "/entrypoint.sh"]                                        # Arranque del servicio
