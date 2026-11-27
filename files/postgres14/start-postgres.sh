#!/bin/bash -eu
set -o pipefail
shopt -s inherit_errexit

flag_upgradeCompletedOk="$PGDATA/../.postgres14-upgrade-successful"

logPrefix="$(date +%s%N)|$(basename "$0")"
log() {
  echo "$(TZ=GMT date) [$logPrefix] $*"
}

pgUpgradeFailureLogs="$PGDATA/new/pg_upgrade_output.d"
if [[ -d "$pgUpgradeFailureLogs" ]]; then
  lineCount=50
  log "A previous upgrade did not complete; tailing the last $lineCount lines of each log file:"
  find "$pgUpgradeFailureLogs" \
      -type f \
      \( -name \*.log -o -name \*.txt \) \
      -exec tail --verbose --lines "$lineCount" {} +
  log "==> End of previous upgrade logs. <=="
fi

if ! [[ -f "$flag_upgradeCompletedOk" ]]; then
  log "Waiting for upgrade to v14 to complete..."
  while ! [[ -f "$flag_upgradeCompletedOk" ]]; do sleep 1; done
  log "Upgrade to v14 complete."
fi

log "Starting postgres..."
# call ENTRYPOINT + CMD from parent Docker image
exec /usr/local/bin/docker-entrypoint.sh postgres "$@"
