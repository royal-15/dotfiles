#!/usr/bin/env python3
"""
generate_qt_theme.py - Dynamic Qt5, Qt6 & Kvantum color-override generator.

Generates:
1. ~/.config/qt5ct/style-colors.conf (21 roles)
2. ~/.config/qt6ct/style-colors.conf (22 roles including Accent)
3. Managed Kvantum theme ~/.config/Kvantum/ThemeSwitcherDynamic/ (overriding [GeneralColors])
4. Updates ~/.config/Kvantum/kvantum.kvconfig
"""

import argparse
import json
import os
import re
import sys
from typing import Dict, Any, Tuple, List, Optional


def parse_rgba(color_str: str) -> Tuple[int, int, int, int]:
    """Parse hex, rgb/rgba, or color name into an (R, G, B, A) tuple (0-255)."""
    color_str = color_str.strip()

    # Match #RGB, #RGBA, #RRGGBB, #RRGGBBAA
    if color_str.startswith("#"):
        hex_val = color_str.lstrip("#")
        if len(hex_val) == 3:
            return (
                int(hex_val[0] * 2, 16),
                int(hex_val[1] * 2, 16),
                int(hex_val[2] * 2, 16),
                255,
            )
        elif len(hex_val) == 4:
            return (
                int(hex_val[0] * 2, 16),
                int(hex_val[1] * 2, 16),
                int(hex_val[2] * 2, 16),
                int(hex_val[3] * 2, 16),
            )
        elif len(hex_val) == 6:
            return (
                int(hex_val[0:2], 16),
                int(hex_val[2:4], 16),
                int(hex_val[4:6], 16),
                255,
            )
        elif len(hex_val) == 8:
            return (
                int(hex_val[0:2], 16),
                int(hex_val[2:4], 16),
                int(hex_val[4:6], 16),
                int(hex_val[6:8], 16),
            )

    # Match rgb(...) or rgba(...)
    match = re.match(
        r"rgba?\s*\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)(?:\s*,\s*([\d.]+))?\s*\)",
        color_str,
    )
    if match:
        r, g, b = int(match.group(1)), int(match.group(2)), int(match.group(3))
        a = 255
        if match.group(4) is not None:
            af = float(match.group(4))
            a = int(round(af * 255)) if af <= 1.0 else int(af)
        return (r, g, b, min(255, max(0, a)))

    if color_str.lower() == "white":
        return (255, 255, 255, 255)
    if color_str.lower() == "black":
        return (0, 0, 0, 255)

    # Fallback default
    return (128, 128, 128, 255)


def to_qt_hex(rgba: Tuple[int, int, int, int]) -> str:
    """Format tuple as Qt INI format: #AARRGGBB."""
    r, g, b, a = rgba
    return f"#{a:02x}{r:02x}{g:02x}{b:02x}"


def to_kvantum_hex(rgba: Tuple[int, int, int, int]) -> str:
    """Format tuple as Kvantum format: #RRGGBB or #RRGGBBAA."""
    r, g, b, a = rgba
    if a == 255:
        return f"#{r:02x}{g:02x}{b:02x}"
    return f"#{r:02x}{g:02x}{b:02x}{a:02x}"


def get_luminance(rgba: Tuple[int, int, int, int]) -> float:
    """Calculate relative luminance using standard perceptual weights."""
    r, g, b, _ = rgba
    return (0.299 * r + 0.587 * g + 0.114 * b) / 255.0


def contrast_fg(
    bg_rgba: Tuple[int, int, int, int],
    light_rgba: Tuple[int, int, int, int] = (255, 255, 255, 255),
    dark_rgba: Tuple[int, int, int, int] = (0, 0, 0, 255),
) -> Tuple[int, int, int, int]:
    """Return high contrast foreground based on background luminance."""
    lum = get_luminance(bg_rgba)
    return dark_rgba if lum > 0.55 else light_rgba


def set_alpha(rgba: Tuple[int, int, int, int], alpha: int) -> Tuple[int, int, int, int]:
    """Return color with updated alpha value."""
    return (rgba[0], rgba[1], rgba[2], min(255, max(0, alpha)))


