#!/bin/bash

# Blur Wallpaper Script for Hyprlock
# This script gets the current wallpaper and creates a blurred version for the lock screen

WALLPAPER_DIR=$HOME/Wallpapers
OUTPUT_DIR=$HOME/.config/hypr/hyprlock/assets
OUTPUT_FILE="$OUTPUT_DIR/blurred_wallpaper.png"
BLUR_STRENGTH=15  # Default blur radius

# Get wallpaper from argument or find current one
CURRENT_WALLPAPER="${1}"

# If no wallpaper provided as argument, try to find one
if [[ -z "$CURRENT_WALLPAPER" ]]; then
    # Try to find the most recently modified wallpaper
    CURRENT_WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" \) -print0 2>/dev/null | xargs -0 ls -t 2>/dev/null | head -1)
fi

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

if [[ -z "$CURRENT_WALLPAPER" ]] || [[ ! -f "$CURRENT_WALLPAPER" ]]; then
    echo "Error: Could not find current wallpaper"
    exit 1
fi

echo "Processing wallpaper: $CURRENT_WALLPAPER"

# Create blurred version using ImageMagick
if command -v magick &> /dev/null; then
    # ImageMagick 7+
    magick "$CURRENT_WALLPAPER" \
        -blur "0x${BLUR_STRENGTH}" \
        "$OUTPUT_FILE"
elif command -v convert &> /dev/null; then
    # ImageMagick 6
    convert "$CURRENT_WALLPAPER" \
        -blur "0x${BLUR_STRENGTH}" \
        "$OUTPUT_FILE"
else
    echo "Error: ImageMagick not found. Please install it with: sudo pacman -S imagemagick"
    exit 1
fi

if [[ -f "$OUTPUT_FILE" ]]; then
    echo "Successfully created blurred wallpaper: $OUTPUT_FILE"
else
    echo "Error: Failed to create blurred wallpaper"
    exit 1
fi
