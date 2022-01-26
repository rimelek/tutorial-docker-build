#!/usr/bin/env bash

set -eu -o pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
source "$script_dir/env.sh"
[[ -f "$script_dir/env.custom.sh" ]] && source "$script_dir/env.custom.sh"

dir_target_base="$script_dir/../var/dockerdb-tmp"

file_src=$1

if [[ ! -f "$file_src" ]]; then
  >&2 echo "File not found: $file_src"
  exit 1
fi

file_src_abs_path="$(cd "$(dirname "$file_src")" && pwd)/$(basename "$file_src")"
file_target_abs_path="${dir_target_base}${file_src_abs_path}"

file_target_abs_dir="$(dirname "$file_target_abs_path")"

mkdir -p "$file_target_abs_dir"

sudo cp "$file_src_abs_path" "$file_target_abs_path"

"$script_dir/../var/bin/dockerdb-reader" "$file_target_abs_path"