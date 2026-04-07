#!/usr/bin/env bash
set -euo pipefail

# Get mode (fallback to balanced if fails)
mode="$(powerprofilesctl get 2>/dev/null || echo balanced)"

case "$mode" in
    power-saver) icon=" " ;;
    performance) icon="" ;;
    *) mode="balanced"; icon=" " ;;
esac

# Read battery directly (no loop)
capacity="$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || echo "--")"

printf '{"text":"%s %s%%","tooltip":"Mode: %s","class":"%s"}\n' \
    "$icon" "$capacity" "$mode" "$mode"