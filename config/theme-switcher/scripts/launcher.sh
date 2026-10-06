#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# source "$SCRIPT_DIR/state_utils.sh"

# load_state

source "$ROOT_DIR/state/active_theme.env"


LAUNCHERS_DIR="$HOME/.config/rofi/themes/launchers"

## Run
rofi \
    -show drun \
    -theme "$LAUNCHERS_DIR/${ACTIVE_LAUNCHER}.rasi"
