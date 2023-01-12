FROM postgres:14

COPY files/postgres-14/start-postgres.sh /usr/local/bin/

# PGDATA is originally declared in the parent Dockerfile, but points
# to an anonymous VOLUME declaration in the same file:
#
#   ENV PGDATA /var/lib/postgresql/data
#   ...
#   VOLUME /var/lib/postgresql/data
#
# To ensure future accessibility, we must make sure that our PGDATA is
# stored _outside_ this anonymous volume.
ENV PGDATA /var/lib/odk-postgresql/data
# TODO as per https://github.com/docker-library/postgres/blob/c3a0b48216491953f25344c3fef1b02ed157ff3e/14/bullseye/Dockerfile#L183-L186,
# we may also need:
#RUN mkdir -p "$PGDATA" && chown -R postgres:postgres "$PGDATA" && chmod 777 "$PGDATA"

ENTRYPOINT []
CMD start-postgres.sh
