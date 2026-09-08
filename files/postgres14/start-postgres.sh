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

  echo "=== FILE METADATA (stat) ==="
  stat "$target"
  echo

  if [ -L "$target" ]; then
    echo "=== SYMLINK ANALYSIS ==="
    echo "Type: Soft / Symbolic Link"

    local link_target
    link_target=$(readlink "$target")
    echo "Direct Target: $link_target"

    if [ -e "$target" ]; then
      echo "Status: Valid"
      echo "Canonical Absolute Path: $(readlink -f "$target")"
    else
      echo "Status: BROKEN LINK"
    fi
  else
    echo "=== HARD LINK ANALYSIS ==="
    echo "Type: Regular File / Hard Link"

    local link_count
    link_count=$(stat -c "%h" "$target")
    local inode
    inode=$(stat -c "%i" "$target")

    if [ "$link_count" -gt 1 ]; then
      echo "Warning: $link_count hard links point to inode $inode."
      echo "To find sibling hard links, run:"
      echo "  find . -samefile \"$target\""
    else
      echo "Link Count: 1 (No additional hard links exist)"
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
