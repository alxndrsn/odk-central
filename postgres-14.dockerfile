FROM postgres:14

COPY files/postgres-14/start-postgres.sh /usr/local/bin/

# Override the PGDATA env var in the parent Dockerfile so that the
# parent's VOLUME declaration does not create a separate VOLUME
# apparently within the pg14 volume declared in docker-compose.yml.
# FIXME looks like some important words are missing from this comment!
ENV PGDATA /var/lib/odk-postgresql/data
# TODO as per https://github.com/docker-library/postgres/blob/c3a0b48216491953f25344c3fef1b02ed157ff3e/14/bullseye/Dockerfile#L183-L186,
# we may also need:
#RUN mkdir -p "$PGDATA" && chown -R postgres:postgres "$PGDATA" && chmod 777 "$PGDATA"

ENTRYPOINT []
CMD start-postgres.sh
