#!/bin/bash -eu
set -o pipefail
shopt -s inherit_errexit

flag_upgradeCompletedOk_1="$PGDATA/../.postgres14-upgrade-successful"
flag_upgradeCompletedOk_2="$PGDATA/.postgres14-upgrade-successful"
flag_upgradeCompletedOk_3="/postgres14-upgrade/upgrade-successful"

logPrefix="$(basename "$0")"
log() {
  echo "$(TZ=GMT date) [$logPrefix] $*"
}

log "Checking for flag file at '$flag_upgradeCompletedOk_1' or '$flag_upgradeCompletedOk_2' ..."
if ! [[ -f "$flag_upgradeCompletedOk_1" ]] &&
   ! [[ -f "$flag_upgradeCompletedOk_2" ]] &&
   ! [[ -f "$flag_upgradeCompletedOk_3" ]]; then
  log "Waiting for upgrade to v14 to complete..."
  while ! [[ -f "$flag_upgradeCompletedOk_1" ]]; do sleep 1; done
  touch "$flag_upgradeCompletedOk_2"
  log "Upgrade to v14 complete."
fi

log "Starting postgres..."
# call ENTRYPOINT + CMD from parent Docker image
exec /usr/local/bin/docker-entrypoint.sh postgres "$@"
