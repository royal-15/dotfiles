#!/bin/bash

WALL_DIR=$HOME/Wallpapers
BLUR_SCRIPT=$HOME/.config/hypr/scripts/blur_wallpaper.sh

while true; do
  IMG=$(find "$WALL_DIR" -type f ! -name "*.py" | shuf -n 1)
  awww img "$IMG" --transition-type wipe --transition-duration 1
  
  # Generate blurred version for lock screen with the exact wallpaper
  sleep 1  # Brief delay to ensure wallpaper is set
  bash "$BLUR_SCRIPT" "$IMG"
 
  # Generate wal colors
  # wal -i "$IMG"

  sleep 300   # change every 5 minutes
done
