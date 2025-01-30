#!/bin/bash -eu
set -o pipefail

log() { echo >&2 "[$(basename "$0")] $*"; }

tmp="$(mktemp)"

check_path() {
  local retries="$1"
  local requestPath="$2"
  local expected="$3"

  for (( i=0; ; ++i )); do
    log "Checking response from $requestPath..."
    echo -e "GET $requestPath HTTP/1.0\r\nHost: local\r\n\r\n" |
        docker compose exec --no-TTY nginx \
            openssl s_client -quiet -connect 127.0.0.1:443 \
        >"$tmp" 2>&1 || true
    if grep --silent --fixed-strings "$expected" "$tmp"; then
      log "  Request responded correctly."
      return
    fi

    if [[ "$i" -lt "$retries" ]]; then
      log "  Request did not respond correctly; sleeping..."
      sleep 1
    else
      log "!!! Retry count exceeded."
      log "!!! Final response:"
      echo
      cat "$tmp"
      echo

      exit 1
    fi
  done
}

echo 'SSL_TYPE=selfsign
DOMAIN=local
SYSADMIN_EMAIL=no-reply@getodk.org' > .env

touch ./files/allow-postgres14-upgrade

log "Building docker containers..."
#docker compose build

log "Starting containers..."
#docker compose up --detach

# we allow a long retry period for the first check because the first-run
# nginx setup could take several minutes due to key generation.
log "Verifying frontend and backend load..."
check_path 30 / 'ODK Central'
check_path 20 /v1/projects '[]'

log "Verifying pm2..."
processCount="$(
    docker compose exec service npx pm2 list \
    | tee /dev/stdout \
    | grep --count online
)"

if [[ "$processCount" != 4 ]]; then
  log "!!! PM2 returned an unexpected count for online processes."
  log "!!!"
  log "!!! Expected 4, but got $processCount."

  exit 1
fi

log "All OK."
