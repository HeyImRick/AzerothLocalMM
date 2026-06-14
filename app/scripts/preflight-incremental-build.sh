#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
readonly PROJECT_ROOT=$(cd -- "$SCRIPT_DIR/../.." && pwd)
readonly SERVER_DIR="$PROJECT_ROOT/source/azerothcore"
readonly BUILD_DIR="$PROJECT_ROOT/var/build"
readonly CCACHE_DIR="$PROJECT_ROOT/var/ccache"
readonly DIST_DIR="$PROJECT_ROOT/var/dist"

test -d "$SERVER_DIR/.git"
test -d "$SERVER_DIR/modules/mod-playerbots"
test -f "$SERVER_DIR/docker-compose.override.yml"
test -f "$SERVER_DIR/apps/docker/Dockerfile.dev-server"

for directory in "$BUILD_DIR" "$CCACHE_DIR" "$DIST_DIR/bin"; do
    mkdir -p "$directory"
    test -w "$directory"
done

docker info >/dev/null
docker compose \
    --project-directory "$SERVER_DIR" \
    --project-name azeroth-local \
    --profile incremental \
    config --quiet

printf 'Preflight incremental concluido; nenhuma compilacao foi iniciada.\n'