def dim_color(rgba: Tuple[int, int, int, int], factor: float = 0.6) -> Tuple[int, int, int, int]:
    """Dim color components towards black while keeping alpha."""
    return (
        int(round(rgba[0] * factor)),
        int(round(rgba[1] * factor)),
        int(round(rgba[2] * factor)),
        rgba[3],
    )


def blend_colors(
    c1: Tuple[int, int, int, int], c2: Tuple[int, int, int, int], ratio: float = 0.5
) -> Tuple[int, int, int, int]:
    """Blend two colors (ratio 0.0 is c1, 1.0 is c2)."""
    return (
        int(round(c1[0] * (1.0 - ratio) + c2[0] * ratio)),
        int(round(c1[1] * (1.0 - ratio) + c2[1] * ratio)),
        int(round(c1[2] * (1.0 - ratio) + c2[2] * ratio)),
        int(round(c1[3] * (1.0 - ratio) + c2[3] * ratio)),
    )


def build_qt_palette_entries(palette: Dict[str, Any], is_qt6: bool = False) -> Dict[str, List[str]]:
    """
    Build active_colors, inactive_colors, and disabled_colors for qt5ct/qt6ct.
    Qt5 uses 21 roles (0 to 20); Qt6 uses 22 roles (0 to 21, including Accent).
    """
    bg = parse_rgba(palette.get("background", "#1e1e2e"))
    bg_alt = parse_rgba(palette.get("backgroundAlt", palette.get("surfaceMuted", "#181825")))
    surface = parse_rgba(palette.get("surface", "#24273a"))
    surface_soft = parse_rgba(palette.get("surfaceSoft", "#2b251f"))
    surface_muted = parse_rgba(palette.get("surfaceMuted", "#15181d"))
    surface_elevated = parse_rgba(palette.get("surfaceElevated", "#292e37"))

    text = parse_rgba(palette.get("text", "#cdd6f4"))
    text_dim = parse_rgba(palette.get("textDim", "#a6adc8"))

    accent = parse_rgba(palette.get("accent", "#89b4fa"))
    accent_alt = parse_rgba(palette.get("accentAlt", "#858e9c"))
    selected_bg = parse_rgba(palette.get("selectedBackground", palette.get("accent", "#89b4fa")))
    selected_fg_str = palette.get("selectedText")
    selected_fg = parse_rgba(selected_fg_str) if selected_fg_str else contrast_fg(selected_bg)

    border = parse_rgba(palette.get("border", "#313244"))
    shadow = (0, 0, 0, 255)

    critical = parse_rgba(palette.get("critical", "#f38ba8"))
    bright_text = (255, 255, 255, 255)
    tip_bg = parse_rgba(palette.get("tip", palette.get("surfaceElevated", "#292e37")))

    # 1. Active roles
    # 0: WindowText
    # 1: Button
    # 2: Light
    # 3: Midlight
    # 4: Dark
    # 5: Mid
    # 6: Text
    # 7: BrightText
    # 8: ButtonText
    # 9: Base
    # 10: Window
    # 11: Shadow
    # 12: Highlight
    # 13: HighlightedText
    # 14: Link
    # 15: LinkVisited
    # 16: AlternateBase
    # 17: NoRole
    # 18: ToolTipBase
    # 19: ToolTipText
    # 20: PlaceholderText
    # 21: Accent (Qt6 only)
    active_roles = [
        text,              # 0: WindowText
        surface,           # 1: Button
        surface_elevated,  # 2: Light
        surface_soft,      # 3: Midlight
        surface_muted,     # 4: Dark
        border,            # 5: Mid
        text,              # 6: Text
        bright_text,       # 7: BrightText
        text,              # 8: ButtonText
        surface,           # 9: Base
        bg,                # 10: Window
        shadow,            # 11: Shadow
        selected_bg,       # 12: Highlight
        selected_fg,       # 13: HighlightedText
        accent_alt,        # 14: Link
        critical,          # 15: LinkVisited
        surface_soft,      # 16: AlternateBase
        (255, 255, 255, 255), # 17: NoRole
        set_alpha(tip_bg, 255), # 18: ToolTipBase
        text,              # 19: ToolTipText
        set_alpha(text_dim, 128), # 20: PlaceholderText
    ]
    if is_qt6:
        active_roles.append(accent)  # 21: Accent

    # 2. Inactive roles (dimmed highlights and inactive text, preserving layout)
    inactive_roles = list(active_roles)
    inactive_roles[0] = set_alpha(text, 200)       # WindowText slightly dimmed
    inactive_roles[12] = blend_colors(selected_bg, surface, 0.3) # Highlight dimmed
    inactive_roles[13] = set_alpha(selected_fg, 200) # HighlightedText slightly dimmed
    if is_qt6:
        inactive_roles[21] = blend_colors(accent, surface, 0.2)

    # 3. Disabled roles
    disabled_roles = list(active_roles)
    disabled_text = set_alpha(text_dim, 160)
    disabled_roles[0] = disabled_text               # WindowText
    disabled_roles[6] = disabled_text               # Text
    disabled_roles[8] = disabled_text               # ButtonText
    disabled_roles[12] = blend_colors(selected_bg, bg, 0.6) # Highlight
    disabled_roles[13] = set_alpha(selected_fg, 102) # HighlightedText (~40% opacity)
    disabled_roles[20] = set_alpha(text_dim, 80)    # PlaceholderText

    return {
        "active_colors": [to_qt_hex(c) for c in active_roles],
        "inactive_colors": [to_qt_hex(c) for c in inactive_roles],
        "disabled_colors": [to_qt_hex(c) for c in disabled_roles],
    }


