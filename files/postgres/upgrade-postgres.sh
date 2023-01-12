#!/bin/bash -eu
set -o pipefail

alreadyRunMarkerFile="$PGDATANEW/../.odk-postgres-9.6-to-14-upgrade-completed-ok"
deleteOldDataMarkerFileName="delete-old-postgres9.6-data-on-next-restart"
deleteOldDataMarkerFile="/postgres-upgrade-logs/$deleteOldDataMarkerFileName"
deleteOldDataMarkerFileForUsers="./postgres-upgrade-logs/$deleteOldDataMarkerFileName"

logPrefix="$(basename "$0")"
log() {
  echo "$(TZ=GMT date) [$logPrefix] $*"
}

log "Checking for existing upgrade marker file..."
if [[ -f "$alreadyRunMarkerFile" ]]; then
  log "Upgrade has been run previously."

  if [[ -f "$deleteOldDataMarkerFile" ]]; then
    log "Deleting legacy data..."
    rm "$deleteOldDataMarkerFile"
    ./delete_old_cluster.sh
    rm ./delete_old_cluster.sh
    log "Legacy data deleted."
  elif [[ -f "$PGDATAOLD/PG_VERSION" ]]; then
    log "!!!"
    log "!!! WARNING: it looks like you still have leftover data from PostgreSQL 9.6."
    log "!!!"
    log "!!! This is taking up disk space: $(du -hs "$PGDATAOLD" 2>/dev/null | cut -f1)B"
    log "!!!"
    log "!!! If you would like to remove this data, please create file: $deleteOldDataMarkerFileForUsers"
    log "!!!"
  fi
else
  if [[ -f "$deleteOldDataMarkerFile" ]]; then
    log "!!!"
    log "!!! ERROR: Deletion request file created, but upgrade has not yet run!"
    log "!!!"
    log "!!! Please remove file and restart container to continue: $deleteOldDataMarkerFileForUsers"
    log "!!!"
    exit 1
  fi

  if ! [[ -f "$PGDATAOLD/PG_VERSION" ]]; then
    log "No legacy data found."
  elif [[ -f "$PGDATANEW/PG_VERSION" ]]; then
    log "!!!"
    log "!!! ERROR: New data found, but upgrade not flagged as complete."
    log "!!!"
    log "!!! PLEASE REPORT TO ODK TEAM AND ASK FOR ASSISTANCE AT https://forum.getodk.org/c/support"
    log "!!!"
    exit 1
  else (
    log "Upgrade not run previously; upgrading now..."

    log "From: $PGDATAOLD"
    log "  To: $PGDATANEW"

    # standard ENTRYPOINT/CMD combo from parent Dockerfile
    if ! docker-upgrade pg_upgrade; then
      log "!!!"
      log "!!! pg_upgrade FAILED; dumping log files..."
      log "!!!"
      ls -halt # FIXME this line for debug only
      df -h # FIXME this line for debug only
      tail -n+1 pg_upgrade_*.log || log "No pg_upgrade log files found ¯\_(ツ)_/¯"
      log "!!!"
      log "!!! pg_upgrade FAILED; check above for clues."
      log "!!!"
      exit 1
    fi

    # see https://github.com/tianon/docker-postgres-upgrade/issues/16,
    #     https://github.com/tianon/docker-postgres-upgrade/issues/1
    cp "$PGDATAOLD/pg_hba.conf" "$PGDATANEW/pg_hba.conf"

    log "Starting postgres server for maintenance..."
    gosu postgres pg_ctl -D "$PGDATANEW" -l logfile start

    # As recommended by pg_upgrade:
    log "Updating extensions..."
    psql -f update_extensions.sql

    # As recommended by pg_upgrade:
    log "Regenerating optimizer statistics..."
    /usr/lib/postgresql/14/bin/vacuumdb --all --analyze-in-stages

    log "Stopping postgres server..."
    gosu postgres pg_ctl -D "$PGDATANEW" -m smart stop

    # pg_upgrade recommends running ./delete_old_cluster.sh, which
    # just runs `rm -rf '/var/lib/postgresql/data'`.  Doing this here
    # can fail with "Device or resource busy".  In addition, deleting
    # the old data may be risky if the upgrade didn't complete
    # perfectly.  We can hedge our bets and make life easier by
    # skipping cleanup here, and providing a docker command to prune
    # the old, unused volume in the next odk-central version.

    log "Upgrade complete."
  ) > >(tee --append "/postgres-upgrade-logs/upgrade-postgres-9.6-14.log" >&2) 2>&1
  fi
  touch "$alreadyRunMarkerFile"
  touch "/postgres-upgrade-logs/upgrade-postgres-9.6-14.completed.ok"
fi

log "Shutting down."
