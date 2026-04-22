#!/usr/bin/env bash

set -euo pipefail

# Get current mode
current="$(powerprofilesctl get 2>/dev/null || echo balanced)"

# Define modes and icons (order matters)
modes=("power-saver" "balanced" "performance")
icons=(" " " " "")

# Map current → index
selected_index=1  # default = balanced

for i in "${!modes[@]}"; do
    if [[ "${modes[$i]}" == "$current" ]]; then
        selected_index="$i"
        break
    fi
done

# Show rofi with preselected row
selection="$(
    printf '%s\n' "${icons[@]}" \
        | rofi -dmenu \
            -p "Power mode" \
            -selected-row "$selected_index" \
            -theme "$HOME/.config/rofi/themes/applets/selector-compact.rasi"
)"

[ -z "$selection" ] && exit 0

# Map selection back to mode
for i in "${!icons[@]}"; do
    if [[ "${icons[$i]}" == "$selection" ]]; then
        powerprofilesctl set "${modes[$i]}"
        break
    fi
done

# refresh waybar
pkill -RTMIN+8 waybar
