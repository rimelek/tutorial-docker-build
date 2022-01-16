#!/usr/bin/env bash

set -eu -o pipefail

version=$1

DOCKER_BUILDKIT=0 \
  docker image build . \
    -t localhost/buildtest:$version \
    -f Dockerfile.$version \
     --rm=false \
     --no-cache