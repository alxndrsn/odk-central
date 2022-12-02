# see: https://github.com/tianon/docker-postgres-upgrade/blob/master/9.6-to-15/Dockerfile
FROM tianon/postgres-upgrade:9.6-to-15

RUN apt update && apt install lsof procps

# This file should be provided by the sysadmin performing the upgrade:
COPY allow-postgres-database-version-update .

COPY files/postgres/odk-migrate-postgres /usr/local/bin/

# we can't rename/remap this directory, as it's an anonymous volume
ENV PGDATAOLD=/var/lib/postgresql/data

ENTRYPOINT []
CMD odk-migrate-postgres
