#!/usr/bin/env bash

set -eu -o pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
source "$script_dir/../env.sh"

if [[ "$PROJECT_STORAGE_DRIVER" != "overlay2" ]]; then
  >&2 echo "Invalid storage driver: $PROJECT_STORAGE_DRIVER"
  >&2 echo "Supported storage drivers: overlay2"
fi

# Global settings

docker_root_dir="$PROJECT_DOCKER_DATA_DIR"
storage_driver="$PROJECT_STORAGE_DRIVER"
imagedb_content_dst_dir="$docker_root_dir/image/$storage_driver/imagedb/content/sha256"
imagedb_metadata_dst_dir="$docker_root_dir/image/$storage_driver/imagedb/metadata/sha256"
repositories_path="$docker_root_dir/image/$storage_driver/repositories.json"

# Image Layer settings
meta_path_src="meta.json"
meta_json_compact="$(jq -c . "$meta_path_src")"
image_id="$(echo "$meta_json_compact" | sha256sum | cut -d " " -f 1)"
last_updated_dst_dir="$imagedb_metadata_dst_dir/$image_id"

# Image layer creation
echo "$meta_json_compact" | sudo tee >/dev/null "$imagedb_content_dst_dir/$image_id"
sudo mkdir -p "$last_updated_dst_dir"
date +%Y-%m-%dT%H:%M:%S.%N%:z | tr -d '\n' | sudo tee >/dev/null "$last_updated_dst_dir/lastUpdated"

# Add a tag to the layer
repository="$PROJECT_IMAGE_REPOSITORY"
tag="$1"

jq -c \
   --arg repository "$repository" \
   --arg tag "$tag" \
   --arg image_id "$image_id" \
   '. * {
          "Repositories": {
            ($repository): {
              ($repository + ":" + $tag): ("sha256:" + $image_id)
            }
          }
        }' \
  < <(sudo cat "$repositories_path") | sudo tee >/dev/null "$repositories_path.tmp"

sudo mv "$repositories_path.tmp" "$repositories_path"

echo "Docker image created from scratch: $repository:$tag"
echo "Please, restart Docker manually to load the new image meta files."
echo "Example: systemctl restart docker"
