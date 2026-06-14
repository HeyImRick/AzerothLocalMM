#!/bin/bash

set -Eeuo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
PROJECT_ROOT=$(cd -- "$SCRIPT_DIR/../.." && pwd)
LOG_DIR="$PROJECT_ROOT/data/logs"
STATE_FILE="$LOG_DIR/step5-build.state"
LOG_FILE="$LOG_DIR/step5-build.log"
UNIT="azeroth-local-step5-build.service"

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
    echo "Ultimas 30 linhas:"
    tail -n 30 "$LOG_FILE"
fi
