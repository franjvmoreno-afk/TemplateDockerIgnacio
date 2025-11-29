FROM alpine:latest

ARG SERVER_NAME=${SERVER_NAME}
ARG SERVER_PORT=${SERVER_PORT}
ENV SERVER_NAME=${SERVER_NAME}
ENV SERVER_PORT=${SERVER_PORT}
EXPOSE ${SERVER_PORT}

RUN apk update && apk upgrade && \
    apk --no-cache add apache2 php82 php82-apache2 \
    php-curl php-gd php-mbstring php-intl php-mysqli php-xml php-zip \
    php-ctype php-dom php-iconv php-simplexml php-openssl php-sodium php-tokenizer
RUN mkdir -p /var/www/${ROOT_DOC_FOLDER} \
    && chown -R apache:apache /var/www/${ROOT_DOC_FOLDER} \
    && chmod -R 755 /var/www/${ROOT_DOC_FOLDER}

COPY ./docker/http/apache+php/conf/*.conf /etc/apache2/conf.d/
ENTRYPOINT ["httpd", "-D", "FOREGROUND"]