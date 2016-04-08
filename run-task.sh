#!/bin/sh
set -e

echo "[builder] Running task MIX_ENV=prod $@"
cd /root/app
export MIX_ENV=prod
exec "$@"

