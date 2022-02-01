#!/usr/bin/env bash

script_dir="$(cd "$(dirname "$0")" && pwd)"

find "$script_dir/../var/bin/" -type f -not -name .gitkeep -exec unlink {} \;
unlink "$script_dir/../env.custom.sh"
