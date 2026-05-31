#!/bin/bash

set -euo pipefail

INPUT_IMAGE="${1:-}"
OUTPUT_IMAGE="${2:-}"

BLUR_STRENGTH=15

if [[ -z "$INPUT_IMAGE" || -z "$OUTPUT_IMAGE" ]]; then
    echo "Usage: $0 <input_image> <output_image>"
    exit 1
fi

if [[ ! -f "$INPUT_IMAGE" ]]; then
    echo "Error: Input image does not exist: $INPUT_IMAGE"
    exit 1
fi

# Create output directory if it doesn't exist
mkdir -p "$(dirname "$OUTPUT_IMAGE")"

if command -v magick >/dev/null 2>&1; then
    # ImageMagick 7+
    magick "$INPUT_IMAGE" \
        -blur "0x${BLUR_STRENGTH}" \
        "$OUTPUT_IMAGE"
elif command -v convert >/dev/null 2>&1; then
    # ImageMagick 6
    convert "$INPUT_IMAGE" \
        -blur "0x${BLUR_STRENGTH}" \
        "$OUTPUT_IMAGE"
else
    echo "Error: ImageMagick not found"
    exit 1
fi

echo "Blurred image saved to: $OUTPUT_IMAGE"