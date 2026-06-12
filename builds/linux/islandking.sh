#!/bin/sh
printf '\033c\033]0;%s\a' Island King
base_path="$(dirname "$(realpath "$0")")"
"$base_path/islandking.x86_64" "$@"
