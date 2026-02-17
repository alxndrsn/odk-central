#!/bin/bash -eu
set -o pipefail
shopt -s inherit_errexit

log() { echo >&2 "[$(basename "$0")] $*"; }

docker_compose() {
  docker compose --file nginx.test.docker-compose.yml "$@"
}

lint_service() {
  local service="$1"
  log "$service: checking config..."
  docker_compose exec "$service" bash -euc '
    cat >.semgrep.yml <<EOF
rules:
  - id: nginx-add-header-missing-always
    languages: [generic]
    message: "Security headers should include \`always\` param to ensure they are sent with error responses (4xx, 5xx)."
    severity: ERROR
    patterns:
      - pattern-regex: "\\\\badd_header\\\\s+(Strict-Transport-Security|X-Content-Type-Options|X-Frame-Options|Content-Security-Policy|Content-Security-Policy-Report-Only)\\\\s+.*"
      - pattern-not-regex: "(?i)add_header\\\\s+.*\\\\balways\\\\b\\\\s*;"
EOF

    echo "----- .semgrep.yml -----"
    cat .semgrep.yml
    echo "------------------------"
    echo
    echo "----- /etc/nginx/conf.d/odk.conf -----"
    #cat /etc/nginx/conf.d/odk.conf
    echo "------------------------"

    apt-get update
    apt-get install -y python3-venv
    python3 -m venv .venv
    . .venv/bin/activate
    pip install semgrep
    semgrep scan --verbose \
                 --metrics=off \
                 --disable-version-check \
                 --no-git-ignore \
                 --config p/nginx \
                 --config .semgrep.yml \
                 -- \
                 /etc/nginx/conf.d/odk.conf #\
                 #/usr/share/odk/nginx/
  '

  log "$service: config looks OK."
}

lint_service nginx-ssl-selfsign
#lint_service nginx-ssl-upstream

log "Completed OK."
