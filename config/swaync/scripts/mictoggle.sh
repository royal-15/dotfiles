#!/usr/bin/env bash

set -euo pipefail

notify() {
  [[ "${1:-}" == "--silent" ]] && return 0
  command -v notify-send >/dev/null 2>&1 && notify-send -u low "Microphone" "$2" || true
}

is_muted() {
  if command -v pactl >/dev/null 2>&1; then
    pactl get-source-mute @DEFAULT_SOURCE@ 2>/dev/null | grep -qi 'yes'
    return
  fi

  if command -v wpctl >/dev/null 2>&1; then
    wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null | grep -qi 'MUTED'
    return
  fi

  return 1
}

set_mute() {
  local state="$1"

  if command -v pactl >/dev/null 2>&1; then
    pactl set-source-mute @DEFAULT_SOURCE@ "$state" >/dev/null 2>&1
    return 0
  fi

  if command -v wpctl >/dev/null 2>&1; then
    if [[ "$state" == "1" ]]; then
      wpctl set-mute @DEFAULT_AUDIO_SOURCE@ 1 >/dev/null 2>&1
    else
      wpctl set-mute @DEFAULT_AUDIO_SOURCE@ 0 >/dev/null 2>&1
    fi
    return 0
  fi

  return 1
}

print_status() {
  is_muted && printf 'true\n' || printf 'false\n'
}

toggle_mute() {
  local silent="${1:-}"
  local desired="${SWAYNC_TOGGLE_STATE:-}"

  if [[ "$desired" != "true" && "$desired" != "false" ]]; then
    if is_muted; then
      desired="false"
    else
      desired="true"
    fi
  fi

  if [[ "$desired" == "true" ]]; then
    set_mute 1 || return 0
    notify "$silent" "Muted"
  else
    set_mute 0 || return 0
    notify "$silent" "Unmuted"
  fi
}

case "${1:-}" in
  --is-muted)
    print_status
    ;;
  --toggle|--silent|"")
    toggle_mute "${1:-}"
    ;;
  *)
    printf 'Usage: %s [--is-muted|--toggle|--silent]\n' "$0" >&2
    exit 2
    ;;
esac
