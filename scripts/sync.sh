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
sync .config/swaync config/swaync
sync .config/waybar config/waybar
sync .config/wlogout config/wlogout
sync .config/Thunar config/Thunar

sync .config/cava config/cava
sync .config/kew config/kew
sync .config/spicetify config/spicetify

sync .config/Kvantum config/Kvantum
sync .config/qt5ct config/qt5ct
sync .config/qt6ct config/qt6ct

sync .config/gtk-3.0 config/gtk-3.0
sync .config/gtk-4.0 config/gtk-4.0
sync .config/nwg-look config/nwg-look

sync .config/theme-switcher config/theme-switcher

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

pacman -Qqen > "$PACKAGES_DIR/pacman.txt"
pacman -Qqem > "$PACKAGES_DIR/aur.txt"

echo "[*] Sync complete."
