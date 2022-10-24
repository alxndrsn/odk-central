FROM tianon/postgres-upgrade:9.6-to-14

ENTRYPOINT /bin/sh
COPY files/postgres/odk-start-postgres /usr/local/bin/
CMD odk-start-postgres
