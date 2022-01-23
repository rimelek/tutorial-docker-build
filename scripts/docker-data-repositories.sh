#!/usr/bin/env bash

set -eu -o pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
source "$script_dir/env.sh"
[[ -f "$script_dir/env.custom.sh" ]] && source "$script_dir/env.custom.sh"

sudo cat "$PROJECT_DOCKER_DATA_DIR/image/overlay2/repositories.json" | jq .
