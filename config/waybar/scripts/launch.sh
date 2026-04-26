#!/usr/bin/env bash

set -euo pipefail

pkill -x waybar 2>/dev/null || true
pkill -x swaync 2>/dev/null || true

sleep 0.2

env -u DISPLAY GDK_BACKEND=wayland waybar >/dev/null 2>&1 &
swaync >/dev/null 2>&1 &
