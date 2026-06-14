#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
readonly PROJECT_ROOT=$(cd -- "$SCRIPT_DIR/../.." && pwd)
readonly SERVER_DIR="$PROJECT_ROOT/source/azerothcore"
readonly PREFLIGHT="$PROJECT_ROOT/app/scripts/preflight-incremental-build.sh"

"$PREFLIGHT"

docker compose \
    --project-directory "$SERVER_DIR" \
    --project-name azeroth-local \
    --profile incremental \
    run --rm ac-incremental-builder bash -lc '
        set -Eeuo pipefail
        ccache --max-size "${CCACHE_MAXSIZE}"
        cmake -S /azerothcore -B /work/build -G Ninja \
            -DCMAKE_INSTALL_PREFIX=/work/dist \
            -DAPPS_BUILD=all \
            -DTOOLS_BUILD=all \
            -DSCRIPTS=static \
            -DMODULES=static \
            -DWITH_WARNINGS=ON \
            -DCMAKE_BUILD_TYPE=RelWithDebInfo \
            -DCMAKE_CXX_COMPILER=clang++ \
            -DCMAKE_C_COMPILER=clang \
            -DCMAKE_CXX_COMPILER_LAUNCHER=ccache \
            -DCMAKE_C_COMPILER_LAUNCHER=ccache \
            -DBoost_USE_STATIC_LIBS=ON
        cmake --build /work/build --target worldserver -j "${BUILD_JOBS:-4}"
        worldserver_path=$(find /work/build -type f -name worldserver -perm -u+x -print -quit)
        test -n "$worldserver_path"
        install -m 0755 "$worldserver_path" /work/dist/bin/worldserver
    '

test -x "$PROJECT_ROOT/var/dist/bin/worldserver"
printf 'Build incremental concluido: %s\n' "$PROJECT_ROOT/var/dist/bin/worldserver"
