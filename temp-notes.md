# Notes

* pg_upgrade requires _both versions_ of postgres to be available
* dump-and-restore requires dump from version A, restore into version B

# Queries

* is db filesystem in host?  if not... could we run the update _inside the postgres container?_
  - could we make it available every time, but skip if data files are already updated to new version?  e.g. change the data directory, and then check if the new directory is empty, run the migrator

# With pg_upgrade

1. stop postgres docker container, and maybe all other docker services
2. run pg_upgrade via https://github.com/tianon/docker-postgres-upgrade
3. update repo (docker-compose.yml will now point to postgres:14)
  - does it matter when this step is run?
