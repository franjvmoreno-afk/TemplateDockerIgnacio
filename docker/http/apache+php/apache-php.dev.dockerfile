// Usamos Alpine como base porque pesa poquísimo (distro ligera)
FROM alpine:latest

// Recogemos las variables que vienen de fuera al construir la imagen
ARG SERVER_PORT=${SERVER_PORT}
ARG SERVER_NAME=${SERVER_NAME}
ARG FOLDER_NAME=${FOLDER_NAME}

// Guardamos esos valores en el sistema para que sigan ahí al arrancar {entorno}
ENV FOLDER_NAME=${FOLDER_NAME}
ENV SERVER_PORT=${SERVER_PORT}
ENV SERVER_NAME=${SERVER_NAME}

// Abrimos el puerto de la web y el de Xdebug para depurar [puertos]
EXPOSE ${SERVER_PORT}
EXPOSE 9003

// Instalamos Apache y todo el pack de PHP que necesita Moodle para funcionar
RUN apk update && apk upgrade && \
    apk --no-cache add apache2 apache2-utils apache2-proxy php php-apache2 \
    php-curl php-gd php-mbstring php-intl php-mysqli php-xml php-zip \
    php-ctype php-dom php-iconv php-simplexml php-openssl php-sodium php-tokenizer php-xdebug

// Preparamos la carpeta de la app, damos permisos al usuario apache y creamos rutas de config
RUN mkdir -p ${FOLDER_NAME} \
    && chown -R apache:apache ${FOLDER_NAME} \
    && chmod -R 755 ${FOLDER_NAME} \
    && mkdir -p /etc/php84/conf.d

// Metemos nuestros archivos de configuración personalizados dentro del contenedor (apache y php)
COPY ./docker/http/apache+php/apache/httpd.conf /etc/apache2/httpd.conf
COPY ./docker/http/apache+php/apache/conf.d/*.conf /etc/apache2/conf.d/
COPY ./docker/http/apache+php/php/php.ini /etc/php84/
COPY ./docker/http/apache+php/php/conf.d/*.ini /etc/php84/conf.d/

// Arrancamos el servidor Apache en primer plano para que el contenedor no se pare
ENTRYPOINT ["httpd", "-D", "FOREGROUND"]
