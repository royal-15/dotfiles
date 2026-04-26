#!/usr/bin/env bash

set -euo pipefail

if pgrep -x waybar >/dev/null 2>&1; then
    pkill -SIGUSR2 -x waybar
else
    "$(dirname "$0")/launch.sh"
fi
