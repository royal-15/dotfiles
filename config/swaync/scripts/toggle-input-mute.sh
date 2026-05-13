#!/usr/bin/env bash

set -euo pipefail

if [[ "${SWAYNC_TOGGLE_STATE:-false}" == "true" ]]; then
  exec pamixer --default-source --mute
fi

exec pamixer --default-source --unmute
