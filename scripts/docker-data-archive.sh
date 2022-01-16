#!/usr/bin/env bash

set -eu -o pipefail

dir_current=/var/lib/docker
dir_archived_base=/var/lib/docker.archived

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
  sudo mv "$dir_current" "$dir_archived"
  sudo systemctl start docker.service docker.socket
  echo "Docker data archived to \"$dir_archived\""
else
  echo "Keeping everything. Don't panic :) "
fi