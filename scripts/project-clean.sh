#!/usr/bn/env

script_dir="$(cd "$(dirname "$0")" && pwd)"

find var/bin/ -type f -not -name .gitkeep -exec unlink {} \;