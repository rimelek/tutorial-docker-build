#!/usr/bin/env bash

dir="/var/lib/docker"

sudo find "$dir" -type f -printf '%P\n'