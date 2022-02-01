#!/usr/bin/env bash

set -eu -o pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
source "$script_dir/../env.sh"

dir_archived_base="$PROJECT_DOCKER_DATA_DIR_ARCHIVED_BASE"

echo -n "Are you sure you want delete every archived folder? \"$dir_archived_base.*\"? [y/N] "
read confirm

if [[ "$confirm" == "y" ]]; then
  echo "Listing current archives \"$dir_archived_base.\"* ..."
  ret=0
  sudo ls -ld "$dir_archived_base."* 2>/dev/null || ret=$?
  if [[ "$ret" == "0" ]]; then
    echo
    echo "Deleting $dir_archived_base.*"
    sudo rm -rf "$dir_archived_base."*
    echo "All of the archived folders have been deleted."
  else 
    echo "There was no archived folder to delete"
  fi
else
  echo "Keeping everything. Don't panic :) "
fi
