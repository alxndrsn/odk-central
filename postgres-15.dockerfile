FROM postgres:15

COPY files/postgres-15/odk-start-postgres /usr/local/bin/

# Override the PGDATA env var in the parent Dockerfile so that the
# parent's VOLUME declaration does not create a separate VOLUME
# apparently within the pg15 volume declared in docker-compose.yml.
ENV PGDATA /var/lib/odk-postgresql/data
# TODO as per https://github.com/docker-library/postgres/blob/c3a0b48216491953f25344c3fef1b02ed157ff3e/15/bullseye/Dockerfile#L183-L186,
# we may also need:
#RUN mkdir -p "$PGDATA" && chown -R postgres:postgres "$PGDATA" && chmod 777 "$PGDATA"

ENTRYPOINT []
CMD odk-start-postgres
