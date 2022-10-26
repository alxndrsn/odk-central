FROM tianon/postgres-upgrade:9.6-to-14

COPY files/postgres/odk-migrate-postgres /usr/local/bin/

ENV PGBINOLD=/var/lib/postgresql/data

ENTRYPOINT []
CMD odk-migrate-postgres
