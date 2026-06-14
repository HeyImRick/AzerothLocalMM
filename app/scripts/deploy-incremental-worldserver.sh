#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
readonly PROJECT_ROOT=$(cd -- "$SCRIPT_DIR/../.." && pwd)
readonly SERVER_DIR="$PROJECT_ROOT/source/azerothcore"
readonly BINARY="$PROJECT_ROOT/var/dist/bin/worldserver"

test -x "$BINARY"

docker compose \
    --project-directory "$SERVER_DIR" \
    --project-name azeroth-local \
    up --no-build --no-deps --detach --force-recreate ac-worldserver

printf 'Worldserver recriado com o binario incremental.\n'
