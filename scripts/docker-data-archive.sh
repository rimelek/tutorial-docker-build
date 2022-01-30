#!/usr/bin/env bash

set -eu -o pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
source "$script_dir/../env.sh"
[[ -f "$script_dir/../env.custom.sh" ]] && source "$script_dir/../env.custom.sh"

dir_current="$PROJECT_DOCKER_DATA_DIR"
dir_archived_base="$PROJECT_DOCKER_DATA_DIR_ARCHIVED_BASE"

function dir_archived() {
  dir_archived=""
  i=1
  while true; do
    dir_archived="$dir_archived_base.$i"
    if ! sudo stat "$dir_archived" &>/dev/null; then
      echo "$dir_archived"
      return 0
    fi
    (( ++i ))
  done
}

echo -n "Are you sure you want to archive \"$dir_current\"? [y/N] "
read confirm

if [[ "$confirm" == "y" ]]; then
  echo "Archiving \"$dir_current\" ..."
  dir_archived="$(dir_archived)"
  sudo systemctl stop docker.service docker.socket
  sudo cp -ax "$dir_current" "$dir_archived"
  sudo systemctl start docker.service docker.socket
  echo "Docker data archived to \"$dir_archived\""
else
  echo "Keeping everything. Don't panic :) "
fi