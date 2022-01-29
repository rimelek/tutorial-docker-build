#!/usr/bin/env bash

set -eu -o pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
source "$script_dir/env.sh"
[[ -f "$script_dir/env.custom.sh" ]] && source "$script_dir/env.custom.sh"

force_trailing_linebreak=0

while getopts ':l' opt; do
  case "$opt" in
    l)
      force_trailing_linebreak=1
      shift
      ;;
    *)
      >&2 echo "Invalid flag: -$OPTARG"
      exit 1
      ;;
  esac
done

file_src="$PROJECT_DOCKER_DATA_DIR/$1"

function data_cat () { sudo cat "$file_src"; }

if [[ "$force_trailing_linebreak" == "0" ]]; then
  data_cat
else
  # shellcheck disable=SC2005
  echo "$(data_cat)"
fi