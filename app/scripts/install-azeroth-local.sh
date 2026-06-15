#!/bin/bash
# ============================================================
#  Azeroth Local — Nobara/Fedora Playerbots Installer
#  Adapted from Dad's MMO Lab installer 1.2.0.
#
#  https://github.com/DadsMmoLab/dads-mmo-lab
#
#  Version: 0.1.0-local
#
#  Usage:
#    chmod +x install-azeroth-local.sh
#    ./install-azeroth-local.sh
#
#  What this does:
#    1. Validates the preinstalled host dependencies
#    2. Shows a summary before building
#    3. Compiles AzerothCore + Playerbots (~2-4 hours)
#    4. Waits for the world server to initialize
#    5. Guides you through account creation
#    6. Sets up the Gaming Mode launcher
#
#  Changelog:
#    1.2.0 — Playerbots-only focus
#      - Removed Base WoW and NPCBots options
#      - Single clear install path: Playerbots, compiled from source
#      - Fixed DB container name discovery (was hardcoded, broke on
#        non-default install dirs)
#      - Replaced sleep 15 DB wait with real connection polling
#    1.1.0 — Error handling overhaul
#      - Keyring reset now checks health first and requires confirmation
#      - install_docker() surfaces real errors instead of silencing them
#      - install_git() no longer reports success on failure
#      - SQL apply loops track and report failures
#      - systemctl start docker exits cleanly on failure
#      - Heredoc launcher synced with standalone launcher scripts
# ============================================================

WIZARD_VERSION="0.1.0-local"

set -Eeuo pipefail

# ─────────────────────────────────────────
# COLORS
# ─────────────────────────────────────────
RST='\033[0m'; BOLD='\033[1m'
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; WHITE='\033[1;37m'; CYAN='\033[0;36m'
MAGENTA='\033[0;35m'; NC='\033[0m'
GOLD='\033[38;5;220m'; DIM='\033[2m'

