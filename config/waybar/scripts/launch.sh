#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_PATH="${SCRIPT_DIR}/../config.jsonc"
LOG_PATH="${XDG_RUNTIME_DIR:-/tmp}/waybar-theme-switcher.log"

launch_waybar() {
    pkill -x waybar 2>/dev/null || true
    sleep 0.2

    nohup env -u DISPLAY GDK_BACKEND=wayland waybar -c "${CONFIG_PATH}" >"${LOG_PATH}" 2>&1 &
}

start_swaync() {
    if ! pgrep -x swaync >/dev/null 2>&1; then
        swaync >/dev/null 2>&1 &
    fi
}

main() {
    launch_waybar
    start_swaync
}

main
