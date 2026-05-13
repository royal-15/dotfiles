#!/usr/bin/env bash

set -euo pipefail

if [[ "${SWAYNC_TOGGLE_STATE:-false}" == "true" ]]; then
  exec pamixer --mute
fi

exec pamixer --unmute
