#!/usr/bin/env bash

set -eu -o pipefail 

script_dir="$(cd "$(dirname "$0")" && pwd)"
source "$script_dir/../env.sh"

dir_current="$PROJECT_DOCKER_DATA_DIR"
dir_archived_base="$PROJECT_DOCKER_DATA_DIR_ARCHIVED_BASE"

version_1="$1"
version_2=""

if (( $# > 1 )); then
  version_2="$2"
else
  version_2="$version_1"
  version_1="0"
fi

dir_1="$dir_archived_base.$version_1"
if [[ "$version_1" == "0" ]]; then
  dir_1="$dir_current"
fi

dir_2="$dir_archived_base.$version_2"

function db_files_rel() {
  echo "volumes/metadata.db"
  echo "network/files/local-kv.db"
  echo "buildkit/snapshots.db"
  echo "buildkit/containerdmeta.db"
  echo "buildkit/cache.db"
  echo -n "buildkit/metadata_v2.db"
}

function db_files_pattern() {
  local dir
  # shellcheck disable=SC2001
  dir="$(echo "$1" | sed 's#/*$##')/"
  
  db_files_rel \
    | sed "s#^#$dir#" \
    | sed 's/\./\\./g' \
    | tr $'\n' '|' \
    | sed 's/|/\\|/g'
}

sudo diff --no-dereference -rq "$dir_1" "$dir_2" 2>/dev/stdout \
  | grep -E -v 'block special file|character special file' \
  | grep -v "$(db_files_pattern "$dir_1")" \
  || true

# diff the actual content of the databases as json, not the binaries
db_files_rel | xargs --replace='{}' -- "$script_dir/docker-db-diff.sh" -q "$dir_1/{}" "$dir_2/{}"  

