#!/bin/bash -eu
set -o pipefail
shopt -s inherit_errexit

flag_upgradeCompletedOk="$PGDATA/../.postgres14-upgrade-successful"

logPrefix="$(basename "$0")"
log() {
  echo "$(TZ=GMT date) [$logPrefix] $*"
}

log "Checking for flag file at '$flag_upgradeCompletedOk' ..."
if ! [[ -f "$flag_upgradeCompletedOk" ]]; then
  log "Waiting for upgrade to complete..."
  while ! [[ -f "$flag_upgradeCompletedOk" ]]; do sleep 1; done
  log "Upgrade complete."
fi

log "Starting postgres..."
# call ENTRYPOINT + CMD from parent Docker image
exec /usr/local/bin/docker-entrypoint.sh postgres "$@"
