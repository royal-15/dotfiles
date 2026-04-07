#!/usr/bin/env bash

set -euo pipefail

# Get current mode
current="$(powerprofilesctl get 2>/dev/null || echo balanced)"

# Define options (order matters)
options=("power-saver" "balanced" "performance")
# options=("  power-saver" "  balanced" " performance")

# Map current → index
selected_index=1  # default = balanced

for i in "${!options[@]}"; do
    if [[ "${options[$i]}" == "$current" ]]; then
        selected_index="$i"
        break
    fi
done

# Show rofi with preselected row
selection="$(
    printf '%s\n' "${options[@]}" \
        | rofi -dmenu \
            -p "Power mode" \
            -selected-row "$selected_index" \
            -theme "$HOME/.config/rofi/vendor-adi1090x/applets/type-2/style-3.rasi"
)"

[ -z "$selection" ] && exit 0

powerprofilesctl set "$selection"

# refresh waybar
pkill -RTMIN+8 waybar
