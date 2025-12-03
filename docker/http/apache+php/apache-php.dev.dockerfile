FROM alpine:latest

ARG SERVER_PORT=${SERVER_PORT}
ARG SERVER_NAME=${SERVER_NAME}

ENV SERVER_NAME=${SERVER_NAME}
ENV SERVER_PORT=${SERVER_PORT}

EXPOSE ${SERVER_PORT}
EXPOSE 9003

RUN apk update && apk upgrade && \
    apk --no-cache add apache2 apache2-utils apache2-proxy php82 php82-apache2 \
    php-curl php-gd php-mbstring php-intl php-mysqli php-xml php-zip \
    php-ctype php-dom php-iconv php-simplexml php-openssl php-sodium php-tokenizer php-xdebug
RUN mkdir -p /var/www/${SERVER_NAME} \
    && chown -R apache:apache /var/www/${SERVER_NAME} \
    && chmod -R 755 /var/www/${SERVER_NAME}

#COPY ./docker/http/apache+php/conf/httpd.conf /etc/apache2/httpd.conf
COPY ./docker/http/apache+php/conf.d/php-xdebug.ini /etc/php82/conf.d/php-xdebug.ini
COPY ./docker/http/apache+php/conf.d/*.conf /etc/apache2/conf.d/
ENTRYPOINT ["httpd", "-D", "FOREGROUND"]