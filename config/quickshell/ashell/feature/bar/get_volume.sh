#!/bin/sh
vol=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)
desc=$(wpctl inspect @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk -F'"' '/node.description/ {print $2; exit}')
if [ -z "$desc" ]; then
    desc=$(pactl get-default-sink 2>/dev/null)
fi
if [ -z "$desc" ]; then
    desc="Audio Output"
fi

if [ -n "$vol" ]; then
    echo "$vol" | awk -v d="$desc" '{
        pct = int($2 * 100);
        muted = ($0 ~ /MUTED/ ? "muted" : "on");
        printf "%d|%s|%s", pct, muted, d;
    }'
else
    # Fallback if wpctl is unavailable: try pactl
    pactl_vol=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | awk -F/ '/Volume:/ {print $2; exit}' | tr -d ' %')
    pactl_mute=$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | awk '{print ($2 == "yes" ? "muted" : "on")}')
    pct=${pactl_vol:-0}
    muted=${pactl_mute:-on}
    printf "%d|%s|%s" "$pct" "$muted" "$desc"
fi
