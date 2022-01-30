#!/usr/bin/env bash

set -eu -o pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
source "$script_dir/../env.sh"

version=$1

DOCKER_BUILDKIT=0 \
  docker image build . \
    -t "$PROJECT_IMAGE_REPOSITORY:$version" \
    -f "$version.Dockerfile" \
     --rm=false \
     --no-cache