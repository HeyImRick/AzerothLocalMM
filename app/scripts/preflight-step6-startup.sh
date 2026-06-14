#!/bin/bash

set -Eeuo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
PROJECT_ROOT=$(cd -- "$SCRIPT_DIR/../.." && pwd)
SERVER_DIR="$PROJECT_ROOT/source/azerothcore"
STEP5_STATE="$PROJECT_ROOT/data/logs/step5-build.state"
ENV_FILE="$SERVER_DIR/.env"
EXPECTED_IMAGES=(
    "azeroth-local/worldserver:82d3bf237d51"
    "azeroth-local/authserver:82d3bf237d51"
    "azeroth-local/db-import:82d3bf237d51"
    "azeroth-local/client-data:82d3bf237d51"
)

select_docker() {
    if docker info >/dev/null 2>&1; then
        DOCKER=(docker)
    else
        echo "Docker nao esta acessivel para o usuario $USER." >&2
        exit 1
    fi
}

test "$(cat "$STEP5_STATE")" = "completed"
test -s "$ENV_FILE"
test "$(stat -c %a "$ENV_FILE")" = "600"
test -w "$SERVER_DIR/env/dist/etc"
test -w "$SERVER_DIR/env/dist/logs"

select_docker

for image in "${EXPECTED_IMAGES[@]}"; do
    "${DOCKER[@]}" image inspect "$image" >/dev/null
done

if "${DOCKER[@]}" ps -a \
    --filter label=com.docker.compose.project=azeroth-local \
    --format '{{.Names}}' | grep -q .; then
    echo "Ja existem containers do projeto azeroth-local." >&2
    exit 1
fi

available_gb=$(df -BG "$PROJECT_ROOT" | awk 'NR == 2 {gsub(/G/, "", $4); print $4}')
if [ "$available_gb" -lt 30 ]; then
    echo "Espaco insuficiente: ${available_gb} GiB livres; minimo 30 GiB." >&2
    exit 1
fi

"${DOCKER[@]}" compose \
    --project-directory "$SERVER_DIR" \
    --project-name azeroth-local \
    config --quiet

printf 'Preflight da etapa 6 concluido: imagens, Compose, diretorios, Docker e disco estao prontos.\n'