def generate_qt_conf(palette: Dict[str, Any], is_qt6: bool = False) -> str:
    """Generate style-colors.conf INI content for qt5ct or qt6ct."""
    entries = build_qt_palette_entries(palette, is_qt6=is_qt6)
    lines = [
        "[ColorScheme]",
        f"active_colors={', '.join(entries['active_colors'])}",
        f"disabled_colors={', '.join(entries['disabled_colors'])}",
        f"inactive_colors={', '.join(entries['inactive_colors'])}",
        "",
    ]
    return "\n".join(lines)


def build_kvantum_general_colors(palette: Dict[str, Any]) -> str:
    """Build the [GeneralColors] section for Kvantum .kvconfig."""
    bg = parse_rgba(palette.get("background", "#1e1e2e"))
    surface = parse_rgba(palette.get("surface", "#24273a"))
    surface_soft = parse_rgba(palette.get("surfaceSoft", "#2b251f"))
    surface_muted = parse_rgba(palette.get("surfaceMuted", "#15181d"))
    surface_elevated = parse_rgba(palette.get("surfaceElevated", "#292e37"))

    text = parse_rgba(palette.get("text", "#cdd6f4"))
    text_dim = parse_rgba(palette.get("textDim", "#a6adc8"))

    accent = parse_rgba(palette.get("accent", "#89b4fa"))
    accent_alt = parse_rgba(palette.get("accentAlt", "#858e9c"))
    selected_bg = parse_rgba(palette.get("selectedBackground", palette.get("accent", "#89b4fa")))
    selected_fg_str = palette.get("selectedText")
    selected_fg = parse_rgba(selected_fg_str) if selected_fg_str else contrast_fg(selected_bg)

    border = parse_rgba(palette.get("border", "#313244"))
    critical = parse_rgba(palette.get("critical", "#f38ba8"))

    lines = [
        "[GeneralColors]",
        f"window.color={to_kvantum_hex(bg)}",
        f"inactive.window.color={to_kvantum_hex(bg)}",
        f"base.color={to_kvantum_hex(surface)}",
        f"inactive.base.color={to_kvantum_hex(surface)}",
        f"alt.base.color={to_kvantum_hex(surface_soft)}",
        f"inactive.alt.base.color={to_kvantum_hex(surface_soft)}",
        f"button.color={to_kvantum_hex(surface)}",
        f"light.color={to_kvantum_hex(surface_elevated)}",
        f"mid.light.color={to_kvantum_hex(surface_soft)}",
        f"dark.color={to_kvantum_hex(surface_muted)}",
        f"mid.color={to_kvantum_hex(border)}",
        f"highlight.color={to_kvantum_hex(selected_bg)}",
        f"inactive.highlight.color={to_kvantum_hex(accent_alt)}",
        f"text.color={to_kvantum_hex(text)}",
        f"inactive.text.color={to_kvantum_hex(set_alpha(text, 200))}",
        f"window.text.color={to_kvantum_hex(text)}",
        f"inactive.window.text.color={to_kvantum_hex(set_alpha(text_dim, 180))}",
        f"button.text.color={to_kvantum_hex(text)}",
        f"disabled.text.color={to_kvantum_hex(text_dim)}",
        f"tooltip.text.color={to_kvantum_hex(text)}",
        f"highlight.text.color={to_kvantum_hex(selected_fg)}",
        f"link.color={to_kvantum_hex(accent)}",
        f"link.visited.color={to_kvantum_hex(critical)}",
        f"progress.indicator.text.color={to_kvantum_hex(selected_fg)}",
        "",
    ]
    return "\n".join(lines)


