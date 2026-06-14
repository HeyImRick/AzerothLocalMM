#!/bin/bash

set -Eeuo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
PROJECT_ROOT=$(cd -- "$SCRIPT_DIR/../.." && pwd)
LOG_DIR="$PROJECT_ROOT/data/logs"
STATE_FILE="$LOG_DIR/step6-startup.state"
LOG_FILE="$LOG_DIR/step6-startup.log"
UNIT="azeroth-local-step6-startup.service"

printf 'Estado: '
if [ -r "$STATE_FILE" ]; then
    cat "$STATE_FILE"
else
    echo "not-started"
fi

printf 'Servico: '
systemctl --user is-active "$UNIT" 2>/dev/null || true

if [ -r "$LOG_FILE" ]; then
    echo
    echo "Ultimas 40 linhas:"
    tail -n 40 "$LOG_FILE"
fi
