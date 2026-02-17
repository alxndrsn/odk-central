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
    # TODO generate .semgrep.yml with a heredoc
    cat >.semgrep.yml <<EOF
rules:
  - id: nginx-add-header-missing-always
    languages: [nginx]
    message: "Security headers should include the 'always' parameter to ensure they are sent on error pages (4xx, 5xx)."
    severity: WARNING
    patterns:
      - pattern: add_header $HEADER $VALUE;
      - metavariable-regex:
          metavariable: $HEADER
          regex: ^(Strict-Transport-Security|X-Content-Type-Options|X-Frame-Options)$
      - pattern-not: add_header $HEADER $VALUE always;
EOF

    apt update
    apt install -y python3-venv
    python3 -m venv .venv
    . .venv/bin/activate
    pip install semgrep
    semgrep scan --metrics=off --disable-version-check --no-git-ignore --config .semgrep.yml
  '

  log "$service: config looks OK."
}

lint_service nginx-ssl-selfsign
lint_service nginx-ssl-upstream

log "Completed OK."
