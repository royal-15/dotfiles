#!/usr/bin/env bash

set -euo pipefail

ROFI_THEME_SELECTION="${HOME}/.config/rofi/themes/applets/selector-medium.rasi"
ROFI_THEME_CONFIRMATION="${HOME}/.config/rofi/themes/applets/selector-compact.rasi"

is_connected() {
    bluetoothctl info "$1" 2>/dev/null |
        grep -q "Connected: yes"
}

get_device_name() {
    bluetoothctl info "$1" 2>/dev/null |
        awk -F ': ' '/^Name:/ {print $2; exit}'
}

# Ensure Bluetooth is powered on.
power_state="$(
    bluetoothctl show 2>/dev/null |
        awk -F ': ' '/^Powered:/ {print $2; exit}'
)"

if [[ "$power_state" != "yes" ]]; then
    bluetoothctl power on >/dev/null 2>&1
fi

declare -A DEVICE_MACS

connected_devices=()
disconnected_devices=()

# Get known Bluetooth devices.
while read -r _ mac name; do
    [[ -z "${mac:-}" || -z "${name:-}" ]] && continue

    if is_connected "$mac"; then
        entry="󰂱  ${name}"
        connected_devices+=("$entry")
    else
        entry="${name}"
        disconnected_devices+=("$entry")
    fi

    DEVICE_MACS["$entry"]="$mac"

done < <(bluetoothctl devices)

devices=(
    "${connected_devices[@]}"
    "${disconnected_devices[@]}"
)

if [[ ${#devices[@]} -eq 0 ]]; then
    # rofi \
    #     -e "No Bluetooth devices found." \
    #     -theme "$ROFI_THEME_SELECTION"

    notify-send "Bluetooth" "No Bluetooth devices found."

    exit 0
fi

chosen="$(
    printf '%s\n' "${devices[@]}" |
        rofi \
            -dmenu \
            -i \
            -p "Bluetooth" \
            -mesg "Select a device to connect or disconnect" \
            -theme "$ROFI_THEME_SELECTION"
)"

[[ -z "$chosen" ]] && exit 0

mac="${DEVICE_MACS[$chosen]:-}"

[[ -z "$mac" ]] && exit 0

device_name="$(get_device_name "$mac")"

# Fallback in case bluetoothctl info does not return a name.
[[ -z "$device_name" ]] && device_name="$chosen"

# Connected device -> confirm before disconnecting.
if is_connected "$mac"; then

    confirm="$(
        printf "No\nYes\n" |
            rofi \
                -dmenu \
                -i \
                -selected-row 0 \
                -p "Disconnect" \
                -mesg "Disconnect from ${device_name}?" \
                -theme "$ROFI_THEME_SELECTION"
    )"

    [[ "$confirm" != "Yes" ]] && exit 0

    bluetoothctl disconnect "$mac" >/dev/null 2>&1 || true

    # Verify actual state instead of parsing command output.
    if ! is_connected "$mac"; then
        notify-send \
            "Bluetooth Disconnected" \
            "$device_name"
    else
        notify-send \
            "Bluetooth Disconnection Failed" \
            "$device_name"
    fi

    exit 0
fi

notify-send \
    "Bluetooth" \
    "connecting to device: $device_name"

# Disconnected device -> connect.
bluetoothctl connect "$mac" >/dev/null 2>&1 || true

# Verify actual connection state.
if is_connected "$mac"; then
    notify-send \
        "Bluetooth Connected" \
        "$device_name"
else
    notify-send \
        "Bluetooth Connection Failed" \
        "$device_name"
fi