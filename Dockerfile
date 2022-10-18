FROM php:8.1-cli-alpine

RUN apk add tini

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
# https://getcomposer.org/doc/03-cli.md#composer-allow-superuser
ENV COMPOSER_ALLOW_SUPERUSER=1

COPY . /srv/app

WORKDIR /srv/app

RUN COMPOSER_MEMORY_LIMIT=-1 composer install --prefer-dist --no-dev --no-progress --no-scripts --no-interaction

# See: https://stackoverflow.com/questions/63447441/docker-stop-for-crond-times-out
ENTRYPOINT ["tini", "--", "./docker-entrypoint.sh"]

CMD ["crond", "-f"]
