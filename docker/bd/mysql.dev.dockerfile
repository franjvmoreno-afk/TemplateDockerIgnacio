FROM alpine:latest

# Variables de entorno configurables
ARG DB_PORT=${DB_PORT}
ARG DB_USER=${DB_USER}
ARG DB_DATADIR=${DB_DATADIR}
ENV DB_PORT=${DB_PORT}
ENV DB_ROOT_PASS=${DB_ROOT_PASS} \
    DB_DATABASE=${DB_NAME} \
    DB_USER=${DB_USER} \
    DB_PASS=${DB_PASS}

# Instalar mariadb y cliente
RUN apk update && \
    apk add --no-cache mariadb mariadb-client mariadb-server-utils && \
    addgroup -S ${DB_USER} && \
    adduser -S ${DB_USER} -G ${DB_USER} && \
    mkdir -p ${DB_DATADIR} && \
    chown -R ${DB_USER}:${DB_USER} ${DB_DATADIR} && \
    echo "[mysqld] \n \
    datadir=${DB_DATADIR} \n \
    socket=/var/lib/mysql/mysql.sock \n \
    user=mysql \n \
    bind-address=0.0.0.0" > /etc/my.cnf && \
    rm -rf /var/cache/apk/* /tmp/* && \
    mariadb-install-db --user=${DB_USER} --datadir=${DB_DATADIR}


# Exponer puerto
EXPOSE ${DB_PORT}

# Usuario no root
USER ${DB_USER}

# Entrypoint y comando por defecto
CMD ["mysqld", "--user=${DB_USER}", "--datadir=${DB_DATADIR}", "--skip-networking=0"]

