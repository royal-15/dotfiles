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
source "$SCRIPT_DIR/theme_switcher_utils.sh"

load_state

THEMES_DIR="$ROOT_DIR/themes"
WAYBAR_DIR="$ROOT_DIR/layouts/waybars"
WALLPAPERS_DIR="$THEMES_DIR/$ACTIVE_THEME/wallpapers"
LAUNCHERS_DIR="$HOME/.config/rofi/themes/launchers"

# =========================================================
# Helpers
# =========================================================

list_spotify_themes(){
    cat "$SPOTIFY_THEMES_FILE"
}

list_launchers(){
    ls "$LAUNCHERS_DIR" | sed 's/\.[^.]*$//'
}

# =========================================================
# Aspect Selection
# =========================================================

SELECTED_ASPECT=$(
    printf '%s\n' \
        theme \
        wallpaper \
        waybar \
        launcher \
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
                show_menu "Theme" "$ACTIVE_THEME"
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
                show_menu "Waybar" "$ACTIVE_WAYBAR_LAYOUT"
        )
        ;;
    launcher)
        FINAL_SELECTION=$(
            list_launchers |
                show_menu "Launcher" "$ACTIVE_LAUNCHER"
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