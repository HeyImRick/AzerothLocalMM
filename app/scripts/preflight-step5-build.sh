#!/bin/bash

set -Eeuo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
PROJECT_ROOT=$(cd -- "$SCRIPT_DIR/../.." && pwd)
SERVER_DIR="$PROJECT_ROOT/source/azerothcore"
LOCK_FILE="$PROJECT_ROOT/app/manifests/sources.lock.env"
OVERRIDE_TEMPLATE="$PROJECT_ROOT/app/compose/docker-compose.override.yml"
CORE_PATCH="$PROJECT_ROOT/custom/patches/0001-core-customizations.patch"
PLAYERBOTS_PATCH="$PROJECT_ROOT/custom/patches/0002-playerbots-customizations.patch"

select_docker() {
    if docker info >/dev/null 2>&1; then
        DOCKER=(docker)
    else
        echo "Docker nao esta acessivel para o usuario $USER." >&2
        exit 1
    fi
}

# shellcheck source=/dev/null
source "$LOCK_FILE"

test "$(git -C "$SERVER_DIR" rev-parse HEAD)" = "$CORE_COMMIT"
test "$(git -C "$SERVER_DIR/modules/mod-playerbots" rev-parse HEAD)" = "$PLAYERBOTS_COMMIT"
cmp -s "$OVERRIDE_TEMPLATE" "$SERVER_DIR/docker-compose.override.yml"
git -C "$SERVER_DIR" apply --reverse --check "$CORE_PATCH"
git -C "$SERVER_DIR/modules/mod-playerbots" apply --reverse --check "$PLAYERBOTS_PATCH"
select_docker
systemctl --user is-system-running | grep -qx running

available_gb=$(df -BG "$PROJECT_ROOT" | awk 'NR == 2 {gsub(/G/, "", $4); print $4}')
if [ "$available_gb" -lt 60 ]; then
    echo "Espaco insuficiente: ${available_gb} GiB livres; minimo 60 GiB." >&2
    exit 1
fi

validation_env=$(mktemp)
trap 'rm -f "$validation_env"' EXIT
chmod 0600 "$validation_env"
printf '%s\n' \
    "DOCKER_DB_ROOT_PASSWORD=preflight-not-used" \
    "AZEROTH_LOCAL_ROOT=$PROJECT_ROOT" \
    "MIN_RANDOM_BOTS=100" \
    "MAX_RANDOM_BOTS=100" \
    "BUILD_JOBS=4" >"$validation_env"

"${DOCKER[@]}" compose \
    --env-file "$validation_env" \
    --project-directory "$SERVER_DIR" \
    --project-name azeroth-local \
    config --quiet

printf 'Preflight concluido: fontes, patches, Compose, Docker, systemd e disco estao prontos.\n'
