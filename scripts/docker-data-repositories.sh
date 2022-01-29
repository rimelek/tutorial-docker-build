#!/usr/bin/env bash

set -eu -o pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"

"$script_dir/docker-data-cat.sh" "image/overlay2/repositories.json" | jq .
