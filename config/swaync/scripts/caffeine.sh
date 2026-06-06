#!/usr/bin/env bash

set -euo pipefail

runtime_dir="${XDG_RUNTIME_DIR:-/tmp}"
pid_file="$runtime_dir/swaync-caffeine.pid"

notify() {
  command -v notify-send >/dev/null 2>&1 && notify-send -u low "Caffeine" "$1" || true
}

running() {
  [[ -f "$pid_file" ]] || return 1

  local pid
  pid="$(cat "$pid_file" 2>/dev/null || true)"
  [[ "$pid" =~ ^[0-9]+$ ]] || return 1
  kill -0 "$pid" >/dev/null 2>&1
}

cleanup_stale() {
  running || rm -f "$pid_file"
}

print_status() {
  cleanup_stale
  running && printf 'true\n' || printf 'false\n'
}

start_caffeine() {
  cleanup_stale
  running && return 0

  if command -v systemd-inhibit >/dev/null 2>&1; then
    nohup systemd-inhibit --what=idle:sleep --why="SwayNC caffeine" sleep infinity >/dev/null 2>&1 &
  else
    nohup sleep infinity >/dev/null 2>&1 &
  fi

  printf '%s\n' "$!" > "$pid_file"
  notify "On"
}

stop_caffeine() {
  cleanup_stale
  if running; then
    local pid
    pid="$(cat "$pid_file")"
    kill "$pid" >/dev/null 2>&1 || true
  fi

  rm -f "$pid_file"
  notify "Off"
}

toggle_caffeine() {
  case "${SWAYNC_TOGGLE_STATE:-}" in
    true)
      start_caffeine
      ;;
    false)
      stop_caffeine
      ;;
    *)
      if running; then
        stop_caffeine
      else
        start_caffeine
      fi
      ;;
  esac
}

case "${1:-}" in
  --is-running)
    print_status
    ;;
  --toggle|"")
    toggle_caffeine
    ;;
  *)
    printf 'Usage: %s [--is-running|--toggle]\n' "$0" >&2
    exit 2
    ;;
esac
