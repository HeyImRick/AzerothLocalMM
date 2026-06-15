#!/usr/bin/env bash
set -euo pipefail

readonly SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
readonly PROJECT_ROOT=$(cd -- "$SCRIPT_DIR/../.." && pwd)
readonly CLIENT_DIR="${WOW_CLIENT_DIR:-$PROJECT_ROOT/client/TheraWoW wotlk}"
readonly CLIENT_EXE="$CLIENT_DIR/Wow.exe"
readonly WINE_BIN="${WINE_BIN:-$(command -v wine || true)}"
readonly WINE_PREFIX="$PROJECT_ROOT/runtime/wine-prefix"
readonly LOG_DIR="$PROJECT_ROOT/data/logs"
readonly LOG_FILE="$LOG_DIR/wow-client.log"
readonly SYSTEMD_UNIT="azeroth-local-wow"

notify() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "Azeroth Local" "$1"
    fi
}

if [[ ! -f "$CLIENT_EXE" ]]; then
    notify "Cliente nao encontrado: $CLIENT_EXE"
    exit 1
fi

if [[ -z "$WINE_BIN" || ! -x "$WINE_BIN" ]]; then
    notify "Wine nao encontrado: $WINE_BIN"
    exit 1
fi

if systemctl --user --quiet is-active "$SYSTEMD_UNIT.service" ||
    pgrep -f '[W]ow.exe' >/dev/null 2>&1; then
    wmctrl -a "World of Warcraft" >/dev/null 2>&1 || true
    notify "O jogo ja esta aberto."
    exit 0
fi

if ! timeout 1 bash -c '</dev/tcp/127.0.0.1/3724' >/dev/null 2>&1; then
    notify "O servidor local nao respondeu na porta 3724. O jogo sera aberto, mas o login pode falhar."
fi

mkdir -p "$LOG_DIR"
printf '\n[%s] Solicitando inicio do World of Warcraft.\n' \
    "$(date --iso-8601=seconds)" >>"$LOG_FILE"

systemd-run \
    --user \
    --unit="$SYSTEMD_UNIT" \
    --collect \
    --property=Restart=no \
    --property="StandardOutput=append:$LOG_FILE" \
    --property="StandardError=append:$LOG_FILE" \
    --working-directory="$CLIENT_DIR" \
    --setenv="WINEPREFIX=$WINE_PREFIX" \
    --setenv="WINEDLLOVERRIDES=mscoree,mshtml=" \
    "$WINE_BIN" "./Wow.exe"
