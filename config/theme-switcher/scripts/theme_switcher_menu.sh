#!/usr/bin/env bash

set -euo pipefail

# =========================================================
# Paths
# =========================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

THEME_SWITCHER="$SCRIPT_DIR/theme_switcher"

STATE_FILE="$ROOT_DIR/state/active_theme.env"
SPOTIFY_THEMES_FILE="$ROOT_DIR/scripts/spotify_themes.tsv"

# shellcheck source=state_utils.sh
source "$SCRIPT_DIR/state_utils.sh"

load_state

THEMES_DIR="$ROOT_DIR/themes"
WAYBAR_DIR="$ROOT_DIR/layouts/waybars"
WALLPAPERS_DIR="$THEMES_DIR/$ACTIVE_THEME/wallpapers"

# =========================================================
# Helpers
# =========================================================

list_subfolders() {
    local dir="$1"

    find "$dir" \
        -mindepth 1 \
        -maxdepth 1 \
        -type d \
        -printf '%f\n' |
        sort
}

list_files_of_type() {
    local dir="$1"
    shift

    [[ -d "$dir" ]] || return 1
    (($# > 0)) || return 0

    local find_args=()
    local ext

    for ext in "$@"; do
        find_args+=(-iname "*.${ext}" -o)
    done

    unset 'find_args[${#find_args[@]}-1]'

    find "$dir" \
        -mindepth 1 \
        -maxdepth 1 \
        -type f \
        \( "${find_args[@]}" \) \
        -print0 |
    sort -z |
    while IFS= read -r -d '' path; do
        printf '%s\0icon\x1f%s\n' \
            "$(basename "$path")" \
            "$path"
    done
}

list_spotify_themes(){
    # while IFS=$'\t' read -r theme scheme; do
    #     echo "$theme-$scheme"
    # done < "$SPOTIFY_THEMES"
    cat "$SPOTIFY_THEMES_FILE"
}

show_menu() {
    rofi \
        -dmenu \
        -i \
        -p "$1" \
        -theme "$HOME/.config/rofi/themes/applets/selector-medium.rasi"
}

show_image_menu() {
    rofi \
        -dmenu \
        -i \
        -show-icons \
        -p "$1" \
        -theme "$HOME/.config/rofi/themes/applets/image-selector.rasi"
}

# =========================================================
# Aspect Selection
# =========================================================

SELECTED_ASPECT=$(
    printf '%s\n' \
        theme \
        wallpaper \
        waybar \
        spotify |
        show_menu "Aspect"
)

[[ -n "${SELECTED_ASPECT:-}" ]] || exit 0

# =========================================================
# Value Selection
# =========================================================

case "$SELECTED_ASPECT" in
    theme)
        FINAL_SELECTION=$(
            list_subfolders "$THEMES_DIR" |
                show_menu "Theme"
        )
        ;;
    wallpaper)
        FINAL_SELECTION=$(
            list_files_of_type \
                "$WALLPAPERS_DIR" \
                jpg jpeg png webp |
                show_image_menu "Wallpaper"
        )
        ;;
    waybar)
        FINAL_SELECTION=$(
            list_subfolders "$WAYBAR_DIR" |
                show_menu "Waybar"
        )
        ;;
    spotify)
        FINAL_SELECTION=$(
            list_spotify_themes |
                show_menu "Spotify"
        )
        ;;
    *)
        exit 1
        ;;
esac

[[ -n "${FINAL_SELECTION:-}" ]] || exit 0

# =========================================================
# Apply Selection
# =========================================================

"$THEME_SWITCHER" switch "$SELECTED_ASPECT" "$FINAL_SELECTION"