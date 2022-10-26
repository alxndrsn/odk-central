FROM postgres:14

COPY files/postgres-14/odk-start-postgres /usr/local/bin/

ENTRYPOINT []
CMD odk-start-postgres