def find_theme_file(theme_name: str, filename_ext: str, kvantum_user_dir: str) -> Optional[str]:
    """Locate a kvconfig or svg file for a theme name in user or system Kvantum directories."""
    clean_name = theme_name.rstrip("#")
    search_dirs = [
        os.path.join(kvantum_user_dir, theme_name),
        os.path.join(kvantum_user_dir, clean_name),
        f"/usr/share/Kvantum/{theme_name}",
        f"/usr/share/Kvantum/{clean_name}",
        f"/usr/local/share/Kvantum/{clean_name}",
        os.path.expanduser(f"~/.local/share/themes/{theme_name}/Kvantum"),
        os.path.expanduser(f"~/.local/share/themes/{theme_name}/kvantum"),
        os.path.expanduser(f"~/.local/share/themes/{clean_name}/Kvantum"),
        os.path.expanduser(f"~/.local/share/themes/{clean_name}/kvantum"),
    ]

    candidates = [f"{theme_name}{filename_ext}", f"{clean_name}{filename_ext}"]
    for d in search_dirs:
        for c in candidates:
            p = os.path.join(d, c)
            if os.path.isfile(p):
                return os.path.abspath(p)
    return None


def update_kvantum_active_theme(config_path: str, managed_theme: str) -> None:
    """Safely update theme=<managed_theme> under [General] in kvantum.kvconfig without wiping other settings."""
    if not os.path.isfile(config_path):
        write_file_atomic(config_path, f"[General]\ntheme={managed_theme}\n")
        return

    try:
        with open(config_path, "r", encoding="utf-8") as f:
            lines = f.readlines()

        output_lines = []
        in_general = False
        theme_set = False

        for line in lines:
            stripped = line.strip()
            if stripped == "[General]":
                in_general = True
                output_lines.append(line)
                continue
            if in_general and stripped.startswith("[") and stripped.endswith("]"):
                if not theme_set:
                    output_lines.append(f"theme={managed_theme}\n")
                    theme_set = True
                in_general = False
            if in_general and stripped.startswith("theme="):
                output_lines.append(f"theme={managed_theme}\n")
                theme_set = True
                continue
            output_lines.append(line)

        if in_general and not theme_set:
            output_lines.append(f"theme={managed_theme}\n")
            theme_set = True

        if not theme_set:
            output_lines.append(f"\n[General]\ntheme={managed_theme}\n")

        write_file_atomic(config_path, "".join(output_lines))
    except Exception:
        write_file_atomic(config_path, f"[General]\ntheme={managed_theme}\n")


