#!/bin/bash -eu
set -o pipefail

{ echo "versions:"; echo "$(git rev-parse HEAD) ($(git describe --tags))"; git submodule; } > /tmp/version.txt
