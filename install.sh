#!/usr/bin/env bash

set -Eeuo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
HOME_DIR="${HOME:?HOME must be set to install dotfiles}"
STATE_DIR="$HOME_DIR/.local/state/dotfiles-installer"
BACKUP_BASE="$HOME_DIR/.local/state/dotfiles-backups"
LOG_FILE=""
BACKUP_DIR=""
INSTALL_PACKAGES=1

usage() {
    cat <<'USAGE'
Usage: ./install.sh [--no-packages]

Copies this repository's configuration and local files into the home directory.
By default, it also installs the package lists in packages/.

Options:
  --no-packages  Copy configuration files without installing packages
  -h, --help     Show this help
USAGE
}

log() {
    local level="$1"
    shift
    local line="$(date '+%Y-%m-%d %H:%M:%S') [$level] $*"
    printf '%s\n' "$line"
    if [[ -n "$LOG_FILE" ]]; then
        printf '%s\n' "$line" >> "$LOG_FILE"
    fi
}

run_logged() {
    "$@" 2>&1 | tee -a "$LOG_FILE"
}

on_error() {
    local line_number="$1"
    local status="$2"
    log ERROR "Installation stopped at script line $line_number (exit $status). See $LOG_FILE"
    exit "$status"
}

trap 'on_error "$LINENO" "$?"' ERR

