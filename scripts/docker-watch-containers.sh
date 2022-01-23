#!/usr/bin/env bash

set -eu -o pipefail

watch --interval 1 --no-title \
  "docker container ls \
    --all \
    --no-trunc \
    --format 'table {{ printf \"%.12s\" .ID }}\t{{ .State }}\t{{ .Command }}'"
