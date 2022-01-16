#!/usr/bin/env bash

sudo cat /var/lib/docker/image/overlay2/repositories.json | jq .
