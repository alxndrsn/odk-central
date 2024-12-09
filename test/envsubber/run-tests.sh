#!/bin/bash -eu

log() { echo >&2 "[test/envsubber] $*"; }


failed=0

log "should correctly substitute provided values"
if diff <( \
  SIMPLE=sv_simple \
  SUBVAL_1=sub_val_one \
  SUBVAL_2=sub_val_two \
  ../../files/nginx/envsubber \
< good-example.in
) good-example.expected; then
  log "  OK"
else
  failed=1
  log "  FAILED"
fi

log "should fail when asked to substitute undefined value"
if ! ../../files/nginx/envsubber <<<'${NOT_DEFINED}'; then
  log "  OK"
else
  failed=1
  log "  FAILED"
fi

if [[ "$failed" = 0 ]]; then
  log "All tests passed OK."
else
  log "TEST(S) FAILED"
  exit 1
fi
