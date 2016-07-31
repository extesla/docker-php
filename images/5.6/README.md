php:5.6
=======

## Installing Shared Extensions

### Postgres

Postgres support was not configured by default when PHP was compiled and
installed. It can be added by executing the following instructions within
a Dockerfile:

```
RUN apk add --no-cache --virtual .postgres-deps \
            libpq postgresql-dev
RUN docker-php-ext-install pgsql
```