def generate_kvantum_theme(
    palette: Dict[str, Any],
    kvantum_dir: str,
    managed_theme: str = "ThemeSwitcherDynamic",
    base_theme: Optional[str] = None,
) -> Tuple[str, str]:
    """
    Clone the base Kvantum theme, replace [GeneralColors], and link SVGs.
    Returns (managed_theme_dir, managed_kvconfig_path).
    """
    managed_dir = os.path.join(kvantum_dir, managed_theme)
    base_theme_marker = os.path.join(managed_dir, ".base_theme")
    active_config_path = os.path.join(kvantum_dir, "kvantum.kvconfig")

    # 1. Determine active base theme
    fallback_base = "KvGnomeDark#"
    candidate_base = base_theme

    if not candidate_base and os.path.isfile(active_config_path):
        try:
            with open(active_config_path, "r", encoding="utf-8") as f:
                for line in f:
                    if line.strip().startswith("theme="):
                        curr = line.strip().split("=", 1)[1].strip()
                        if curr and curr != managed_theme:
                            candidate_base = curr
                        break
        except Exception:
            pass

    if not candidate_base and os.path.isfile(base_theme_marker):
        try:
            with open(base_theme_marker, "r", encoding="utf-8") as f:
                saved = f.read().strip()
                if saved and saved != managed_theme:
                    candidate_base = saved
        except Exception:
            pass

    if not candidate_base:
        candidate_base = fallback_base

    # 2. Locate base kvconfig
    base_kvconfig = find_theme_file(candidate_base, ".kvconfig", kvantum_dir)
    if not base_kvconfig and candidate_base != fallback_base:
        base_kvconfig = find_theme_file(fallback_base, ".kvconfig", kvantum_dir)
        candidate_base = fallback_base

    if not base_kvconfig:
        raise FileNotFoundError(f"Could not find base Kvantum .kvconfig for {candidate_base} or {fallback_base}")

    # 3. Locate base SVG / SVGZ
    base_svg = find_theme_file(candidate_base, ".svg", kvantum_dir)
    ext = ".svg"
    if not base_svg:
        base_svg = find_theme_file(candidate_base, ".svgz", kvantum_dir)
        ext = ".svgz"
    if not base_svg and candidate_base != fallback_base:
        base_svg = find_theme_file(fallback_base, ".svg", kvantum_dir)
        ext = ".svg"
        if not base_svg:
            base_svg = find_theme_file(fallback_base, ".svgz", kvantum_dir)
            ext = ".svgz"

    # 4. Prepare managed theme directory and store base theme marker
    os.makedirs(managed_dir, exist_ok=True)
    try:
        with open(base_theme_marker, "w", encoding="utf-8") as f:
            f.write(candidate_base + "\n")
    except Exception:
        pass

    # 5. Read base kvconfig and replace only [GeneralColors]
    with open(base_kvconfig, "r", encoding="utf-8") as f:
        lines = f.readlines()

    new_general_colors = build_kvantum_general_colors(palette)
    output_lines = []
    in_general_colors = False
    replaced = False

    for line in lines:
        stripped = line.strip()
        if stripped == "[GeneralColors]":
            in_general_colors = True
            output_lines.append(new_general_colors)
            replaced = True
            continue
        if in_general_colors:
            if stripped.startswith("[") and stripped.endswith("]"):
                in_general_colors = False
                output_lines.append(line)
            else:
                # Skip old [GeneralColors] lines
                continue
        else:
            output_lines.append(line)

    if not replaced:
        output_lines.append("\n" + new_general_colors)

    managed_kvconfig_path = os.path.join(managed_dir, f"{managed_theme}.kvconfig")
    write_file_atomic(managed_kvconfig_path, "".join(output_lines))

    # 6. Symlink SVG if found
    if base_svg and os.path.isfile(base_svg):
        target_svg = os.path.join(managed_dir, f"{managed_theme}{ext}")
        if os.path.lexists(target_svg):
            try:
                os.remove(target_svg)
            except OSError:
                pass
        try:
            os.symlink(base_svg, target_svg)
        except OSError as e:
            # Fallback to copy if symlink fails
            import shutil
            shutil.copyfile(base_svg, target_svg)

    # 7. Update kvantum.kvconfig to point to managed theme safely
    update_kvantum_active_theme(active_config_path, managed_theme)

    return managed_dir, managed_kvconfig_path

    return managed_dir, managed_kvconfig_path


