FROM php:8.1-cli-alpine

RUN apk add tini

COPY . /srv/app

WORKDIR /srv/app

# See: https://stackoverflow.com/questions/63447441/docker-stop-for-crond-times-out
ENTRYPOINT ["tini", "--", "./docker-entrypoint.sh"]

CMD ["crond", "-f"]
