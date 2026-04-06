#!/bin/bash

WALL_DIR=~/Wallpapers

while true; do
  IMG=$(find "$WALL_DIR" -type f | shuf -n 1)
  awww img "$IMG" --transition-type wipe --transition-duration 1
  sleep 300   # change every 5 minutes
done
