#!/bin/bash -eu
set -o pipefail

log() { echo >&2 "[$(basename "$0")] $*"; }

scriptFiles="$(cat <(git grep -El '^#!.*sh\b') <(git ls-files | grep -E '.sh$') | sort -u)"

for script in $scriptFiles; do
  log "Checking $script ..."

  log "  Checking shebang..."
  shebang="$(head -n2 "$script")"
  if ! diff <(echo "$shebang") <(printf '#!/bin/bash -eu\nset -o pipefail\n'); then
    log "    !!! Unexpected shebang !!!"
    exit 1
  fi
  log "    passed OK."

  log "  Checking trailing newline..."
  if [[ -n "$(tail -c 1 < "$script")" ]]; then
    log "    !!! Missing final newline !!!"
    exit 1
  fi
  if [[ -z "$(tail -c 2 < "$script")" ]]; then
    log "    !!! Blank lines at end of file !!!"
    exit 1
  fi
  log "    passed OK."

  log "  Running shellcheck..."
  shellcheck --exclude=SC2016 "$script"
  log "    passed OK."
done
