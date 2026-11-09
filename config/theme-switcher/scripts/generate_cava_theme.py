#!/usr/bin/env python3
"""
Generate a smooth, vibrancy-boosted 8-color gradient theme for CAVA.

Picks 3 base non-status colors from a theme's palette:
  - Base 1 (bottom / foundation): accentAlt
  - Base 2 (mid / body):          accent
  - Base 3 (crest / peak):        text

Boosts their vibrancy (Oklab chroma) by ~20%, and perceptually bridges them
with 5 intermediate colors across the vertical visualizer pillar:
  - Step 1: Base 1 (boosted)
  - Steps 2-3: 2 intermediate bridging colors (Base 1 -> Base 2)
  - Step 4: Base 2 (boosted)
  - Steps 5-7: 3 intermediate bridging colors (Base 2 -> Base 3)
  - Step 8: Base 3 (boosted)
"""

import json
import math
import os
import sys
from pathlib import Path


def hex_to_srgb(hex_str: str):
    """Parse #RRGGBB hex string to normalized [0.0, 1.0] sRGB components."""
    clean = hex_str.strip().lstrip("#")
    if len(clean) == 3:
        clean = "".join(c * 2 for c in clean)
    elif len(clean) > 6:
        clean = clean[:6]
    r = int(clean[0:2], 16) / 255.0
    g = int(clean[2:4], 16) / 255.0
    b = int(clean[4:6], 16) / 255.0
    return r, g, b


def srgb_to_linear(c: float) -> float:
    """Transfer function: standard sRGB component to linear RGB."""
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def linear_to_srgb(c: float) -> float:
    """Transfer function: linear RGB component to standard sRGB."""
    c = max(0.0, min(1.0, c))
    return 12.92 * c if c <= 0.0031308 else 1.055 * (c ** (1.0 / 2.4)) - 0.055


def srgb_to_oklab(rgb):
    """Convert sRGB tuple (r, g, b) in [0, 1] to Oklab (L, a, b)."""
    r, g, b = (srgb_to_linear(c) for c in rgb)

    l = 0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b
    m = 0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b
    s = 0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b

    l_ = math.cbrt(l)
    m_ = math.cbrt(m)
    s_ = math.cbrt(s)

    L = 0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_
    a = 1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_
    b = 0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_

    return L, a, b


def oklab_to_srgb(lab):
    """Convert Oklab (L, a, b) to sRGB tuple (r, g, b) clamped to [0, 1]."""
    L, a, b = lab

    l_ = L + 0.3963377774 * a + 0.2158037573 * b
    m_ = L - 0.1055613458 * a - 0.0638541728 * b
    s_ = L - 0.0894841775 * a - 1.2914855480 * b

    l = l_ ** 3
    m = m_ ** 3
    s = s_ ** 3

    r_lin = +4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s
    g_lin = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s
    b_lin = -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s

    r = linear_to_srgb(r_lin)
    g = linear_to_srgb(g_lin)
    b = linear_to_srgb(b_lin)

    return max(0.0, min(1.0, r)), max(0.0, min(1.0, g)), max(0.0, min(1.0, b))


def rgb_to_hex(rgb) -> str:
    """Format sRGB tuple to #rrggbb hex string."""
    r = int(round(rgb[0] * 255))
    g = int(round(rgb[1] * 255))
    b = int(round(rgb[2] * 255))
    return f"#{r:02x}{g:02x}{b:02x}"


def boost_vibrancy_oklab(lab, factor: float = 1.20):
    """
    Boost color chroma by scaling the Oklab a and b components.
    Since Chroma C = sqrt(a^2 + b^2), scaling (a, b) by factor scales C by factor.
    """
    L, a, b = lab
    return L, a * factor, b * factor


def interpolate_oklab(lab1, lab2, t: float):
    """Linearly interpolate between two Oklab colors for uniform perception."""
    return (
        lab1[0] + (lab2[0] - lab1[0]) * t,
        lab1[1] + (lab2[1] - lab1[1]) * t,
        lab1[2] + (lab2[2] - lab1[2]) * t,
    )


def generate_gradient_colors(palette: dict) -> list[str]:
    """Generate 8 gradient colors from the palette."""
    # 3 base colors from palette (excluding status colors: success, warning, critical)
    base1_hex = palette.get("accentAlt") or palette.get("surfaceElevated") or "#4a78aa"
    base2_hex = palette.get("accent") or palette.get("selectedBackground") or "#6aa3e8"
    base3_hex = palette.get("text") or "#ffffff"

    # Convert to Oklab and boost vibrancy by ~20%
    b1_lab = boost_vibrancy_oklab(srgb_to_oklab(hex_to_srgb(base1_hex)), 1.20)
    b2_lab = boost_vibrancy_oklab(srgb_to_oklab(hex_to_srgb(base2_hex)), 1.20)
    b3_lab = boost_vibrancy_oklab(srgb_to_oklab(hex_to_srgb(base3_hex)), 1.20)

    colors = []

    # Segment 1: Base 1 to Base 2 across 3 intervals
    # Steps 1 (t=0/3), 2 (t=1/3), 3 (t=2/3)
    for i in range(3):
        t = i / 3.0
        colors.append(rgb_to_hex(oklab_to_srgb(interpolate_oklab(b1_lab, b2_lab, t))))

    # Segment 2: Base 2 to Base 3 across 4 intervals
    # Steps 4 (t=0/4), 5 (t=1/4), 6 (t=2/4), 7 (t=3/4), 8 (t=4/4)
    for i in range(5):
        t = i / 4.0
        colors.append(rgb_to_hex(oklab_to_srgb(interpolate_oklab(b2_lab, b3_lab, t))))

    return colors


def generate_cava_theme_content(colors: list[str]) -> str:
    """Format gradient colors as CAVA configuration INI."""
    lines = [
        "[color]",
        "gradient = 1",
        f"gradient_count = {len(colors)}",
    ]
    for idx, hex_code in enumerate(colors, start=1):
        lines.append(f"gradient_color_{idx} = '{hex_code}'")
    lines.append("")
    return "\n".join(lines)


def main():
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <colors.json> [output_file]", file=sys.stderr)
        sys.exit(1)

    source_path = Path(sys.argv[1])
    if not source_path.is_file():
        print(f"Error: Palette file not found: {source_path}", file=sys.stderr)
        sys.exit(1)

    with open(source_path, "r", encoding="utf-8") as f:
        palette = json.load(f)

    colors = generate_gradient_colors(palette)
    theme_content = generate_cava_theme_content(colors)

    if len(sys.argv) >= 3:
        target_path = Path(sys.argv[2])
        target_path.parent.mkdir(parents=True, exist_ok=True)
        target_path.write_text(theme_content, encoding="utf-8")
    else:
        sys.stdout.write(theme_content)


if __name__ == "__main__":
    main()
