FROM pgautoupgrade/pgautoupgrade:17.12-trixie

COPY files/postgres14/start-postgres.sh /usr/local/bin/

ENV PGDATA=/var/lib/odk/postgresql/data

ENTRYPOINT []
CMD ["/usr/local/bin/start-postgres.sh"]
