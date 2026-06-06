#!/usr/bin/env bash

set -euo pipefail

close_panel() {
  command -v swaync-client >/dev/null 2>&1 && swaync-client -cp >/dev/null 2>&1 || true
}

script="$HOME/.config/theme-switcher/scripts/theme_switcher_menu.sh"

close_panel

if [[ -x "$script" ]]; then
  "$script" || true
  exit 0
fi

if [[ -f "$script" ]]; then
  bash "$script" || true
  exit 0
fi

command -v notify-send >/dev/null 2>&1 && notify-send -u low "Theme Menu" "Theme switcher menu was not found" || true
