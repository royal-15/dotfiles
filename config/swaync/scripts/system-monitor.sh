#!/usr/bin/env bash

set -euo pipefail

close_panel() {
  command -v swaync-client >/dev/null 2>&1 && swaync-client -cp >/dev/null 2>&1 || true
}

notify_missing() {
  command -v notify-send >/dev/null 2>&1 && notify-send -u low "System Monitor" "$1" || true
}

pick_first() {
  local cmd
  for cmd in "$@"; do
    command -v "$cmd" >/dev/null 2>&1 && {
      printf '%s\n' "$cmd"
      return 0
    }
  done
  return 1
}

terminal="$(pick_first alacritty kitty foot wezterm ghostty xterm || true)"
monitor="$(pick_first htop btop top || true)"

close_panel

if [[ -z "$terminal" || -z "$monitor" ]]; then
  notify_missing "No supported terminal or monitor command found"
  exit 0
fi

if command -v hyprctl >/dev/null 2>&1; then
  hyprctl dispatch exec "$terminal -e $monitor" >/dev/null 2>&1 || true
else
  nohup "$terminal" -e "$monitor" >/dev/null 2>&1 &
fi