while (($#)); do
    case "$1" in
        --no-packages)
            INSTALL_PACKAGES=0
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            printf 'Unknown option: %s\n' "$1" >&2
            usage >&2
            exit 2
            ;;
    esac
    shift
done

mkdir -p "$STATE_DIR"
LOG_FILE="$(mktemp "$STATE_DIR/install-$(date '+%Y%m%d-%H%M%S').XXXXXX")"
shopt -s dotglob nullglob
log INFO "Starting dotfiles setup from $REPO_DIR"
log INFO "Writing this run's log to $LOG_FILE"

# The Oh My Zsh directory is recorded as a submodule in this repository.
if [[ ! -f "$REPO_DIR/home/.oh-my-zsh/oh-my-zsh.sh" ]]; then
    log INFO "Initializing the Oh My Zsh submodule"
    git -C "$REPO_DIR" submodule update --init --recursive -- home/.oh-my-zsh
fi

if [[ ! -f "$REPO_DIR/home/.oh-my-zsh/oh-my-zsh.sh" ]]; then
    log ERROR "Oh My Zsh is missing. Initialize home/.oh-my-zsh before installing."
    exit 1
fi

if ((INSTALL_PACKAGES)); then
    if ! command -v pacman >/dev/null 2>&1; then
        log ERROR "pacman was not found; this package setup expects Arch Linux."
        exit 1
    fi
    if ((EUID != 0)) && ! command -v sudo >/dev/null 2>&1; then
        log ERROR "sudo is required to install packages as a non-root user."
        exit 1
    fi

    mapfile -t PACMAN_PACKAGES < <(sed -e 's/#.*//' -e '/^[[:space:]]*$/d' "$REPO_DIR/packages/pacman.txt")
    mapfile -t AUR_PACKAGES < <(sed -e 's/#.*//' -e '/^[[:space:]]*$/d' "$REPO_DIR/packages/aur.txt")

    if ((${#PACMAN_PACKAGES[@]})); then
        log INFO "Installing ${#PACMAN_PACKAGES[@]} official repository packages"
        if ((EUID == 0)); then
            run_logged pacman -S --needed "${PACMAN_PACKAGES[@]}"
        else
            run_logged sudo pacman -S --needed "${PACMAN_PACKAGES[@]}"
        fi
        log INFO "Official repository package installation finished"
    fi

    if ((${#AUR_PACKAGES[@]})); then
        AUR_HELPER=""
        if command -v yay >/dev/null 2>&1; then
            AUR_HELPER="yay"
        elif command -v paru >/dev/null 2>&1; then
            AUR_HELPER="paru"
        fi

        if [[ -z "$AUR_HELPER" ]]; then
            if ((EUID == 0)); then
                log ERROR "Run as a regular user to build the yay AUR helper."
                exit 1
            fi
            if ! command -v makepkg >/dev/null 2>&1 || ! command -v git >/dev/null 2>&1; then
                log ERROR "AUR packages are listed, but yay/paru, makepkg, or git is unavailable."
                exit 1
            fi
            BUILD_DIR="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-yay.XXXXXX")"
            log INFO "No AUR helper found; building yay in $BUILD_DIR"
            run_logged git clone https://aur.archlinux.org/yay.git "$BUILD_DIR/yay"
            run_logged bash -c 'cd "$1" && makepkg -si' _ "$BUILD_DIR/yay"
            rm -rf -- "$BUILD_DIR"
            if command -v yay >/dev/null 2>&1; then
                AUR_HELPER="yay"
            elif command -v paru >/dev/null 2>&1; then
                AUR_HELPER="paru"
            else
                log ERROR "The AUR helper build completed, but yay/paru was not found in PATH."
                exit 1
            fi
        fi

        log INFO "Installing ${#AUR_PACKAGES[@]} AUR packages with $AUR_HELPER"
        run_logged "$AUR_HELPER" -S --needed "${AUR_PACKAGES[@]}"
        log INFO "AUR package installation finished"
    fi
else
    log INFO "Skipping package installation (--no-packages)"
fi

backup_existing() {
    local target="$1"
    local relative_path="${target#"$HOME_DIR"/}"
    local backup_target

    if [[ -z "$BACKUP_DIR" ]]; then
        mkdir -p "$BACKUP_BASE"
        BACKUP_DIR="$(mktemp -d "$BACKUP_BASE/$(date '+%Y%m%d-%H%M%S').XXXXXX")"
        log INFO "Created backup directory $BACKUP_DIR"
    fi

    backup_target="$BACKUP_DIR/$relative_path"
    mkdir -p "$(dirname -- "$backup_target")"
    mv -- "$target" "$backup_target"
    log WARN "Moved existing path $target to $backup_target"
}

copy_entry() {
    local source="$1"
    local target="$2"
    local child

    if [[ -d "$source" && ! -L "$source" ]]; then
        if [[ -L "$target" || ( -e "$target" && ! -d "$target" ) ]]; then
            backup_existing "$target"
        fi
        mkdir -p "$target"
        for child in "$source"/*; do
            [[ -e "$child" || -L "$child" ]] || continue
            case "${child##*/}" in
                .git|.agents|.codex) continue ;;
            esac
            copy_entry "$child" "$target/${child##*/}"
        done
        return
    fi

    if [[ -f "$source" && -f "$target" && ! -L "$source" && ! -L "$target" ]] && cmp -s -- "$source" "$target"; then
        return
    fi
    if [[ -L "$source" && -L "$target" ]] && [[ "$(readlink -- "$source")" == "$(readlink -- "$target")" ]]; then
        return
    fi

    if [[ -e "$target" || -L "$target" ]]; then
        backup_existing "$target"
    fi
    mkdir -p "$(dirname -- "$target")"
    run_logged cp -a -- "$source" "$target"
}

copy_tree() {
    local source="$1"
    local target="$2"

    if [[ ! -e "$source" ]]; then
        log WARN "Skipping missing source $source"
        return
    fi
    log INFO "Copying $source to $target"
    copy_entry "$source" "$target"
}

for source in "$REPO_DIR"/config/*; do
    [[ -d "$source" ]] || continue
    copy_tree "$source" "$HOME_DIR/.config/${source##*/}"
done

copy_tree "$REPO_DIR/local/bin" "$HOME_DIR/.local/bin"
copy_tree "$REPO_DIR/local/share/easyeffects" "$HOME_DIR/.local/share/easyeffects"
copy_tree "$REPO_DIR/vendor/spicetify-themes" "$HOME_DIR/.config/spicetify/Themes"

for name in .zshrc .p10k.zsh .oh-my-zsh; do
    copy_tree "$REPO_DIR/home/$name" "$HOME_DIR/$name"
done

log INFO "Dotfiles setup completed successfully"
log INFO "Review the full run log at $LOG_FILE"
if [[ -n "$BACKUP_DIR" ]]; then
    log INFO "Previous files are backed up at $BACKUP_DIR"
fi
