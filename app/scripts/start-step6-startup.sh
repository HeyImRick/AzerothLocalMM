#!/bin/bash

set -Eeuo pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
PROJECT_ROOT=$(cd -- "$SCRIPT_DIR/../.." && pwd)
UNIT="azeroth-local-step6-startup.service"
WORKER="$PROJECT_ROOT/app/scripts/run-step6-startup-worker.sh"

if systemctl --user is-active --quiet "$UNIT"; then
    echo "A etapa 6 ja esta em execucao."
    exit 1
fi

"$PROJECT_ROOT/app/scripts/preflight-step6-startup.sh"

systemd-run \
    --user \
    --unit="${UNIT%.service}" \
    --collect \
    --property=Restart=no \
    --property=TimeoutStartSec=infinity \
    "$WORKER"

echo "Etapa 6 iniciada como $UNIT."
echo "Consulte: $PROJECT_ROOT/app/scripts/status-step6-startup.sh"
