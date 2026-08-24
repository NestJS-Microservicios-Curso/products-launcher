#!/usr/bin/env bash

set -Eeuo pipefail

keyfile=/data/db/keyfile

if [[ ! -e "$keyfile" ]]; then
  umask 077
  openssl rand -base64 756 >"$keyfile"
fi

chown mongodb:mongodb "$keyfile"
chmod 0400 "$keyfile"

exec /usr/local/bin/docker-entrypoint.sh "$@"
