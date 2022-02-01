#!/usr/bin/env bash

set -eu -o pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
source "$script_dir/../env.sh"

version="$1"

dir_current="$PROJECT_DOCKER_DATA_DIR"
dir_archived_base="$PROJECT_DOCKER_DATA_DIR_ARCHIVED_BASE"
dir_archived="$dir_archived_base.$version"

echo -n "Are you sure you want to delete \"$dir_current\" and restore \"$dir_archived\"? [y/N] "
read -r confirm

if [[ "$confirm" == "y" ]]; then
  echo "Stopping docker daemon: sudo systemctl stop docker.service docker.socket"
  sudo systemctl stop docker.service docker.socket
  echo "Removing \"$dir_current\" ..."
  sudo rm -rf "$dir_current"
  echo "Copying \"$dir_archived\" to \"$dir_current\""
  sudo cp -ax "$dir_archived" "$dir_current"
  echo "Starting docker daemon: sudo systemctl start docker.service docker.socket"
  sudo systemctl start docker.service docker.socket
  echo "Docker data restored from \"$dir_archived\""
else
  echo "Keeping everything. Don't panic :) "
fi
