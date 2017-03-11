FROM php:7.0-alpine

LABEL maintainer Srdjan Vranac <vranac@gmail.com>

# persistent / runtime deps
ENV PHPIZE_DEPS \
    autoconf \
    cmake \
    file \
    g++ \
    gcc \
    libc-dev \
    make \
    git \
    pkgconf \
    re2c

# https://pkgs.alpinelinux.org/packages?name=&branch=&repo=&arch=&maintainer=
RUN echo http://dl-4.alpinelinux.org/alpine/v3.3/main/ >>/etc/apk/repositories \
    && echo http://dl-4.alpinelinux.org/alpine/v3.3/community/ >>/etc/apk/repositories \
    && echo http://dl-4.alpinelinux.org/alpine/v3.4/main/ >>/etc/apk/repositories \
    && echo http://dl-4.alpinelinux.org/alpine/v3.4/community/ >>/etc/apk/repositories \
    && echo http://dl-4.alpinelinux.org/alpine/v3.5/main/ >>/etc/apk/repositories \
    && echo http://dl-4.alpinelinux.org/alpine/v3.5/community/ >>/etc/apk/repositories \
    && echo http://dl-4.alpinelinux.org/alpine/edge/main/ >>/etc/apk/repositories \
    && echo http://dl-4.alpinelinux.org/alpine/edge/community/ >>/etc/apk/repositories \
    && echo http://dl-4.alpinelinux.org/alpine/edge/testing/ >>/etc/apk/repositories \
    && apk update \
    && apk add --no-cache --virtual .build-deps \
            $PHPIZE_DEPS \
    && apk add git \
            bash \
            curl \
            icu \
            icu-libs \
            icu-dev \
            postgresql-dev \
            icu-dev \
            freetype \
            libpng \
            libjpeg-turbo \
            freetype-dev \
            libpng-dev \
            libjpeg-turbo-dev \
            imagemagick \
            imagemagick-dev \
            libtool \
            php7-mcrypt \
            php7-gd \
            php7-exif \
            php7-pdo_mysql \
            php7-pdo_pgsql \
            php7-curl \
            php7-intl \
            php7-bcmath \
            php7-mbstring \
            php7-dom \
            php7-zip \
            php7-xsl \
            php7-pcntl \
            php7-opcache \
            php7-xdebug \
            php7-calendar \
            php7-ctype \
            php7-gettext \
            php7-iconv \
            php7-json \
            php7-mysqli \
            php7-pgsql \
            php7-pdo_pgsql \
            php7-sockets \
            php7-redis \
    && pecl install imagick-3.4.3 \
    && rm -rf /var/cache/apk/* \
    # Install Composer
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    # Install Symfony installer
    && curl -LsS https://symfony.com/installer -o /usr/local/bin/symfony \
    &&  chmod a+x /usr/local/bin/symfony \
    # create aliases
    && echo "alias php-debug='/usr/local/bin/php -dzend_extension=/usr/lib/php7/modules/xdebug.so'" >> ~/.bashrc \
    && echo "alias php-profiler='XDEBUG_CONFIG=\"profiler_enable=1\" /usr/local/bin/php -dzend_extension=/usr/lib/php7/modules/xdebug.so'" >> ~/.bashrc

# configure extensions
ADD ./php-configuration/ /usr/local/etc/php/conf.d/
ADD ./php-xdebug/xdebug.ini ./php-xdebug/xdebug-profiler.ini /usr/local/etc/php/conf.d/

RUN mkdir -p /var/log/xdebug
RUN mkdir -p /var/log/xdebug/profiler_output

ARG DESTINATION_PATH

WORKDIR $DESTINATION_PATH
