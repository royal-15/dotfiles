#!/bin/bash

STATE_FILE="/tmp/brightness_value"
STEP=0.05

get() {
    [ -f "$STATE_FILE" ] && cat "$STATE_FILE" || echo 1.0
}

set_val() {
    echo "$1" > "$STATE_FILE"
    pkill wlsunset
    wlsunset -g "$1" &
}

case "$1" in
    up)
        val=$(get)
        new=$(awk "BEGIN {print ($val + $STEP)}")
        [ "$(awk "BEGIN {print ($new > 1.0)}")" -eq 1 ] && new=1.0
        set_val $new
        ;;
    down)
        val=$(get)
        new=$(awk "BEGIN {print ($val - $STEP)}")
        [ "$(awk "BEGIN {print ($new < 0.3)}")" -eq 1 ] && new=0.3
        set_val $new
        ;;
    *)
        echo "Usage: up/down"
        ;;
esac

