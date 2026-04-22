#!/bin/bash

set -e

DOTFILES_DIR="$HOME/dotfiles"

sync() {
    src="$HOME/$1"
    dest="$DOTFILES_DIR/$2"

    if [ -d "$src" ]; then
        # Directory sync
        mkdir -p "$dest"
        rsync -a --delete "$src/" "$dest/"
    elif [ -f "$src" ]; then
        # File sync
        mkdir -p "$(dirname "$dest")"
        rsync -a "$src" "$dest"
    else
        echo "sync: source not found -> $src"
        return 1
    fi
}

echo "[*] Sync started..."

# assets
echo "[*] Syncing assets..."

sync Wallpapers assets/Wallpapers

# configs
echo "[*] Syncing configs..."

sync .config/hypr config/hypr
sync .config/kitty config/kitty
sync .config/rofi config/rofi
sync .config/waybar config/waybar

# local
echo "[*] Syncing local..."

sync .local/bin local/bin

# home
echo "[*] Syncing home..."

sync .zshrc home/.zshrc
sync .oh-my-zsh home/.oh-my-zsh
sync .p10k.zsh home/.p10k.zsh

# packages
echo "[*] Syncing packages..."

PACKAGES_DIR="$DOTFILES_DIR/packages"
mkdir -p "$PACKAGES_DIR"

pacman -Qqe > "$PACKAGES_DIR/pacman.txt"
pacman -Qqem > "$PACKAGES_DIR/aur.txt"

echo "[*] Sync complete."