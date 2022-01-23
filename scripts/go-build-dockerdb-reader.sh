#!/usr/bin/env bash

set -eu -o pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"

(
  cd "$script_dir/../dockerdb-reader"
  go build -o "$script_dir/../var/bin/dockerdb-reader"
)