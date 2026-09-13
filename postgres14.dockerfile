FROM pgautoupgrade/pgautoupgrade:17.11-trixie

COPY files/postgres14/start-postgres.sh /usr/local/bin/

ENV PGDATA=/var/lib/postgresql/data

ENTRYPOINT []
CMD ["start-postgres.sh"]
