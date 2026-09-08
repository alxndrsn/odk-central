#!/bin/bash -eu
set -o pipefail
shopt -s inherit_errexit

flag_upgradeCompletedOk="/postgres14-upgrade/upgrade-successful"

logPrefix="$(basename "$0")"
log() {
  echo "$(TZ=GMT date) [$logPrefix] $*"
}

log "Checking for flag file(s)..."
if ! [[ -f "$flag_upgradeCompletedOk" ]] &&
   ! [[ -f "$PGDATA/../.postgres14-upgrade-successful" ]]; then
  log "Waiting for upgrade to v14 to complete..."
  while ! [[ -f "$flag_upgradeCompletedOk" ]]; do
    log "  Flag file not yet present; sleeping..."
    sleep 1
  done
  log "Upgrade to v14 complete."
fi

ls_dir() {
  dir="$1"
  log "--------- $dir -----------"
  ls -al "$dir" || true
  log "--------------------------"

  log "=== FILE METADATA (stat) ==="
  stat "$dir" || true
  log

  if [ -L "$dir" ]; then
    log "=== SYMLINK ANALYSIS ==="
    log "Type: Soft / Symbolic Link"

    local link_target
    link_dir=$(readlink "$dir")
    log "Direct Target: $link_target"

    if [ -e "$dir" ]; then
      log "Status: Valid"
      log "Canonical Absolute Path: $(readlink -f "$dir")"
    else
      log "Status: BROKEN LINK"
    fi
  else
    log "=== HARD LINK ANALYSIS ==="
    log "Type: Regular File / Hard Link"

    local link_count
    link_count=$(stat -c "%h" "$dir")
    local inode
    inode=$(stat -c "%i" "$dir")

    if [ "$link_count" -gt 1 ]; then
      log "Warning: $link_count hard links point to inode $inode."
      log "To find sibling hard links, run:"
      log "  find . -samefile \"$dir\""
    else
      log "Link Count: 1 (No additional hard links exist)"
    fi
  fi
}
ls_dir "$PGDATA"
ls_dir "/var/lib/postgresql"
ls_dir "/var/lib/postgresql/data"
ls_dir "/var/lib/postgresql/18"
ls_dir "/var/lib/postgresql/18/docker"

log "Starting postgres..."
# call ENTRYPOINT + CMD from parent Docker image
exec /usr/local/bin/docker-entrypoint.sh postgres "$@"
