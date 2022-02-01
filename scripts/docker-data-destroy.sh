#!/usr/bin/env bash

set -eu -o pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
source "$script_dir/../env.sh"

dir="$PROJECT_DOCKER_DATA_DIR"

echo -n "Are you sure you want to destroy \"$dir\"? [y/N] "
read confirm

if [[ "$confirm" == "y" ]]; then
  echo "Stopping Docker daemon: sudo systemctl stop docker.service docker.socket"
  sudo systemctl stop docker.service docker.socket
  echo "Destroying \"$dir\" ..."
  sudo rm -rf "$dir"
  echo "Starting Docker daemon"
  sudo systemctl start docker.service docker.socket
  echo "Docker data destroyed"
else
  echo "Keeping everything. Don't panic :) "
fi
