#!/usr/bin/env bash

set -euo pipefail

command -v swaync-client >/dev/null 2>&1 && swaync-client -cp >/dev/null 2>&1 || true

notify() {
  command -v notify-send >/dev/null 2>&1 && notify-send -u low "Session" "$1" || true
}

if ! command -v rofi >/dev/null 2>&1; then
  notify "rofi is not installed"
  exit 0
fi

choice="$(
  printf '%s\n' "Lock" "Logout" "Suspend" "Reboot" "Shutdown" |
    rofi -dmenu -i -p "Session" -theme "$HOME/.config/rofi/themes/applets/selector-medium.rasi" || true
)"

case "$choice" in
  Lock)
    if command -v hyprlock >/dev/null 2>&1; then
      hyprlock
    elif command -v swaylock >/dev/null 2>&1; then
      swaylock
    else
      notify "No lock command found"
    fi
    ;;
  Logout)
    if command -v hyprctl >/dev/null 2>&1; then
      hyprctl dispatch exit >/dev/null 2>&1 || true
    else
      notify "No compositor logout command found"
    fi
    ;;
  Suspend)
    systemctl suspend
    ;;
  Reboot)
    systemctl reboot
    ;;
  Shutdown)
    systemctl poweroff
    ;;
  "" )
    exit 0
    ;;
esac
