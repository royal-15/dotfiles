#!/usr/bin/env bash
set -euo pipefail

mode="$(powerprofilesctl get 2>/dev/null || echo balanced)"

case "$mode" in
    power-saver) mode_icon=" "; mode_label="Power Saver" ;;
    performance) mode_icon=" "; mode_label="Performance" ;;
    *) mode="balanced"; mode_label="Balanced"; mode_icon="󰾆 " ;;
esac

battery_path="/sys/class/power_supply/BAT0"
capacity="$(cat "$battery_path/capacity" 2>/dev/null || echo "--")"
status="$(cat "$battery_path/status" 2>/dev/null || echo "Unknown")"

classes=("$mode")
level="unknown"
percentage=0

if [[ "$status" == "Charging" ]]; then
    classes+=("charging")
fi

if [[ "$capacity" =~ ^[0-9]+$ ]]; then
    percentage="$capacity"
    level="normal"

    if (( capacity <= 15 )); then
        level="critical"
        battery_icon="󰂃"
    elif (( capacity <= 35 )); then
        level="warning"
        battery_icon="󰂃"
    elif (( capacity <= 55 )); then
        battery_icon="󰂄"
    elif (( capacity <= 75 )); then
        battery_icon="󰂀"
    else
        level="normal"
        battery_icon="󰁹"
    fi
else
    capacity="--"
    battery_icon="󰂑"
fi

if [[ "$status" == "Charging" ]]; then
    battery_icon="󰂄"
fi

classes+=("$level")

class_json=$(printf '"%s",' "${classes[@]}")
class_json="[${class_json%,}]"
tooltip="Profile: ${mode_label}\\nBattery: ${capacity}% (${status})"

printf -v text '%s %s%%' "$mode_icon" "$capacity"

printf '{"text":"%s","tooltip":"%s","class":%s,"percentage":%s}\n' \
    "$text" "$tooltip" "$class_json" "$percentage"
