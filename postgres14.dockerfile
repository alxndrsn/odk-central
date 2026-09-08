FROM pgautoupgrade/pgautoupgrade:18.4-trixie

COPY files/postgres14/start-postgres.sh /usr/local/bin/

ENTRYPOINT []
CMD ["start-postgres.sh"]
