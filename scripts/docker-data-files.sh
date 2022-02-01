#!/usr/bin/env bash

set -eu -o pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
source "$script_dir/../env.sh"

dir="$PROJECT_DOCKER_DATA_DIR"

sudo find "$dir" -type f -printf '%P\n'
