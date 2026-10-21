ARG ALPINE_VERSION=3.24
FROM alpine:${ALPINE_VERSION}
LABEL Maintainer="Tim de Pater <code@trafex.nl>"
LABEL Description="Lightweight container with Nginx & PHP 8.3 based on Alpine Linux."
# Setup document root
WORKDIR /var/www/html

# Install packages and remove default server definition
RUN apk add --no-cache \
  curl \
  nginx \
  php83 \
  php83-ctype \
  php83-curl \
  php83-dom \
  php83-fpm \
  php83-gd \
  php83-intl \
  php83-mbstring \
  php83-mysqli \
  php83-opcache \
  php83-openssl \
  php83-phar \
  php83-session \
  php83-xml \
  php83-xmlreader \
  php83-zlib \
  php83-redis \
  php83-tokenizer \
  php83-fileinfo \
  php83-zip \
  php83-pdo \
  php83-pdo_mysql \
  php83-pdo_pgsql \
  php83-exif \
  php83-xmlwriter \
  php83-pecl-xdebug \
  supervisor

# Create symlink so programs depending on `php` still function
RUN ln -s /usr/bin/php83 /usr/bin/php

COPY --from=docker.io/composer:2 /usr/bin/composer /usr/local/bin/composer

# Configure nginx
COPY config/nginx.conf /etc/nginx/nginx.conf

# Configure PHP-FPM
COPY config/fpm-pool.conf /etc/php83/php-fpm.d/www.conf
COPY config/php.ini /etc/php83/conf.d/custom.ini

# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Make sure files/folders needed by the processes are accessable when they run under the nobody user
RUN chown -R nobody:nobody /var/www/html /run /var/lib/nginx /var/log/nginx

# Switch to use a non-root user from here on
USER nobody

# Add application
COPY --chown=nobody src/ /var/www/html/

# Expose the port nginx is reachable on
EXPOSE 8080

# Let supervisord start nginx & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# Configure a healthcheck to validate that everything is up&running
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping
