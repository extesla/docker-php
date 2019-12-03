# The MIT License (MIT)
#
# Copyright (c) Extesla, LLC.
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

FROM extesla/alpine
LABEL maintainer="Sean Quinn <sean.quinn@extesla.com>"

RUN apk update && apk upgrade
RUN apk add --no-cache --virtual .phpize-deps \
            autoconf dpkg-dev dpkg file freetype freetype-dev \
            g++ gcc libc-dev libgcrypt-dev libxslt-dev make pkgconf \
 && apk add --no-cache --virtual .php-deps \
            bzip2 ca-certificates curl gdbm gettext icu icu-libs libdbi \
            libedit libintl libjpeg-turbo libjpeg-turbo-dev \
            libpng libpng-dev libxml2 libxslt libressl re2c tar xz \
 && apk add --no-cache --virtual .build-deps \
            argon2-dev bzip2-dev coreutils curl-dev gdbm-dev gettext-dev \
            gnupg icu-dev libdbi-dev libedit-dev libressl-dev libsodium-dev \
            libxml2-dev linux-headers oniguruma-dev postgresql-dev sqlite-dev

#: Create the www-data user if it doesn't exist with gid/uid 82.
#:
#: The gid/uid '82' is the standard value for the "www-data" group and user
#: in Alpine.
#:
#: See:
#:   http://git.alpinelinux.org/cgit/aports/tree/main/apache2/apache2.pre-install?h=v3.3.2
#:   http://git.alpinelinux.org/cgit/aports/tree/main/lighttpd/lighttpd.pre-install?h=v3.3.2
#:   http://git.alpinelinux.org/cgit/aports/tree/main/nginx-initscripts/nginx-initscripts.pre-install?h=v3.3.2
RUN set -x \
 && addgroup -g 82 -S www-data \
 && adduser -u 82 -D -S -G www-data www-data \
 && echo "www-data ALL=(ALL) NOPASSWD:ALL" | tee -a /etc/sudoers \
 && mkdir -p /var/www \
 && chown -R www-data:www-data /var/www

ENV GPG_KEYS="5A52880781F755608BF815FC910DEB46F53EA312 42670A7FE4D0441C8E4632349E4FDC074A4EF02D"

#: PHP Version
ENV PHP_VERSION 7.4.0
ENV PHP_FILENAME php-7.4.0.tar.xz
ENV PHP_URL "https://secure.php.net/get/${PHP_FILENAME}/from/this/mirror"
ENV PHP_ASC_URL "https://secure.php.net/get/${PHP_FILENAME}.asc/from/this/mirror"
ENV PHP_SHA256 9bb751b20e5d6cc1ea9b1ebf23ef2d5f07f99b2d9cc417bf1d70c04f8b20ec42

ENV PHP_INI_DIR /etc/php

# Apply stack smash protection to functions using local buffers and alloca()
# Make PHP's main executable position-independent (improves ASLR security mechanism, and has no performance impact on x86_64)
# Enable optimization (-O2)
# Enable linker optimization (this sorts the hash buckets to improve cache locality, and is non-default)
# Adds GNU HASH segments to generated executables (this is used if present, and is much faster than sysv hash; in this configuration, sysv hash is also generated)
# https://github.com/docker-library/php/issues/272
# -D_LARGEFILE_SOURCE and -D_FILE_OFFSET_BITS=64 (https://www.php.net/manual/en/intro.filesystem.php)
ENV PHP_CFLAGS="-fstack-protector-strong -fpic -fpie -O2 -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64"
ENV PHP_CPPFLAGS="$PHP_CFLAGS"
ENV PHP_LDFLAGS="-Wl,-O1 -Wl,--hash-style=both -pie"

RUN set -xe \
 && wget -O "$PHP_FILENAME" "$PHP_URL" \
 && echo "$PHP_SHA256 *$PHP_FILENAME" | sha256sum -c - \
 && wget -O "$PHP_FILENAME.asc" "$PHP_ASC_URL" \
 && mkdir -p /tmp/gnupg \
 && export GNUPGHOME="$(mktemp -d -p /tmp/gnupg)" \
 && for key in $GPG_KEYS; do \
      gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys "$key" ; \
      gpg --batch --keyserver pgp.mit.edu --recv-keys "$GPG_KEYS"; \
      gpg --batch --keyserver keyserver.pgp.com --recv-keys "$key" ; \
    done \
 && gpg --batch --verify "$PHP_FILENAME.asc" "$PHP_FILENAME" \
 && gpgconf --kill all \
 && rm -rf "$GNUPGHOME" "$PHP_FILENAME.asc"

RUN mkdir -p /usr/src \
 && tar -Jxf "$PHP_FILENAME" -C /usr/src \
 && mv "/usr/src/php-$PHP_VERSION" /usr/src/php \
 && rm "$PHP_FILENAME"
COPY files/phpmake /phpmake
RUN chmod +x /phpmake

#: Add scripts to create/add extensions with ease
COPY files/usr/local/bin/docker-php-ext-* /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-php-ext-*

#: ==========================================================================
#: PHP Installation & Configuration
#: ==========================================================================

RUN mkdir -p $PHP_INI_DIR \
 && mkdir -p $PHP_INI_DIR/conf.d \
 && mkdir -p $PHP_INI_DIR/mods-available

