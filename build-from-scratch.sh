#!/usr/bin/env bash

set -eu -o pipefail

# Global settings

docker_root_dir=/var/lib/docker
storage_driver=overlay2
imagedb_content_dst_dir="$docker_root_dir/image/$storage_driver/imagedb/content/sha256"
imagedb_metadata_dst_dir="$docker_root_dir/image/$storage_driver/imagedb/metadata/sha256"
repositories_path="$docker_root_dir/image/$storage_driver/repositories.json"

# Image Layer settings
meta_path_src="meta.json"
meta_json_compact="$(jq -c . "$meta_path_src")"
image_id="$(echo "$meta_json_compact" | sha256sum | cut -d " " -f 1)"
last_updated_dst_dir="$imagedb_metadata_dst_dir/$image_id"

# Image layer creation
echo "$meta_json_compact" > "$imagedb_content_dst_dir/$image_id"
mkdir -p "$last_updated_dst_dir"
date +%Y-%m-%dT%H:%M:%S.%N%:z | tr -d '\n' > "$last_updated_dst_dir/lastUpdated"

# Add a tag to the layer
repository="localhost/buildtest"
tag="v7"

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
  < "$repositories_path" > "$repositories_path.tmp"

mv "$repositories_path.tmp" "$repositories_path"
