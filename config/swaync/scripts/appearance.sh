#!/usr/bin/env bash

set -euo pipefail

command -v swaync-client >/dev/null 2>&1 && swaync-client -cp >/dev/null 2>&1 || true

if ! command -v nwg-look >/dev/null 2>&1; then
  command -v notify-send >/dev/null 2>&1 && notify-send -u low "Appearance" "nwg-look is not installed" || true
  exit 0
fi

if command -v hyprctl >/dev/null 2>&1; then
  hyprctl dispatch exec nwg-look >/dev/null 2>&1 || true
else
  nohup nwg-look >/dev/null 2>&1 &
fi