WORKDIR /usr/src/php

#: Configure and build PHP
#:
#: The flag --enable-mysqlnd is included because it's harder to compile
#: after the fact than extensions are (since it's a plugin for several
#: extensions, not an extension in itself)

RUN export CFLAGS="$PHP_CFLAGS" \
           CPPFLAGS="$PHP_CPPFLAGS" \
           LDFLAGS="$PHP_LDFLAGS" \
  ; \
  /phpmake -o --with-config-file-path="$PHP_INI_DIR" \
           -o --with-config-file-scan-dir="$PHP_INI_DIR/conf.d" \
           -o --enable-option-checking=fatal \
           -o --enable-fpm \
           -o --with-fpm-user=www-data \
           -o --with-fpm-group=www-data \
           -o --disable-cgi \
           -o --disable-short-tags \
           -o --enable-bcmath \
           -o --enable-calendar \
           -o --enable-exif \
           -o --enable-ftp \
           -o --enable-intl \
           -o --enable-mbstring \
           -o --enable-mysqlnd \
           -o --enable-pcntl \
           -o --enable-sockets \
           -o --enable-shmop \
           -o --enable-sysvmsg \
           -o --with-bz2 \
           -o --with-curl \
           -o --with-libedit \
           -o --with-gettext \
           -o --with-mhash \
           -o --with-openssl \
           -o --with-password-argon2 \
           -o --with-pdo-mysql \
           -o --with-pdo-pgsql \
           -o --with-pdo-sqlite=/usr \
           -o --with-pear \
           -o --with-pgsql \
           -o --with-readline \
           -o --with-sodium=shared \
           -o --with-sqlite3=/usr \
           -o --with-system-ciphers \
           -o --with-zlib \
           -o --with-xsl \
 && apk del --no-network .build-deps \
 && rm -rf /var/cache/apk/* \
 && cp /usr/src/php/php.ini-production /etc/php/php.ini \
 && pecl update-channels \
 && rm -rf /tmp/pear ~/.pearrc \
 && docker-php-ext-configure gd --with-freetype --with-jpeg \
 && docker-php-ext-enable sodium \
 && php --version

#: ==========================================================================
#: PHP FPM Configuration
#: ==========================================================================

RUN set -xe \
 && cd /etc/php \
 && if [ -d php-fpm.d ]; then \
      # for some reason, upstream's php-fpm.conf.default has "include=NONE/etc/php-fpm.d/*.conf"
      sed 's!=NONE/!=!g' php-fpm.conf.default | tee php-fpm.conf > /dev/null; \
      cp php-fpm.d/www.conf.default php-fpm.d/www.conf; \
    else \
      # PHP 5.x don't use "include=" by default, so we'll create our own simple config that mimics PHP 7+ for consistency
      mkdir php-fpm.d; \
      cp php-fpm.conf.default php-fpm.d/www.conf; \
      { \
        echo '[global]'; \
        echo 'pid=/var/run/php-fpm.pid'; \
        echo 'include=/etc/php/php-fpm.d/*.conf'; \
      } | tee php-fpm.conf; \
    fi \
 && { \
      echo '[www]'; \
      echo 'user = www-data'; \
      echo 'group = www-data'; \
      echo; \
      echo '; if we send this to /proc/self/fd/1, it never appears'; \
      echo 'access.log = /proc/self/fd/2'; \
      echo; \
      echo 'clear_env = no'; \
      echo; \
      echo 'listen = /run/php-fpm.sock'; \
      echo 'listen.owner = www-data'; \
      echo 'listen.group = www-data'; \
      echo; \
      echo 'pm = ondemand'; \
      echo 'pm.process_idle_timeout = 30s'; \
      echo 'pm.max_children = 10'; \
      echo 'pm.status_path = /status'; \
      echo; \
      echo 'ping.path = /ping'; \
      echo 'ping.response = pong'; \
      echo; \
      echo '; Ensure worker stdout and stderr are sent to the main error log.'; \
      echo 'catch_workers_output = yes'; \
     } | tee php-fpm.d/www.conf \
 && { \
      echo '[global]'; \
      echo 'error_log = /proc/self/fd/2'; \
    } | tee php-fpm.d/docker.conf \
 && { \
      echo '[global]'; \
      echo 'daemonize = no'; \
    } | tee php-fpm.d/zz-docker.conf

WORKDIR /

#: Clear the APK cache before we finish.
RUN rm -rf /var/cache/apk/*

#: Copy init.d script (its a modified version of what is available under the
#: PHP source: /usr/src/sapi/fpm/init.d.php-fpm)
COPY files/etc/init.d/php-fpm /etc/init.d/php-fpm
RUN chmod +x /etc/init.d/php-fpm

#: Enable additional extensions
COPY files/etc/php/mods-available /etc/php/mods-available
RUN ln -s /etc/php/mods-available/opcache.ini /etc/php/conf.d/05-opcache.ini

# Override stop signal to stop process gracefully
# https://github.com/php/php-src/blob/17baa87faddc2550def3ae7314236826bc1b1398/sapi/fpm/php-fpm.8.in#L163
STOPSIGNAL SIGQUIT

#: Default Command.
#:
#: If the PHP container is invoked directly without a command or arguments,
#: it will launch the user into the interactive PHP shell.
CMD ["php", "-a"]
