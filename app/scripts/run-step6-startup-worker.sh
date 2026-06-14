#!/bin/bash

set -Eeuo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
PROJECT_ROOT=$(cd -- "$SCRIPT_DIR/../.." && pwd)
SERVER_DIR="$PROJECT_ROOT/source/azerothcore"
LOG_DIR="$PROJECT_ROOT/data/logs"
STATE_FILE="$LOG_DIR/step6-startup.state"
LOG_FILE="$LOG_DIR/step6-startup.log"
PREFLIGHT="$PROJECT_ROOT/app/scripts/preflight-step6-startup.sh"

select_docker() {
    if docker info >/dev/null 2>&1; then
        DOCKER=(docker)
    else
        echo "Docker nao esta acessivel para o usuario $USER." >&2
        return 1
    fi
}

compose() {
    "${DOCKER[@]}" compose \
        --project-directory "$SERVER_DIR" \
        --project-name azeroth-local \
        "$@"
}

set_state() {
    printf '%s\n' "$1" >"$STATE_FILE"
}

on_error() {
    exit_code=$?
    set_state "failed:$exit_code"
    printf '[%s] Etapa 6 falhou com codigo %s.\n' \
        "$(date --iso-8601=seconds)" "$exit_code"
    compose ps || true
    exit "$exit_code"
}

mkdir -p "$LOG_DIR"
exec >>"$LOG_FILE" 2>&1
trap on_error ERR

set_state "preflight"
printf '[%s] Iniciando preflight da etapa 6.\n' "$(date --iso-8601=seconds)"
select_docker
"$PREFLIGHT"

set_state "client-data"
printf '[%s] Baixando e validando client-data v19.\n' "$(date --iso-8601=seconds)"
compose up --no-build --no-deps --abort-on-container-exit \
    --exit-code-from ac-client-data-init ac-client-data-init

set_state "database"
printf '[%s] Iniciando banco de dados.\n' "$(date --iso-8601=seconds)"
compose up --no-build --no-deps --detach ac-database

for attempt in $(seq 1 60); do
    health=$("${DOCKER[@]}" inspect \
        --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' \
        azeroth-local-database)
    if [ "$health" = "healthy" ]; then
        break
    fi
    if [ "$attempt" -eq 60 ]; then
        echo "Banco nao ficou saudavel dentro do prazo." >&2
        exit 1
    fi
    sleep 5
done

set_state "database-import"
printf '[%s] Importando bancos e migrations do core.\n' "$(date --iso-8601=seconds)"
compose up --no-build --no-deps --abort-on-container-exit \
    --exit-code-from ac-db-import ac-db-import

set_state "services"
printf '[%s] Iniciando authserver e worldserver.\n' "$(date --iso-8601=seconds)"
playerbots_conf_dir="$SERVER_DIR/env/dist/etc/modules"
mkdir -p "$playerbots_conf_dir"
if [ ! -f "$playerbots_conf_dir/playerbots.conf" ]; then
    cp "$playerbots_conf_dir/playerbots.conf.dist" \
        "$playerbots_conf_dir/playerbots.conf"
fi
compose up --no-build --no-deps --detach ac-authserver ac-worldserver

for attempt in $(seq 1 36); do
    auth_running=$("${DOCKER[@]}" inspect \
        --format '{{.State.Running}}' azeroth-local-authserver)
    world_running=$("${DOCKER[@]}" inspect \
        --format '{{.State.Running}}' azeroth-local-worldserver)
    if [ "$auth_running" = "true" ] && [ "$world_running" = "true" ]; then
        sleep 10
        auth_running=$("${DOCKER[@]}" inspect \
            --format '{{.State.Running}}' azeroth-local-authserver)
        world_running=$("${DOCKER[@]}" inspect \
            --format '{{.State.Running}}' azeroth-local-worldserver)
        if [ "$auth_running" = "true" ] && [ "$world_running" = "true" ]; then
            break
        fi
    fi
    if [ "$attempt" -eq 36 ]; then
        echo "Servidores nao permaneceram ativos dentro do prazo." >&2
        exit 1
    fi
    sleep 5
done

set_state "completed"
printf '[%s] Etapa 6 concluida; servicos ativos.\n' "$(date --iso-8601=seconds)"
compose ps
