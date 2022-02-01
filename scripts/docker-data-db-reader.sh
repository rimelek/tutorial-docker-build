#!/usr/bin/env bash

set -eu -o pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
source "$script_dir/../env.sh"

sudo "$script_dir/docker-db-reader.sh" "$PROJECT_DOCKER_DATA_DIR/$1"
