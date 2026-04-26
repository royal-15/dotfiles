#!/usr/bin/env bash

set -euo pipefail

temp_raw="$(
    sensors 2>/dev/null | awk '
        /Package id 0:/ { print $4; exit }
        /Tctl:/ { print $2; exit }
        /Tdie:/ { print $2; exit }
    '
)"

temp="${temp_raw#+}"
temp="${temp%°C}"
temp="${temp%%.*}"

if [[ -z "$temp" || ! "$temp" =~ ^[0-9]+$ ]]; then
    printf '{"text":"󰔄 --","tooltip":"CPU temperature unavailable","class":["unknown"]}\n'
    exit 0
fi

state="normal"
icon="󰔏"
if (( temp >= 90 )); then
    state="critical"
    icon="󰸁"
elif (( temp >= 80 )); then
    state="hot"
    icon="󰔄"
elif (( temp >= 70 )); then
    state="warm"
    icon="󱃂"
fi

printf '{"text":"%s %s°","tooltip":"CPU temperature: %s°C","class":["%s"],"percentage":%s}\n' \
    "$icon" "$temp" "$temp" "$state" "$temp"
