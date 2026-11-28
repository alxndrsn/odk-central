#!/bin/bash -eu
set -o pipefail
shopt -s inherit_errexit

flag_upgradedOk_data="/var/lib/odk/postgresql/.postgres14-upgrade-successful"
flag_upgradedOk_host="/postgres14-upgrade/upgrade-successful"

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

if  ! [[ -f "$flag_upgradedOk_data" ]] &&
    ! [[ -f "$flag_upgradedOk_host" ]]; then
  log "Waiting for upgrade to v14 to complete..."
  while ! [[ -f "$flag_upgradedOk_data" ]] &&
        ! [[ -f "$flag_upgradedOk_host" ]]; do sleep 1; done
  log "Upgrade to v14 complete."
fi

# If a previous run of postgres had a messy shutdown, it may have left a stale
# PID file.  Remove here to prevent pgautoupgrade stalling.
# See: https://github.com/pgautoupgrade/docker-pgautoupgrade/issues/304
rm -f "$PGDATA/postmaster.pid"

log "Starting postgres..."
# call ENTRYPOINT + CMD from parent Docker image
exec /usr/local/bin/docker-entrypoint.sh postgres "$@"
