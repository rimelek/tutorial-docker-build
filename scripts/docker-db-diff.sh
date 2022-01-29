#!/usr/bin/env bash

# https://stackoverflow.com/a/31933234/2584843

set -eu -o pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"

quiet=0

while getopts ':q' opt; do
  case "$opt" in
    q) quiet=1 ;; # don't show the actual diff, only the filenames 
    *)
      >&2 echo "Invalid flag: -$OPTARG"
      exit 1
      ;;
  esac
done
shift $((OPTIND -1))

file_a="$1"
file_b="$2"

if [[ "$quiet" == "1" ]]; then
  diff -q \
    <("$script_dir/docker-db-reader.sh" "$file_a") \
    <("$script_dir/docker-db-reader.sh" "$file_b") \
    1>/dev/null \
    || echo "Files $file_a and $file_b differ"
else
  diff \
    <("$script_dir/docker-db-reader.sh" "$file_a") \
    <("$script_dir/docker-db-reader.sh" "$file_b")
fi


# alternative solution
# jq \
#   --argjson a "$(cat a.json)" \
#   --argjson b "$(cat c.json)" \
#   -n \
#   '($a | (.. | arrays) |= sort) as $a | ($b | (.. | arrays) |= sort) as $b | $a == $b'

