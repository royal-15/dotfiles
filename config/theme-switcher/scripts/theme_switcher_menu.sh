#!/usr/bin/env bash

set -euo pipefail

# =========================================================
# Config
# =========================================================

scripts_dir=$(dirname "${BASH_SOURCE[0]}")
state_manager="$scripts_dir/state_manager"
theme_switcher="$scripts_dir/theme_switcher"

current_theme="$($state_manager get theme)"
current_wallpaper="$($state_manager get wallpaper)"
current_waybar="$($state_manager get waybar)"

echo "current theme: $current_theme"
echo "current wallpaper: $current_wallpaper"
echo "current waybar: $current_waybar"

THEMES_DIR="$HOME/.config/theme-switcher/themes"

WALLPAPERS_DIR="$HOME/.config/theme-switcher/themes/$current_theme/wallpapers"

WAYBAR_DIR="$HOME/.config/theme-switcher/layouts/waybars"

# =========================================================
# Helpers
# =========================================================

list_subfolders() {
    local dir="$1"

    find "$dir" \
        -mindepth 1 \
        -maxdepth 1 \
        -type d \
        -printf "%f\n" \
        | sort
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

show_menu() {
    rofi -dmenu -i -p "$1" -theme "$HOME/.config/rofi/themes/applets/selector-medium.rasi"
}

show_image_menu() {
    rofi -dmenu -i -p "$1" -show-icons -theme "$HOME/.config/rofi/themes/applets/image-selector.rasi"
}

# =========================================================
# Main Menu
# =========================================================

theme_aspects=(
    "theme"
    "wallpaper"
    "waybar_layout"
)

selected_aspect=$(
    printf "%s\n" "${theme_aspects[@]}" \
    | show_menu "Select Aspect"
)

[ -z "${selected_aspect:-}" ] && exit 0

# =========================================================
# Selection Logic
# =========================================================

final_selection=""

case "$selected_aspect" in
    "theme")
        final_selection=$(
            list_subfolders "$THEMES_DIR" \
            | show_menu "Select Theme"
        )
        ;;
    
    "wallpaper")
        final_selection=$(
            list_files_of_type "$WALLPAPERS_DIR" jpg jpeg png webp | show_image_menu "Select Wallpaper"
        )
        ;;
    
    "waybar_layout")
        final_selection=$(
            list_subfolders "$WAYBAR_DIR" \
            | show_menu "Select Waybar"
        )
        ;;
esac

[ -z "${final_selection:-}" ] && exit 0

# =========================================================
# Result
# =========================================================

echo "Selected Aspect: $selected_aspect"
echo "Final Selection: $final_selection"

$theme_switcher switch "$selected_aspect" "$final_selection"
