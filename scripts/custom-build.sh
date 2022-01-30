#!/usr/bin/env bash

set -eu -o pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
source "$script_dir/../env.sh"

function build_layer() {
  local image="$1"
  local instruction="$2"
  shift 2

  local args=("$@")

  local env
  local container_id=""
  local change=()

  ((++step))
  echo "Step $step : $instruction ${args[*]}"

  case "$instruction" in
    FROM)
      if [[ "$(docker image ls -q "${args[0]}" | wc -l)" == 0 ]]; then
        docker image pull "${args[0]}"
      fi
      image_id=$(docker image inspect "${args[0]}" --format '{{ .Id }}')
      ;;
    ARG)
      container_id=$(docker container create "$image" /bin/sh -c '#(nop)' "$instruction ${args[*]}")
      ;;
    ENV)
      env=()
      for e in "${args[@]}"; do
        env+=(-e "$e");
      done
      container_id=$(docker container create "${env[@]}" "$image" /bin/sh -c '#(nop)' "$instruction ${args[*]}")
      ;;
    CMD)
      container_id=$(docker container create "$image" /bin/sh -c '#(nop)' "$instruction ${args[*]}")
      change=(-c "$instruction ${args[*]}")
      ;;
    RUN)
      container_id=$(docker container create "$image" "${args[@]}")
      ;;
    *)
      >&2 echo "Invalid instruction: $instruction"
      return 1
      ;;
  esac

  if [[ -n "$container_id" ]]; then
    printf " ---> Running in %.12s\n" "$container_id"
  fi
  
  if [[ "$instruction" == "RUN" ]]; then
    docker container start -a "$container_id"
  fi

  if [[ -n "$container_id" ]]; then
    image_id=$(docker container commit "${change[@]}" "$container_id")
  fi
  printf ' ---> %.12s\n' "$(echo "$image_id" | cut -d: -f2)"
}

target_image_tag="$1"
target_image_name="$PROJECT_IMAGE_REPOSITORY:$target_image_tag"
image_id=""
step=0

build_layer "$image_id" FROM "ubuntu:20.04"
build_layer "$image_id" ARG app_dir=/app
build_layer "$image_id" ENV version=1.0 config_name=config.ini
build_layer "$image_id" RUN /bin/sh -c 'export app_dir=/app && mkdir $app_dir'
build_layer "$image_id" RUN /bin/sh -c 'export app_dir=/app && echo "version=$version" > "$app_dir/$config_name"'
build_layer "$image_id" RUN /bin/sh -c 'apt-get update && apt-get install nano'
build_layer "$image_id" CMD '["env"]'

printf 'Successfully built %.12s\n' "$(echo "$image_id" | cut -d: -f2)"

if [[ -n "$target_image_name" ]]; then
  docker image tag "$image_id" "$target_image_name"
  echo "Successfully tagged $target_image_name"
fi