print_header() {
    clear
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${WHITE}${BOLD}         ⚙️  DAD'S MMO LAB                        ${NC}${CYAN}║${NC}"
    echo -e "${CYAN}║${WHITE}         WoW Playerbots Installer                 ${NC}${CYAN}║${NC}"
    echo -e "${CYAN}║${BLUE}         github.com/DadsMmoLab/dads-mmo-lab       ${NC}${CYAN}║${NC}"
    echo -e "${CYAN}║${YELLOW}         Version ${WIZARD_VERSION}                              ${NC}${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_step() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}${BOLD} $1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error()   { echo -e "${RED}❌ $1${NC}"; }
print_info()    { echo -e "${BLUE}ℹ️  $1${NC}"; }

ask_yes_no() {
    while true; do
        echo -e "${WHITE}$1 (y/n): ${NC}"
        read -r answer
        case $answer in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer y or n.";;
        esac
    done
}

press_enter() {
    echo ""
    echo -e "${WHITE}Press ENTER to continue...${NC}"
    read -r
}

# ─────────────────────────────────────────
# CONFIGURATION
# ─────────────────────────────────────────
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
PROJECT_ROOT=$(cd -- "$SCRIPT_DIR/../.." && pwd)
SERVER_DIR="$PROJECT_ROOT/source/azerothcore"
MODULES_DIR="$SERVER_DIR/modules"
LOG_DIR="$PROJECT_ROOT/data/logs"
LAUNCHER_PATH="$PROJECT_ROOT/app/scripts/start-azeroth-local.sh"
COMPOSE_OVERRIDE_TEMPLATE="$PROJECT_ROOT/app/compose/docker-compose.override.yml"
SOURCE_LOCK_FILE="$PROJECT_ROOT/app/manifests/sources.lock.env"
CORE_PATCH="$PROJECT_ROOT/custom/patches/0001-core-customizations.patch"
PLAYERBOTS_PATCH="$PROJECT_ROOT/custom/patches/0002-playerbots-customizations.patch"
COMPOSE_PROJECT_NAME="azeroth-local"
MIN_RANDOM_BOTS="100"
MAX_RANDOM_BOTS="100"
BUILD_JOBS="4"

if [ ! -r "$SOURCE_LOCK_FILE" ]; then
    echo "Missing source lock file: $SOURCE_LOCK_FILE" >&2
    exit 1
fi

# shellcheck source=/dev/null
source "$SOURCE_LOCK_FILE"

: "${CORE_REPOSITORY:?Missing CORE_REPOSITORY}"
: "${CORE_BRANCH:?Missing CORE_BRANCH}"
: "${CORE_COMMIT:?Missing CORE_COMMIT}"
: "${PLAYERBOTS_REPOSITORY:?Missing PLAYERBOTS_REPOSITORY}"
: "${PLAYERBOTS_BRANCH:?Missing PLAYERBOTS_BRANCH}"
: "${PLAYERBOTS_COMMIT:?Missing PLAYERBOTS_COMMIT}"
: "${TRANSMOG_REPOSITORY:?Missing TRANSMOG_REPOSITORY}"
: "${TRANSMOG_BRANCH:?Missing TRANSMOG_BRANCH}"
: "${TRANSMOG_COMMIT:?Missing TRANSMOG_COMMIT}"

export COMPOSE_PROJECT_NAME

ensure_runtime_env() {
    local env_file="$SERVER_DIR/.env"

    if [ -s "$env_file" ]; then
        if ! grep -q '^AZEROTH_LOCAL_ROOT=' "$env_file"; then
            printf 'AZEROTH_LOCAL_ROOT=%s\n' "$PROJECT_ROOT" >> "$env_file"
        fi
        chmod 0600 "$env_file"
        return
    fi

    local db_password
    db_password=$(openssl rand -hex 32)
    umask 077
    printf '%s\n' \
        "DOCKER_DB_ROOT_PASSWORD=$db_password" \
        "AZEROTH_LOCAL_ROOT=$PROJECT_ROOT" \
        "MIN_RANDOM_BOTS=$MIN_RANDOM_BOTS" \
        "MAX_RANDOM_BOTS=$MAX_RANDOM_BOTS" \
        "BUILD_JOBS=$BUILD_JOBS" > "$env_file"
    chmod 0600 "$env_file"
}

apply_source_patches() {
    local patch
    for patch in "$CORE_PATCH" "$PLAYERBOTS_PATCH"; do
        if [ ! -r "$patch" ]; then
            print_error "Required source patch is missing: $patch"
            exit 1
        fi
    done

    if git -C "$SERVER_DIR" apply --reverse --check "$CORE_PATCH" 2>/dev/null; then
        print_success "Core customizations already applied."
    elif git -C "$SERVER_DIR" apply --check "$CORE_PATCH"; then
        git -C "$SERVER_DIR" apply "$CORE_PATCH"
        print_success "Applied core build and client-data customizations."
    else
        print_error "Core customizations do not apply cleanly to the locked commit."
        exit 1
    fi

    if git -C "$MODULES_DIR/mod-playerbots" apply --reverse --check "$PLAYERBOTS_PATCH" 2>/dev/null; then
        print_success "Playerbots customizations already applied."
    elif git -C "$MODULES_DIR/mod-playerbots" apply --check "$PLAYERBOTS_PATCH"; then
        git -C "$MODULES_DIR/mod-playerbots" apply "$PLAYERBOTS_PATCH"
        print_success "Applied peak command and regional bot population."
    else
        print_error "Playerbots customizations do not apply cleanly to the locked commit."
        exit 1
    fi
}

# ─────────────────────────────────────────
# SYSTEM CHECKS
# ─────────────────────────────────────────
check_system() {
    print_step "Checking System Requirements"

    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        print_error "This script requires Linux."
        exit 1
    fi
    print_success "Linux detected"

    if ! grep -Eq '^(ID|ID_LIKE)=.*(nobara|fedora|rhel)' /etc/os-release; then
        print_error "This adapted installer supports Nobara/Fedora-family systems only."
        exit 1
    fi
    print_success "Nobara/Fedora family detected"

    if [ ! -d "$PROJECT_ROOT" ] || [ ! -w "$PROJECT_ROOT" ]; then
        print_error "Project root is missing or not writable: $PROJECT_ROOT"
        exit 1
    fi

    AVAILABLE_GB=$(df -BG "$PROJECT_ROOT" 2>/dev/null | awk 'NR==2 {print $4}' | sed 's/G//' | tr -d ' ')
    if [ -n "$AVAILABLE_GB" ] && [ "$AVAILABLE_GB" -lt 60 ] 2>/dev/null; then
        print_error "Not enough project disk space. You have ${AVAILABLE_GB}GB free, need at least 60GB."
        exit 1
    fi
    print_success "Disk space OK (${AVAILABLE_GB:-unknown}GB available)"

    local required=(docker git)
    local command_name
    for command_name in "${required[@]}"; do
        if ! command -v "$command_name" &>/dev/null; then
            print_error "Required command is missing: $command_name"
            exit 1
        fi
    done

    if ! docker compose version &>/dev/null; then
        print_error "Docker Compose plugin is unavailable."
        exit 1
    fi

    if ! docker info &>/dev/null; then
        print_error "Docker is not accessible for user $USER."
        print_info "Log out and back in if group membership was added recently."
        exit 1
    fi
    print_success "Docker and Compose are ready"

    if ! git ls-remote "$CORE_REPOSITORY" "refs/heads/$CORE_BRANCH" | \
         grep -q .; then
        print_error "Cannot reach the Playerbots source repository."
        exit 1
    fi
    if ! git ls-remote "$PLAYERBOTS_REPOSITORY" "refs/heads/$PLAYERBOTS_BRANCH" | \
         grep -q .; then
        print_error "Cannot reach the official Playerbots module repository."
        exit 1
    fi
    print_success "Internet connection OK"
}

# ─────────────────────────────────────────
# STEP 1 — SUMMARY AND CONFIRM
# ─────────────────────────────────────────
show_summary() {
    print_header
    print_step "STEP 1/4 — What We're Building"

    echo ""
    echo -e "  ${WHITE}${BOLD}Server:${NC}   ${CYAN}WoW Playerbots (AzerothCore WotLK)${NC}"
    echo -e "  ${WHITE}${BOLD}Folder:${NC}   ${CYAN}$SERVER_DIR${NC}"
    echo -e "  ${WHITE}${BOLD}Install:${NC}  ${YELLOW}Compile from source (2-4 hours)${NC}"
    echo ""
    echo -e "  ${WHITE}${BOLD}What you get:${NC}"
    echo -e "    ${GREEN}✅${NC} ${MIN_RANDOM_BOTS}-${MAX_RANDOM_BOTS} AI players in the initial profile"
    echo -e "    ${GREEN}✅${NC} Bots quest, dungeon, raid alongside you"
    echo -e "    ${GREEN}✅${NC} Azeroth feels truly alive — solo or co-op"
    echo ""
    echo -e "${YELLOW}  ⚠️  COMPILATION WARNING:${NC}"
    echo -e "  This may take several hours on the current host."
    echo -e "  The build remains entirely under the project Btrfs volume."
    echo ""

    if ! ask_yes_no "Ready to build your Playerbots server?"; then
        echo ""
        echo -e "${WHITE}No problem! Run this script again when you're ready.${NC}"
        exit 0
    fi
}

# ─────────────────────────────────────────
# STEP 2 — INSTALL SERVER
# ─────────────────────────────────────────
install_server() {
    print_header
    print_step "STEP 2/4 — Building Playerbots Server (2-4 hours)"

    print_info "Host dependencies were validated before confirmation."

    # ── Skip clone+compile if images already built ───────────────────
    # AzerothCore's compose setup builds and manages its own images.
    # If they already exist in $SERVER_DIR, skip the 2-4 hour compile
    # and just start the server — the rest of the install continues
    # normally (account creation, launcher setup, etc.).
    if [ -d "$SERVER_DIR" ] && \
       (cd "$SERVER_DIR" && \
        docker compose --project-name "$COMPOSE_PROJECT_NAME" images 2>/dev/null | \
        grep -qi "worldserver"); then
        print_success "Compiled images already found in $SERVER_DIR"
        print_info "Skipping compile — reusing your existing build."
        cd "$SERVER_DIR" || exit 1
        docker compose --project-name "$COMPOSE_PROJECT_NAME" up -d 2>&1 | tail -5
        return 0
    fi

    if [ -d "$SERVER_DIR/.git" ]; then
        print_success "Existing AzerothCore checkout found; it will be preserved."
    elif [ -n "$(find "$SERVER_DIR" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]; then
        print_error "Source directory is not empty and is not a Git checkout:"
        print_info "$SERVER_DIR"
        print_info "The installer will not delete or overwrite it."
        exit 1
    else
        print_info "Cloning Playerbots source..."
        print_info "Using immutable core commit: $CORE_COMMIT"
        git clone \
            --branch="$CORE_BRANCH" \
            "$CORE_REPOSITORY" \
            "$SERVER_DIR"
        git -C "$SERVER_DIR" checkout --detach "$CORE_COMMIT"
    fi

    if [ ! -d "$SERVER_DIR/.git" ]; then
        print_error "Clone failed. Check your internet connection."
        exit 1
    fi
    if [ "$(git -C "$SERVER_DIR" rev-parse HEAD)" != "$CORE_COMMIT" ]; then
        print_error "Core checkout does not match the locked commit."
        exit 1
    fi
    mkdir -p "$MODULES_DIR" "$LOG_DIR"

    if [ -d "$MODULES_DIR/mod-playerbots/.git" ]; then
        print_success "Existing mod-playerbots checkout found; it will be preserved."
    elif [ -e "$MODULES_DIR/mod-playerbots" ]; then
        print_error "Module path exists but is not a Git checkout:"
        print_info "$MODULES_DIR/mod-playerbots"
        exit 1
    else
        print_info "Cloning immutable Playerbots commit: $PLAYERBOTS_COMMIT"
        git clone \
            --branch="$PLAYERBOTS_BRANCH" \
            "$PLAYERBOTS_REPOSITORY" \
            "$MODULES_DIR/mod-playerbots"
        git -C "$MODULES_DIR/mod-playerbots" checkout --detach "$PLAYERBOTS_COMMIT"
    fi
    if [ "$(git -C "$MODULES_DIR/mod-playerbots" rev-parse HEAD)" != "$PLAYERBOTS_COMMIT" ]; then
        print_error "Playerbots checkout does not match the locked commit."
        exit 1
    fi

    if [ -d "$MODULES_DIR/mod-transmog/.git" ]; then
        print_success "Existing mod-transmog checkout found; it will be preserved."
    elif [ -e "$MODULES_DIR/mod-transmog" ]; then
        print_error "Module path exists but is not a Git checkout:"
        print_info "$MODULES_DIR/mod-transmog"
        exit 1
    else
        print_info "Cloning immutable Transmog commit: $TRANSMOG_COMMIT"
        git clone \
            --branch="$TRANSMOG_BRANCH" \
            "$TRANSMOG_REPOSITORY" \
            "$MODULES_DIR/mod-transmog"
        git -C "$MODULES_DIR/mod-transmog" checkout --detach "$TRANSMOG_COMMIT"
    fi
    if [ "$(git -C "$MODULES_DIR/mod-transmog" rev-parse HEAD)" != "$TRANSMOG_COMMIT" ]; then
        print_error "Transmog checkout does not match the locked commit."
        exit 1
    fi

    apply_source_patches

    if [ ! -f "$COMPOSE_OVERRIDE_TEMPLATE" ]; then
        print_error "Compose override template not found: $COMPOSE_OVERRIDE_TEMPLATE"
        exit 1
    fi
    if [ -f "$SERVER_DIR/docker-compose.override.yml" ] && \
       ! cmp -s "$COMPOSE_OVERRIDE_TEMPLATE" "$SERVER_DIR/docker-compose.override.yml"; then
        print_error "A different Compose override already exists."
        print_info "The installer will not overwrite: $SERVER_DIR/docker-compose.override.yml"
        exit 1
    fi
    cp "$COMPOSE_OVERRIDE_TEMPLATE" "$SERVER_DIR/docker-compose.override.yml"
    ensure_runtime_env

    print_info "Compiling Playerbots server (2-4 hours)..."
    local build_log="$LOG_DIR/playerbots-build.log"
    print_info "Progress saved to: $build_log"

    cd "$SERVER_DIR"
    MIN_RANDOM_BOTS="$MIN_RANDOM_BOTS" MAX_RANDOM_BOTS="$MAX_RANDOM_BOTS" \
        docker compose --project-name "$COMPOSE_PROJECT_NAME" up -d --build 2>&1 | tee "$build_log"

    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        print_error "Compilation failed. Check $build_log"
        exit 1
    fi

    print_success "Playerbots server compiled!"
}

# ─────────────────────────────────────────
# WAIT FOR SERVER READY
# ─────────────────────────────────────────
wait_for_server() {
    print_info "Waiting for world server to initialize..."
    print_info "First launch after compilation may take 10-15 minutes."
    echo ""

    TIMEOUT=1800
    ELAPSED=0
    READY=0
    WORLD_CONTAINER=""

    while [ $ELAPSED -lt $TIMEOUT ]; do
        WORLD_CONTAINER=$(cd "$SERVER_DIR" && \
            docker compose --project-name "$COMPOSE_PROJECT_NAME" ps -q ac-worldserver 2>/dev/null)

        if [ -n "$WORLD_CONTAINER" ]; then
            if docker logs "$WORLD_CONTAINER" \
                2>/dev/null | grep -q "ready\.\.\."; then
                READY=1
                break
            fi
        fi

        printf "."
        sleep 10
        ELAPSED=$((ELAPSED + 10))
    done

    echo ""
    echo ""

    if [ $READY -eq 1 ]; then
        print_success "Server is READY! ⚔️"
    else
        print_warning "Server is taking longer than expected."
        print_info "Check progress from $SERVER_DIR:"
        print_info "docker compose --project-name $COMPOSE_PROJECT_NAME logs -f ac-worldserver"
        print_info "Wait for 'ready...' then create accounts manually."
    fi
}

# ─────────────────────────────────────────
# STEP 3 — CREATE ACCOUNTS
# ─────────────────────────────────────────
create_accounts() {
    print_header
    print_step "STEP 3/4 — Create Your Accounts"

    echo ""
    echo -e "${GREEN}${BOLD}Your server is running!${NC}"
    echo ""
    echo -e "${WHITE}Now create your account. Open a NEW Konsole window${NC}"
    echo -e "${WHITE}and run these three steps:${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${WHITE}${BOLD}1. Open the GM Console:${NC}"
    echo -e "   ${CYAN}cd \"$SERVER_DIR\"${NC}"
    echo -e "   ${CYAN}docker compose --project-name $COMPOSE_PROJECT_NAME attach ac-worldserver${NC}"
    echo ""
    echo -e "${WHITE}${BOLD}2. Create your account (replace USERNAME and PASSWORD):${NC}"
    echo -e "   ${GREEN}account create USERNAME PASSWORD${NC}"
    echo -e "   ${GREEN}account set gmlevel USERNAME 3 -1${NC}"
    echo ""
    echo -e "${WHITE}${BOLD}3. Exit the console safely:${NC}"
    echo -e "   ${YELLOW}Ctrl+P then Ctrl+Q${NC}"
    echo -e "   ${RED}Never press Ctrl+C — that stops the server!${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${WHITE}Press ENTER when done creating accounts...${NC}"
    read -r
}

# ─────────────────────────────────────────
# STEP 4 — GAMING MODE SETUP
# ─────────────────────────────────────────
setup_gaming_mode() {
    print_step "STEP 4/4 — Setting Up Gaming Mode"

    local launcher_path="$LAUNCHER_PATH"
    local server_dir="$SERVER_DIR"

    cat > "$launcher_path" << LAUNCHER
#!/bin/bash
# Dad's MMO Lab — WoW Playerbots Launcher v${WIZARD_VERSION}
export PATH="/usr/bin:/usr/local/bin:/bin:\$PATH"
unset LD_PRELOAD
unset LD_LIBRARY_PATH

LOGFILE="${LOG_DIR}/launcher.log"
exec 2>"\$LOGFILE"

clear
echo ""
printf "${GOLD} ══════════════════════════════════════════════════════════════════════════════════${NC}\n"
printf "   ${DIM}Dad's MMO Lab${NC}  ✦  ${DIM}WoW Playerbots${NC}\n"
printf "${GOLD} ══════════════════════════════════════════════════════════════════════════════════${NC}\n"
echo ""
echo -e "  ${WHITE}${BOLD}Starting server...${NC}"
echo ""

cd "${server_dir}" || exit 1

export COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME}"
export MIN_RANDOM_BOTS="${MIN_RANDOM_BOTS}"
export MAX_RANDOM_BOTS="${MAX_RANDOM_BOTS}"

if docker compose --project-name "\$COMPOSE_PROJECT_NAME" up -d >> "\$LOGFILE" 2>&1; then
    echo -e "  ${GREEN}✅ Containers started!${NC}"
else
    echo -e "  ${RED}❌ Failed to start server.${NC}"
    echo -e "  ${DIM}Check: \$LOGFILE${NC}"
    sleep 10
    exit 1
fi

echo ""
printf "${GOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
echo -e "${WHITE}${BOLD} Waiting for Azeroth to wake up...${NC}"
printf "${GOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
echo ""
echo -e "  ${DIM}First launch: 5-15 minutes${NC}"
echo -e "  ${DIM}After first launch: ~30 seconds${NC}"
echo ""

TIMEOUT=900
ELAPSED=0
READY=0
WORLD_CONTAINER=""

while [ \$ELAPSED -lt \$TIMEOUT ]; do
    WORLD_CONTAINER=\$(docker compose --project-name "\$COMPOSE_PROJECT_NAME" ps -q ac-worldserver 2>/dev/null)
    if [ -n "\$WORLD_CONTAINER" ]; then
        if docker logs "\$WORLD_CONTAINER" 2>/dev/null | grep -q "ready\.\.\."; then
            READY=1
            break
        fi
    fi
    printf "  ${GOLD}.${NC}"
    sleep 5
    ELAPSED=\$((ELAPSED + 5))
done

echo ""
echo ""

if [ \$READY -eq 1 ]; then
    printf "${GOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    echo -e "${GREEN}${BOLD}  ✅ AZEROTH IS READY!${NC}"
    printf "${GOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
else
    echo -e "  ${YELLOW}⏳ Still initializing — launch WoW soon${NC}"
fi

echo ""
echo -e "  ${WHITE}${BOLD}Press STEAM button and launch WoW${NC}"
echo -e "  ${DIM}Server AUTO-SHUTS DOWN when WoW closes${NC}"
echo -e "  ${DIM}── or press ENTER to shut down manually ──${NC}"
echo ""

MANUAL_SHUTDOWN=0
WOW_STARTED=0
for i in \$(seq 1 60); do
    if pgrep -fi "Wow\\.exe|wine.*[Ww]o[Ww]" > /dev/null 2>&1; then
        WOW_STARTED=1
        break
    fi
    if read -r -t 5 2>/dev/null; then
        MANUAL_SHUTDOWN=1
        break
    fi
done

if [ \$MANUAL_SHUTDOWN -eq 0 ]; then
    if [ \$WOW_STARTED -eq 1 ]; then
        echo -e "  ${GREEN}⚔️  WoW detected! Enjoy Azeroth!${NC}"
        while pgrep -fi "Wow\\.exe|wine.*[Ww]o[Ww]" > /dev/null 2>&1; do
            if read -r -t 3 2>/dev/null; then
                MANUAL_SHUTDOWN=1
                break
            fi
        done
        if [ \$MANUAL_SHUTDOWN -eq 0 ]; then
            sleep 5
            echo -e "  ${YELLOW}WoW closed — shutting down...${NC}"
        fi
    else
        echo -e "  ${DIM}WoW not detected — press ENTER to shut down.${NC}"
        read -r
    fi
fi

if [ \$MANUAL_SHUTDOWN -eq 1 ]; then
    echo -e "  ${YELLOW}Manual shutdown — shutting down...${NC}"
fi

cd "${server_dir}" && docker compose --project-name "\$COMPOSE_PROJECT_NAME" down >> "\$LOGFILE" 2>&1

echo ""
printf "${GOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
echo -e "${GREEN}${BOLD}  ✅ Server stopped! Safe to close.${NC}"
echo -e "  ${DIM}Thanks for playing! youtube.com/@DadsMmoLab${NC}"
printf "${GOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
echo ""
sleep 5
LAUNCHER

    chmod +x "$launcher_path"
    print_success "Launcher created: $launcher_path"

    # Save server info
    cat > "$SERVER_DIR/MY_SERVER.txt" << INFO
====================================
  Dad's MMO Lab — WoW Playerbots
  AzerothCore WotLK + Playerbots
====================================

SERVER:
  Folder:    ${SERVER_DIR}
  Realmlist: 127.0.0.1
  Account:   create via mangosd console (see below)

LAUNCHER:
  Path: ${launcher_path}
  Add to Steam:
    Target:  /usr/bin/konsole
    Options: --hold -e bash "${launcher_path}"
    Proton:  OFF (launcher needs no Proton)

REALMLIST (in your WoW client folder):
  Edit:  realmlist.wtf
  Set to: set realmlist 127.0.0.1

USEFUL COMMANDS:
  Start:   cd "${SERVER_DIR}" && docker compose --project-name ${COMPOSE_PROJECT_NAME} up -d
  Stop:    cd "${SERVER_DIR}" && docker compose --project-name ${COMPOSE_PROJECT_NAME} down
  Logs:    cd "${SERVER_DIR}" && docker compose --project-name ${COMPOSE_PROJECT_NAME} logs -f
  Console: cd "${SERVER_DIR}" && docker compose --project-name ${COMPOSE_PROJECT_NAME} attach ac-worldserver
    (Exit safely: Ctrl+P then Ctrl+Q. NOT Ctrl+C.)

CREATE ACCOUNTS:
  cd "${SERVER_DIR}"
  docker compose --project-name ${COMPOSE_PROJECT_NAME} attach ac-worldserver
  account create USERNAME PASSWORD
  account set gmlevel USERNAME 3 -1   (optional: makes GM)
  [Ctrl+P then Ctrl+Q to exit safely]
INFO

    print_success "Server info saved to: $SERVER_DIR/MY_SERVER.txt"
}

# ─────────────────────────────────────────
# DONE
# ─────────────────────────────────────────
show_completion() {
    echo ""
    echo -e "${GOLD}${BOLD}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${GOLD}${BOLD}║   🎉 YOUR PLAYERBOTS SERVER IS READY!            ║${NC}"
    echo -e "${GOLD}${BOLD}╚══════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${WHITE}${BOLD}Server:${NC}   ${CYAN}WoW Playerbots (AzerothCore WotLK)${NC}"
    echo -e "  ${WHITE}${BOLD}Folder:${NC}   ${CYAN}$SERVER_DIR${NC}"
    echo -e "  ${WHITE}${BOLD}Launcher:${NC} ${CYAN}$LAUNCHER_PATH${NC}"
    echo ""

    echo -e "${GOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}${BOLD} STEP A — Set Your WoW Realmlist${NC}"
    echo -e "${GOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  1. Open your WoW client folder in the file manager"
    echo -e "  2. Find and open: ${CYAN}realmlist.wtf${NC}"
    echo -e "  3. Make sure it says exactly: ${GREEN}set realmlist 127.0.0.1${NC}"
    echo -e "  4. Save the file"
    echo ""

    echo -e "${GOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}${BOLD} STEP B — Add to Steam Gaming Mode${NC}"
    echo -e "${GOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  Your Gaming Mode launcher was created here:"
    echo ""
    echo -e "  ${GREEN}${BOLD}$LAUNCHER_PATH${NC}"
    echo ""
    echo -e "  Add it to Steam:"
    echo -e "  1. Open Steam in Desktop Mode"
    echo -e "  2. Click ${CYAN}Games${NC} → ${CYAN}Add a Non-Steam Game${NC}"
    echo -e "  3. Click ${CYAN}Browse${NC} → navigate to ${CYAN}/usr/bin/${NC}"
    echo -e "  4. Select ${CYAN}konsole${NC} → click ${CYAN}Add Selected Programs${NC}"
    echo -e "  5. Find ${CYAN}konsole${NC} in your library"
    echo -e "  6. Right-click → ${CYAN}Properties${NC}"
    echo -e "  7. Rename it to: ${GREEN}WoW Playerbots Server${NC}"
    echo -e "  8. Set Launch Options to exactly:"
    echo ""
    echo -e "  ${GREEN}--hold -e bash \"$LAUNCHER_PATH\"${NC}"
    echo ""
    echo -e "  9. Under Compatibility — ${RED}do NOT enable Proton${NC}"
    echo ""

    echo -e "${GOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}${BOLD} STEP C — Play!${NC}"
    echo -e "${GOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  1. Switch to Gaming Mode"
    echo -e "  2. Launch ${CYAN}WoW Playerbots Server${NC} from your library"
    echo -e "  3. Watch the dots... wait for ${GREEN}AZEROTH IS READY!${NC}"
    echo -e "  4. Press Steam button → launch WoW"
    echo -e "  5. Login with the account you created"
    echo -e "  6. Play! Bots populate within 5-10 min — be patient!"
    echo -e "  7. Close WoW → server shuts down automatically ✅"
    echo ""
    echo -e "  ${YELLOW}Server info saved at: $SERVER_DIR/MY_SERVER.txt${NC}"
    echo ""
    echo -e "${GOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${WHITE}  📺 youtube.com/@DadsMmoLab${NC}"
    echo -e "${WHITE}  📦 github.com/DadsMmoLab/dads-mmo-lab${NC}"
    echo -e "${WHITE}  ☕ ko-fi.com/dadsmmolab${NC}"
    echo -e "${GOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${GREEN}${BOLD}Welcome to Azeroth. It's yours now. Forever. ⚔️${NC}"
    echo ""
    echo -e "${YELLOW}  ℹ️  Your server is still running right now!${NC}"
    echo -e "${YELLOW}  To stop it: ${CYAN}cd \"$SERVER_DIR\" && docker compose --project-name $COMPOSE_PROJECT_NAME down${NC}"
    echo -e "${YELLOW}  Or just use the Gaming Mode launcher next time.${NC}"
    echo ""
    if ask_yes_no "Would you like to stop the server now?"; then
        print_info "Stopping server..."
        cd "$SERVER_DIR" && docker compose --project-name "$COMPOSE_PROJECT_NAME" down
        print_success "Server stopped! Use the Gaming Mode launcher to start it next time."
    else
        print_info "Server left running — enjoy Azeroth! ⚔️"
    fi
    echo ""
}

# ─────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────
print_header

echo -e "${WHITE}Welcome to the WoW Playerbots installer!${NC}"
echo -e "${WHITE}${MIN_RANDOM_BOTS}-${MAX_RANDOM_BOTS} AI players will populate your Azeroth,${NC}"
echo -e "${WHITE}quest, run dungeons, and make the world feel alive.${NC}"
echo ""
echo -e "${BLUE}This takes about 5 minutes to set up, then${NC}"
echo -e "${BLUE}compiles itself over 2-4 hours. Plug in and walk away.${NC}"
echo ""

if ! ask_yes_no "Ready to begin?"; then
    echo "No problem — run this script when you're ready!"
    exit 0
fi

check_system

echo ""
show_summary
install_server
wait_for_server
create_accounts
setup_gaming_mode
show_completion
