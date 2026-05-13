#!/usr/bin/env bash

set -euo pipefail

if ! command -v swaync-client >/dev/null 2>&1; then
  printf 'false\n'
  exit 0
fi

state="$(timeout 1s swaync-client --get-dnd 2>/dev/null || true)"

case "$state" in
  true|false)
    printf '%s\n' "$state"
    ;;
  *)
    printf 'false\n'
    ;;
esac