def write_file_atomic(path: str, content: str) -> None:
    """Write content to target path in-place to preserve file watching where possible."""
    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
        f.flush()
        os.fsync(f.fileno())


def main():
    parser = argparse.ArgumentParser(description="Generate dynamic Qt5/Qt6 and Kvantum color overrides from theme colors.json")
    parser.add_argument(
        "source",
        nargs="?",
        default=os.path.expanduser("~/.config/theme-switcher/state/current_colors.json"),
        help="Path to source colors.json (default: state/current_colors.json)",
    )
    parser.add_argument(
        "--qt5-out",
        default=os.path.expanduser("~/.config/qt5ct/style-colors.conf"),
        help="Target output for qt5ct style-colors.conf (default: ~/.config/qt5ct/style-colors.conf)",
    )
    parser.add_argument(
        "--qt6-out",
        default=os.path.expanduser("~/.config/qt6ct/style-colors.conf"),
        help="Target output for qt6ct style-colors.conf (default: ~/.config/qt6ct/style-colors.conf)",
    )
    parser.add_argument(
        "--kvantum-dir",
        default=os.path.expanduser("~/.config/Kvantum"),
        help="Kvantum user directory (default: ~/.config/Kvantum)",
    )
    parser.add_argument(
        "--theme-name",
        default="ThemeSwitcherDynamic",
        help="Name of managed Kvantum theme (default: ThemeSwitcherDynamic)",
    )
    parser.add_argument(
        "--base-theme",
        default=None,
        help="Base Kvantum theme to clone (default: auto-detect from active config / fallback to KvGnomeDark#)",
    )
    parser.add_argument(
        "--no-qtct",
        action="store_true",
        help="Skip generating qt5ct/qt6ct style-colors.conf files",
    )
    parser.add_argument(
        "--no-kvantum",
        action="store_true",
        help="Skip generating Kvantum managed theme override",
    )
    parser.add_argument(
        "--stdout",
        action="store_true",
        help="Print generated configurations to stdout instead of writing files",
    )

    args = parser.parse_args()

    source_path = os.path.abspath(args.source)
    if not os.path.exists(source_path):
        print(f"[ERROR] Source color file not found: {source_path}", file=sys.stderr)
        sys.exit(1)

    try:
        with open(source_path, "r", encoding="utf-8") as f:
            palette = json.load(f)
    except Exception as e:
        print(f"[ERROR] Failed to load JSON from {source_path}: {e}", file=sys.stderr)
        sys.exit(1)

    qt5_conf = generate_qt_conf(palette, is_qt6=False)
    qt6_conf = generate_qt_conf(palette, is_qt6=True)
    kvantum_colors = build_kvantum_general_colors(palette)

    if args.stdout:
        if not args.no_qtct:
            print("/* === qt5ct style-colors.conf === */")
            print(qt5_conf)
            print("/* === qt6ct style-colors.conf === */")
            print(qt6_conf)
        if not args.no_kvantum:
            print("/* === Kvantum [GeneralColors] === */")
            print(kvantum_colors)
        return

    # Write qt5ct / qt6ct configs
    if not args.no_qtct:
        write_file_atomic(args.qt5_out, qt5_conf)
        write_file_atomic(args.qt6_out, qt6_conf)
        print(f"[OK] Generated Qt5 color palette -> {args.qt5_out}")
        print(f"[OK] Generated Qt6 color palette -> {args.qt6_out}")

    # Write Kvantum dynamic theme override
    if not args.no_kvantum:
        try:
            m_dir, m_cfg = generate_kvantum_theme(
                palette=palette,
                kvantum_dir=args.kvantum_dir,
                managed_theme=args.theme_name,
                base_theme=args.base_theme,
            )
            print(f"[OK] Generated Kvantum dynamic theme -> {m_cfg}")
            print(f"[OK] Configured Kvantum active theme -> {args.theme_name}")
        except Exception as e:
            print(f"[WARN] Failed to generate Kvantum dynamic theme: {e}", file=sys.stderr)


if __name__ == "__main__":
    main()
