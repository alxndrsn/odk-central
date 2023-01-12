#!/bin/bash -eux
set -o pipefail

alreadyRunMarkerFile="$PGDATA/../.odk-postgres-9.6-to-14-upgrade-completed-ok"

logPrefix="$(basename $0)"
log() {
  echo "$(TZ=GMT date) [$logPrefix] $*"
}

log "Waiting for upgrade to complete..."
while ! [[ -f "$alreadyRunMarkerFile" ]]; do sleep 1; done
log "Upgrade complete."

log "Starting postgres..."
# call ENTRYPOINT + CMD from parent Docker image
docker-entrypoint.sh postgres
