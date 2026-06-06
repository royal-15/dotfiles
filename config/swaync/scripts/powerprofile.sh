#!/usr/bin/env bash

set -euo pipefail

notify() {
  command -v notify-send >/dev/null 2>&1 && notify-send -u low "Power Profile" "$1" || true
}

current_profile() {
  powerprofilesctl get 2>/dev/null || printf 'unknown\n'
}

profile_available() {
  powerprofilesctl list 2>/dev/null | grep -qE "^[* ]*[[:space:]]*$1:"
}

print_is_quiet() {
  if ! command -v powerprofilesctl >/dev/null 2>&1; then
    printf 'false\n'
    return
  fi

  [[ "$(current_profile)" == "power-saver" ]] && printf 'true\n' || printf 'false\n'
}

toggle_quiet() {
  if ! command -v powerprofilesctl >/dev/null 2>&1; then
    notify "powerprofilesctl is not installed"
    return 0
  fi

  local current next
  current="$(current_profile)"

  if [[ "${SWAYNC_TOGGLE_STATE:-}" == "true" ]]; then
    next="power-saver"
  elif [[ "${SWAYNC_TOGGLE_STATE:-}" == "false" ]]; then
    next="balanced"
  elif [[ "$current" == "power-saver" ]]; then
    next="balanced"
  else
    next="power-saver"
  fi

  if ! profile_available "$next"; then
    next="balanced"
  fi

  powerprofilesctl set "$next" >/dev/null 2>&1 || {
    notify "Could not switch to $next"
    return 0
  }

  notify "$next"
}

case "${1:-}" in
  --is-quiet)
    print_is_quiet
    ;;
  --toggle-quiet|--toggle|"")
    toggle_quiet
    ;;
  *)
    printf 'Usage: %s [--is-quiet|--toggle-quiet]\n' "$0" >&2
    exit 2
    ;;
esac
