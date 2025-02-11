#!/bin/bash -eu
set -o pipefail
shopt -s inherit_errexit

log() { echo >&2 "[$(basename "$0")] $*"; }

scriptFiles="$(cat <(git grep -El '^#!.*sh\b') <(git ls-files | grep -E '.sh$') | sort -u)"

for script in $scriptFiles; do
  log "Checking $script ..."

  log "  Checking shebang..."
  shebang="$(head -n3 "$script")"
  if ! diff <(echo "$shebang") <(printf '#!/bin/bash -eu\nset -o pipefail\nshopt -s inherit_errexit\n'); then
    log "    !!! Unexpected shebang !!!"
    exit 1
  fi
  log "    Passed OK."

  log "  Checking trailing newline..."
  if [[ -n "$(tail -c 1 < "$script")" ]]; then
    log "    !!! Missing final newline !!!"
    exit 1
  fi
  if [[ -z "$(tail -c 2 < "$script")" ]]; then
    log "    !!! Blank lines at end of file !!!"
    exit 1
  fi
  log "    Passed OK."

  log "  Checking for indirect invocations..."
  # shellcheck disable=2086
  if git grep -E "sh.*$(basename "$script")" $scriptFiles; then
    log "    !!! Indirect invocation(s) found !!!"
    exit 1
  fi
  log "    Passed OK."
done

log "Running shellcheck..."
echo "$scriptFiles" | xargs \
    shellcheck \
        --enable=all \
        --exclude=SC2016,SC2154,SC2250,SC2312 \
        "$script"
log "  Shellcheck passed OK."

log "All scripts passed OK."
