# syntax=docker/dockerfile:1
# PHP CLI image used by the backend, queue and scheduler services and by
# every one-off `composer` / `artisan` command (see Makefile).
FROM php:8.3-cli-bookworm

ARG UID=1000
ARG GID=1000
ARG PHPREDIS_VERSION=6.2.0

RUN apt-get update \
    && apt-get install -y --no-install-recommends git unzip curl libpq-dev libzip-dev libicu-dev \
    && docker-php-ext-install -j"$(nproc)" pdo_pgsql pgsql bcmath pcntl zip intl \
    && pecl install "redis-${PHPREDIS_VERSION}" \
    && docker-php-ext-enable redis \
    && rm -rf /var/lib/apt/lists/* /tmp/pear

COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer

# Run as a user matching the host UID/GID so bind-mounted files are not
# owned by root. macOS GIDs (e.g. 20) may already exist in Debian: reuse them.
RUN (getent group "${GID}" >/dev/null || groupadd -g "${GID}" app) \
    && useradd -m -u "${UID}" -g "${GID}" -s /bin/bash app \
    && mkdir -p /var/www/html/vendor /home/app/.composer \
    && chown -R "${UID}:${GID}" /var/www/html /home/app

# vendor/ is mounted as a named volume (see compose.yaml); creating it here, owned
# by the app user, makes a fresh volume inherit that ownership.
ENV COMPOSER_HOME=/home/app/.composer
WORKDIR /var/www/html
USER app

EXPOSE 8000
