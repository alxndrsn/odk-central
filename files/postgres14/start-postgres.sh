#!/bin/bash -eu
set -o pipefail
shopt -s inherit_errexit

flag_upgradeCompletedOk="/postgres14-upgrade/upgrade-successful"

logPrefix="$(date +%s%N)|$(basename "$0")"
log() {
  echo "$(TZ=GMT date) [$logPrefix] $*"
}

log "--- debugging tree ---"
tree
log "--- tree completed ---"

if ! [[ -f "$flag_upgradeCompletedOk" ]] &&
   ! [[ -f "$PGDATA/../.postgres14-upgrade-successful" ]]; then
  log "Waiting for upgrade to v14 to complete..."
  while ! [[ -f "$flag_upgradeCompletedOk" ]]; do sleep 1; done
  log "Upgrade to v14 complete."
fi

log "Starting postgres..."
# call ENTRYPOINT + CMD from parent Docker image
exec /usr/local/bin/docker-entrypoint.sh postgres "$@"
