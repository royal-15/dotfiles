#!/usr/bin/env bash

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

show_menu() {
    local prompt="$1"

    local selected_label="${2:-}"
    local menu
    local selected_index=""

    menu=$(cat)

    if [[ -n "$selected_label" ]]; then
        selected_index=$(printf '%s\n' "$menu" | awk -v label="$selected_label" '
            $0 == label { print NR - 1; exit }
        ')
    fi

    if [[ -n "$selected_index" ]]; then
        printf '%s\n' "$menu" | rofi \
            -dmenu \
            -i \
            -p "$prompt" \
            -selected-row "$selected_index" \
            -theme "$HOME/.config/rofi/themes/applets/selector-medium.rasi"
    else
        printf '%s\n' "$menu" | rofi \
            -dmenu \
            -i \
            -p "$prompt" \
            -theme "$HOME/.config/rofi/themes/applets/selector-medium.rasi"
    fi
}

show_image_menu() {
    rofi \
        -dmenu \
        -i \
        -show-icons \
        -p "$1" \
        -theme "$HOME/.config/rofi/themes/applets/image-selector.rasi"
}
