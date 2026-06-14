#!/bin/bash

set -Eeuo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
PROJECT_ROOT=$(cd -- "$SCRIPT_DIR/../.." && pwd)
SERVER_DIR="$PROJECT_ROOT/source/azerothcore"
LOG_DIR="$PROJECT_ROOT/data/logs"
STATE_FILE="$LOG_DIR/step5-build.state"
LOG_FILE="$LOG_DIR/step5-build.log"
PREFLIGHT="$PROJECT_ROOT/app/scripts/preflight-step5-build.sh"
ENV_FILE="$SERVER_DIR/.env"

select_docker() {
    if docker info >/dev/null 2>&1; then
        DOCKER=(docker)
    else
        echo "Docker nao esta acessivel para o usuario $USER." >&2
        return 1
    fi
}

mkdir -p "$LOG_DIR"
exec >>"$LOG_FILE" 2>&1

set_state() {
    printf '%s\n' "$1" >"$STATE_FILE"
}

on_error() {
    exit_code=$?
    set_state "failed:$exit_code"
    printf '[%s] Build falhou com codigo %s.\n' "$(date --iso-8601=seconds)" "$exit_code"
    exit "$exit_code"
}
trap on_error ERR

set_state "preflight"
printf '[%s] Iniciando preflight da etapa 5.\n' "$(date --iso-8601=seconds)"
"$PREFLIGHT"
select_docker

if [ ! -s "$ENV_FILE" ]; then
    umask 077
    db_password=$(openssl rand -hex 32)
    printf '%s\n' \
        "DOCKER_DB_ROOT_PASSWORD=$db_password" \
        "AZEROTH_LOCAL_ROOT=$PROJECT_ROOT" \
        "MIN_RANDOM_BOTS=100" \
        "MAX_RANDOM_BOTS=100" \
        "BUILD_JOBS=4" >"$ENV_FILE"
elif ! grep -q '^AZEROTH_LOCAL_ROOT=' "$ENV_FILE"; then
    printf 'AZEROTH_LOCAL_ROOT=%s\n' "$PROJECT_ROOT" >>"$ENV_FILE"
fi
chmod 0600 "$ENV_FILE"

set_state "building"
printf '[%s] Compilando imagens; nenhum container sera iniciado.\n' "$(date --iso-8601=seconds)"
"${DOCKER[@]}" compose \
    --progress plain \
    --project-directory "$SERVER_DIR" \
    --project-name azeroth-local \
    build

set_state "completed"
printf '[%s] Etapa 5 concluida.\n' "$(date --iso-8601=seconds)"
