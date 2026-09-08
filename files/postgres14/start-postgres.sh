#!/bin/bash -eu
set -o pipefail
shopt -s inherit_errexit

flag_upgradeCompletedOk="/postgres14-upgrade/upgrade-successful"

logPrefix="$(basename "$0")"
log() {
  echo "$(TZ=GMT date) [$logPrefix] $*"
}

log "Checking free space..."
df -h "$PGDATA"

log "Checking inodes..."
df -i "$PGDATA"

log "Checking for flag file(s)..."
if ! [[ -f "$flag_upgradeCompletedOk" ]] &&
   ! [[ -f "$PGDATANEW/../.postgres14-upgrade-successful" ]]; then
  log "Waiting for upgrade to v14 to complete..."
  while ! [[ -f "$flag_upgradeCompletedOk" ]]; do sleep 1; done
  log "Upgrade to v14 complete."
fi

log "Debugging PGDATA directory..."
ls -al "$PGDATA" || true

log "Starting postgres..."
# call ENTRYPOINT + CMD from parent Docker image
exec /usr/local/bin/docker-entrypoint.sh postgres "$@"
