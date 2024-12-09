#!/bin/bash -eu

log() { echo >&2 "[test/envsub] $*"; }


failed=0

log "should correctly substitute provided values"
if diff <( \
  SIMPLE=sv_simple \
  SUBVAL_1=sub_val_one \
  SUBVAL_2=sub_val_two \
  ../../files/shared/envsub.sh \
< good-example.in
) good-example.expected; then
  log "  OK"
else
  failed=1
  log "  FAILED"
fi

log "should fail when asked to substitute undefined value"
if ! ../../files/shared/envsub.sh <<<'${NOT_DEFINED}'; then
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
