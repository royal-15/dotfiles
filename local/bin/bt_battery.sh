#!/usr/bin/env bash

sink=$(pactl list sinks short | grep bluez_output | head -n1)

if [[ -z "$sink" ]]; then
    echo '{"text":"","class":"disconnected"}'
    exit 0
fi

mac=$(echo "$sink" | grep -oE '([A-F0-9]{2}_){5}[A-F0-9]{2}' | tr '_' ':')

device=$(bluetoothctl devices Connected | grep -i "$mac")
name=$(echo "$device" | cut -d' ' -f4-)

upower_device=$(upower -e | grep -i "${mac//:/_}")

battery=$(upower -i "$upower_device" 2>/dev/null | awk '/percentage:/ {gsub("%","",$2); print $2}')

# Default values
class="normal"
text="$name"

if [[ -n "$battery" ]]; then
    if (( battery <= 20 )); then
        class="critical"
    elif (( battery <= 50 )); then
        class="warn"
    fi

    text="$name ${battery}%"
fi

printf '{"text":"%s","class":"%s","tooltip":"%s"}\n' \
    "$text" \
    "$class" \
    "$text"