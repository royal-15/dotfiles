#!/usr/bin/env bash

set -euo pipefail

if ! command -v swaync-client >/dev/null 2>&1; then
  exit 0
fi

desired_state="${SWAYNC_TOGGLE_STATE:-}"

if [[ "$desired_state" != "true" && "$desired_state" != "false" ]]; then
  current_state="$(timeout 1s swaync-client --get-dnd 2>/dev/null || true)"
  if [[ "$current_state" == "true" ]]; then
    desired_state="false"
  else
    desired_state="true"
  fi
fi

if [[ "$desired_state" == "true" ]]; then
  timeout 1s swaync-client --dnd-on >/dev/null 2>&1 || true
  exit 0
fi

timeout 1s swaync-client --dnd-off >/dev/null 2>&1 || true
