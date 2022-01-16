#!/usr/bin/env bash

set -eu -o pipefail

dir=/var/lib/docker

echo -n "Are you sure you want to destroy \"$dir\"? [y/N] "
read confirm

if [[ "$confirm" == "y" ]]; then
  echo "Destroying \"$dir\" ..."
  sudo systemctl stop docker.service docker.socket
  sudo rm -rf "$dir"
  sudo systemctl start docker.service docker.socket
  echo "Docker data destroyed"
else
  echo "Keeping everything. Don't panic :) "
fi