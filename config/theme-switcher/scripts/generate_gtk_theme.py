#!/usr/bin/env python3
"""
generate_gtk_theme.py - Dynamic color-override generator for GTK 3 & GTK 4/Libadwaita.

Generates:
1. GTK 4 / Libadwaita color overrides -> ~/.config/gtk-4.0/gtk.css (live-reloaded by GTK 4).
2. Dynamic GTK 3 themes -> ~/.local/share/themes/ThemeSwitcherDynamic-[A|B]/
   (including gtk.css, index.theme, and assets symlink).
3. Sanitizes ~/.config/gtk-3.0/gtk.css to remove global @define-color overrides that
   shadow GTK_STYLE_PROVIDER_PRIORITY_THEME and block live reloading in running GTK 3 apps.
"""

import argparse
import json
import os
import re
import sys
from typing import Dict, Any, Tuple, Optional


def parse_rgb(color_str: str) -> Tuple[int, int, int]:
    """Parse hex, rgb/rgba, or color name into an (R, G, B) tuple (0-255)."""
    color_str = color_str.strip()

    # Match #RGB, #RGBA, #RRGGBB, #RRGGBBAA
    if color_str.startswith("#"):
        hex_val = color_str.lstrip("#")
        if len(hex_val) == 3:
            return (
                int(hex_val[0] * 2, 16),
                int(hex_val[1] * 2, 16),
                int(hex_val[2] * 2, 16),
            )
        elif len(hex_val) == 4:
            return (
                int(hex_val[0] * 2, 16),
                int(hex_val[1] * 2, 16),
                int(hex_val[2] * 2, 16),
            )
        elif len(hex_val) in (6, 8):
            return (
                int(hex_val[0:2], 16),
                int(hex_val[2:4], 16),
                int(hex_val[4:6], 16),
            )

    # Match rgb(...) or rgba(...)
    match = re.match(r"rgba?\s*\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)", color_str)
    if match:
        return (int(match.group(1)), int(match.group(2)), int(match.group(3)))

    if color_str.lower() == "white":
        return (255, 255, 255)
    if color_str.lower() == "black":
        return (0, 0, 0)

    # Fallback default
    return (128, 128, 128)


def get_luminance(color_str: str) -> float:
    """Calculate relative luminance using standard perceptual weights."""
    r, g, b = parse_rgb(color_str)
    return (0.299 * r + 0.587 * g + 0.114 * b) / 255.0


def contrast_fg(bg_color: str, light_fg: str = "#ffffff", dark_fg: str = "#000000") -> str:
    """Return high contrast foreground (light or dark) based on background luminance."""
    lum = get_luminance(bg_color)
    return dark_fg if lum > 0.55 else light_fg


def build_gtk_palette(palette: Dict[str, Any]) -> Dict[str, str]:
    """Map theme palette tokens to standard GTK / Libadwaita color variables."""
    # Source colors with sensible fallbacks
    bg = palette.get("background", "#1e1e2e")
    bg_alt = palette.get("backgroundAlt", palette.get("surfaceMuted", "#181825"))
    surface = palette.get("surface", "#24273a")
    surface_soft = palette.get("surfaceSoft", surface)
    surface_muted = palette.get("surfaceMuted", bg_alt)
    surface_elevated = palette.get("surfaceElevated", surface_soft)
    text = palette.get("text", "#cdd6f4")
    text_dim = palette.get("textDim", "#a6adc8")

    accent = palette.get("accent", "#89b4fa")
    accent_bg = palette.get("selectedBackground", accent)
    accent_fg = palette.get("selectedText") or contrast_fg(accent_bg, "#ffffff", "#000000")

    border = palette.get("border", "#313244")
    shadow = palette.get("shadow", "rgba(0, 0, 0, 0.36)")

    critical = palette.get("critical", "#f38ba8")
    critical_fg = contrast_fg(critical, "#ffffff", "#000000")

    success = palette.get("success", "#a6e3a1")
    success_fg = contrast_fg(success, "#ffffff", "#000000")

    warning = palette.get("warning", "#f9e2af")
    warning_fg = contrast_fg(warning, "#ffffff", "#000000")

    return {
        # Accent colors
        "accent_color": accent,
        "accent_bg_color": accent_bg,
        "accent_fg_color": accent_fg,
        # Window & View
        "window_bg_color": bg,
        "window_fg_color": text,
        "view_bg_color": surface,
        "view_fg_color": text,
        # Headerbar & Titlebar
        "headerbar_bg_color": surface_muted,
        "headerbar_fg_color": text,
        "headerbar_border_color": border,
        "headerbar_backdrop_color": bg,
        "headerbar_shade_color": shadow,
        # Card, Popover, Dialog
        "card_bg_color": surface_soft,
        "card_fg_color": text,
        "card_shade_color": shadow,
        "dialog_bg_color": surface_elevated,
        "dialog_fg_color": text,
        "popover_bg_color": surface_elevated,
        "popover_fg_color": text,
        "popover_shade_color": shadow,
        # Sidebar
        "sidebar_bg_color": surface_muted,
        "sidebar_fg_color": text,
        "sidebar_backdrop_color": bg,
        "secondary_sidebar_bg_color": surface,
        "secondary_sidebar_fg_color": text,
        # Borders & Shadows
        "shade_color": shadow,
        "scrollbar_outline_color": border,
        "border_color": border,
        # Semantic statuses
        "destructive_color": critical,
        "destructive_bg_color": critical,
        "destructive_fg_color": critical_fg,
        "success_color": success,
        "success_bg_color": success,
        "success_fg_color": success_fg,
        "warning_color": warning,
        "warning_bg_color": warning,
        "warning_fg_color": warning_fg,
        "error_color": critical,
        "error_bg_color": critical,
        "error_fg_color": critical_fg,
        # Additional tokens
        "text_dim_color": text_dim,
    }


def generate_gtk4_css(colors: Dict[str, str]) -> str:
    """Generate GTK 4 / Libadwaita CSS overrides."""
    lines = [
        "/* ========================================================================= */",
        "/* GTK 4 / Libadwaita Color Overrides - Dynamic Theme Switcher               */",
        "/* Generated by generate_gtk_theme.py                                        */",
        "/* ========================================================================= */",
        "",
        "/* --- Primary Palette & Libadwaita Variables --- */",
        f"@define-color accent_color {colors['accent_color']};",
        f"@define-color accent_bg_color {colors['accent_bg_color']};",
        f"@define-color accent_fg_color {colors['accent_fg_color']};",
        "",
        f"@define-color window_bg_color {colors['window_bg_color']};",
        f"@define-color window_fg_color {colors['window_fg_color']};",
        "",
        f"@define-color view_bg_color {colors['view_bg_color']};",
        f"@define-color view_fg_color {colors['view_fg_color']};",
        "",
        f"@define-color headerbar_bg_color {colors['headerbar_bg_color']};",
        f"@define-color headerbar_fg_color {colors['headerbar_fg_color']};",
        f"@define-color headerbar_border_color {colors['headerbar_border_color']};",
        f"@define-color headerbar_backdrop_color {colors['headerbar_backdrop_color']};",
        f"@define-color headerbar_shade_color {colors['headerbar_shade_color']};",
        "",
        f"@define-color card_bg_color {colors['card_bg_color']};",
        f"@define-color card_fg_color {colors['card_fg_color']};",
        f"@define-color card_shade_color {colors['card_shade_color']};",
        "",
        f"@define-color dialog_bg_color {colors['dialog_bg_color']};",
        f"@define-color dialog_fg_color {colors['dialog_fg_color']};",
        "",
        f"@define-color popover_bg_color {colors['popover_bg_color']};",
        f"@define-color popover_fg_color {colors['popover_fg_color']};",
        f"@define-color popover_shade_color {colors['popover_shade_color']};",
        "",
        f"@define-color sidebar_bg_color {colors['sidebar_bg_color']};",
        f"@define-color sidebar_fg_color {colors['sidebar_fg_color']};",
        f"@define-color sidebar_backdrop_color {colors['sidebar_backdrop_color']};",
        f"@define-color secondary_sidebar_bg_color {colors['secondary_sidebar_bg_color']};",
        f"@define-color secondary_sidebar_fg_color {colors['secondary_sidebar_fg_color']};",
        "",
        f"@define-color shade_color {colors['shade_color']};",
        f"@define-color scrollbar_outline_color {colors['scrollbar_outline_color']};",
        f"@define-color border_color {colors['border_color']};",
        "",
        "/* --- Semantic Indicators --- */",
        f"@define-color destructive_color {colors['destructive_color']};",
        f"@define-color destructive_bg_color {colors['destructive_bg_color']};",
        f"@define-color destructive_fg_color {colors['destructive_fg_color']};",
        f"@define-color success_color {colors['success_color']};",
        f"@define-color success_bg_color {colors['success_bg_color']};",
        f"@define-color success_fg_color {colors['success_fg_color']};",
        f"@define-color warning_color {colors['warning_color']};",
        f"@define-color warning_bg_color {colors['warning_bg_color']};",
        f"@define-color warning_fg_color {colors['warning_fg_color']};",
        f"@define-color error_color {colors['error_color']};",
        f"@define-color error_bg_color {colors['error_bg_color']};",
        f"@define-color error_fg_color {colors['error_fg_color']};",
        "",
        "/* --- GTK 3 Compatibility Aliases in GTK 4 --- */",
        "@define-color theme_selected_bg_color @accent_bg_color;",
        "@define-color theme_selected_fg_color @accent_fg_color;",
        "@define-color theme_bg_color @window_bg_color;",
        "@define-color theme_fg_color @window_fg_color;",
        "@define-color theme_base_color @view_bg_color;",
        "@define-color theme_text_color @view_fg_color;",
        "@define-color borders @border_color;",
        "",
    ]
    return "\n".join(lines)


def generate_gtk3_css(colors: Dict[str, str]) -> str:
    """Generate GTK 3 (adw-gtk3) CSS overrides."""
    gtk4_base = generate_gtk4_css(colors)
    gtk3_extras = [
        "/* --- adw-gtk3 Specific Aliases and Mixes --- */",
        "@define-color theme_unfocused_fg_color mix(@window_fg_color, @window_bg_color, 0.4);",
        "@define-color theme_unfocused_text_color @theme_unfocused_fg_color;",
        "@define-color theme_unfocused_bg_color @window_bg_color;",
        "@define-color theme_unfocused_base_color @window_bg_color;",
        "@define-color theme_unfocused_selected_bg_color @accent_bg_color;",
        "@define-color theme_unfocused_selected_fg_color @accent_fg_color;",
        "@define-color unfocused_borders @borders;",
        "@define-color content_view_bg @view_bg_color;",
        "",
    ]
    return gtk4_base.replace(
        "/* GTK 4 / Libadwaita Color Overrides - Dynamic Theme Switcher               */",
        "/* GTK 3 / adw-gtk3 Color Overrides - Dynamic Theme Switcher                 */"
    ) + "\n".join(gtk3_extras)


def write_file_atomic(path: str, content: str) -> None:
    """Write content to target path in-place to preserve file watching where possible."""
    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
        f.flush()
        os.fsync(f.fileno())


def find_gtk_base_theme(theme_name: str) -> Tuple[Optional[str], Optional[str]]:
    """Locate the base GTK 3 theme css and its assets directory."""
    candidates = [
        f"/usr/share/themes/{theme_name}",
        f"/usr/local/share/themes/{theme_name}",
        os.path.expanduser(f"~/.local/share/themes/{theme_name}"),
        os.path.expanduser(f"~/.themes/{theme_name}"),
    ]
    for d in candidates:
        css_path = os.path.join(d, "gtk-3.0", "gtk.css")
        if os.path.isfile(css_path):
            assets_dir = os.path.join(d, "gtk-3.0", "assets")
            return os.path.abspath(css_path), (os.path.abspath(assets_dir) if os.path.isdir(assets_dir) else None)
    return None, None


def sanitize_user_gtk3_css(path: str) -> None:
    """
    Ensure ~/.config/gtk-3.0/gtk.css does not define @define-color rules.
    In GTK 3, ~/.config/gtk-3.0/gtk.css is loaded at GTK_STYLE_PROVIDER_PRIORITY_USER (800).
    If it defines @define-color tokens, it permanently masks GTK_STYLE_PROVIDER_PRIORITY_THEME (200),
    preventing running GTK 3 apps like Thunar from updating colors when the theme alternates.
    Any non-color custom user CSS rules are preserved.
    """
    header = (
        "/* ========================================================================= */\n"
        "/* GTK 3 User Styles - Dynamic Theme Switcher                                */\n"
        "/* Colors are managed dynamically via ThemeSwitcherDynamic-[A|B] themes.     */\n"
        "/* Global @define-color rules are excluded here to allow live GTK3 reloading */\n"
        "/* ========================================================================= */\n"
    )

    if not os.path.exists(path):
        write_file_atomic(path, header)
        return

    try:
        with open(path, "r", encoding="utf-8") as f:
            content = f.read()

        gen_markers = [
            "/* ===",
            "/* ---",
            "/* GTK 3",
            "/* GTK 4",
            "/* Generated by",
            "/* Colors are managed dynamically",
            "/* Global @define-color",
        ]
        user_lines = []
        for line in content.splitlines():
            stripped = line.strip()
            if not stripped:
                continue
            if any(stripped.startswith(m) for m in gen_markers):
                continue
            if stripped.startswith("@define-color "):
                continue
            user_lines.append(line)

        cleaned_user_css = "\n".join(user_lines).strip()
        new_content = header + ("\n" + cleaned_user_css + "\n" if cleaned_user_css else "")
        write_file_atomic(path, new_content)
    except Exception as e:
        print(f"[WARN] Failed to sanitize user gtk.css: {e}", file=sys.stderr)


def generate_dynamic_theme_variant(
    variant_name: str,
    gtk3_css: str,
    base_css: Optional[str],
    base_assets: Optional[str],
    icon_theme: str = "Papirus-Dark",
) -> None:
    """Generate a self-contained GTK 3 theme variant in ~/.local/share/themes/<variant_name>."""
    theme_dir = os.path.expanduser(f"~/.local/share/themes/{variant_name}")
    gtk3_dir = os.path.join(theme_dir, "gtk-3.0")
    os.makedirs(gtk3_dir, exist_ok=True)

    # 1. index.theme
    index_theme = (
        "[Desktop Entry]\n"
        "Type=X-GNOME-Metatheme\n"
        f"Name={variant_name}\n"
        "Comment=Dynamic GTK Theme Managed by Theme Switcher\n"
        "Encoding=UTF-8\n\n"
        "[X-GNOME-Metatheme]\n"
        f"GtkTheme={variant_name}\n"
        f"MetacityTheme={variant_name}\n"
        f"IconTheme={icon_theme}\n"
    )
    write_file_atomic(os.path.join(theme_dir, "index.theme"), index_theme)

    # 2. gtk-3.0/gtk.css
    import_header = f'@import url("{base_css}");\n\n' if base_css else ""
    full_css = import_header + gtk3_css
    write_file_atomic(os.path.join(gtk3_dir, "gtk.css"), full_css)

    # 3. Symlink assets if available (ensures checkboxes, radios, switches render properly)
    if base_assets and os.path.isdir(base_assets):
        target_assets = os.path.join(gtk3_dir, "assets")
        if not os.path.exists(target_assets):
            try:
                os.symlink(base_assets, target_assets)
            except OSError:
                pass


def main():
    parser = argparse.ArgumentParser(description="Generate GTK 3 & GTK 4 color overrides from theme colors.json")
    parser.add_argument(
        "source",
        nargs="?",
        default=os.path.expanduser("~/.config/theme-switcher/state/current_colors.json"),
        help="Path to source colors.json (default: state/current_colors.json)",
    )
    parser.add_argument(
        "--gtk3-user-css",
        default=os.path.expanduser("~/.config/gtk-3.0/gtk.css"),
        help="Target path for GTK 3 user CSS (default: ~/.config/gtk-3.0/gtk.css)",
    )
    parser.add_argument(
        "--gtk4-out",
        default=os.path.expanduser("~/.config/gtk-4.0/gtk.css"),
        help="Target output for GTK 4 CSS (default: ~/.config/gtk-4.0/gtk.css)",
    )
    parser.add_argument(
        "--base-theme",
        default="adw-gtk3-dark",
        help="Base GTK 3 theme to import (default: adw-gtk3-dark)",
    )
    parser.add_argument(
        "--icon-theme",
        default="Papirus-Dark",
        help="Icon theme to register in index.theme (default: Papirus-Dark)",
    )
    parser.add_argument(
        "--stdout",
        action="store_true",
        help="Print generated CSS to stdout instead of writing files",
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

    colors = build_gtk_palette(palette)
    gtk3_css = generate_gtk3_css(colors)
    gtk4_css = generate_gtk4_css(colors)

    if args.stdout:
        print("/* === GTK 3 === */")
        print(gtk3_css)
        print("/* === GTK 4 === */")
        print(gtk4_css)
        return

    # 1. Write GTK 4 / Libadwaita CSS (watched and live-reloaded by GTK 4)
    write_file_atomic(args.gtk4_out, gtk4_css)
    print(f"[OK] Generated GTK 4 theme -> {args.gtk4_out}")

    # 2. Locate base GTK 3 theme (e.g. adw-gtk3-dark) and assets
    base_css, base_assets = find_gtk_base_theme(args.base_theme)
    if not base_css and args.base_theme != "adw-gtk3-dark":
        base_css, base_assets = find_gtk_base_theme("adw-gtk3-dark")

    # 3. Generate dynamic theme variants ThemeSwitcherDynamic-A and ThemeSwitcherDynamic-B
    for variant in ["ThemeSwitcherDynamic-A", "ThemeSwitcherDynamic-B"]:
        generate_dynamic_theme_variant(
            variant_name=variant,
            gtk3_css=gtk3_css,
            base_css=base_css,
            base_assets=base_assets,
            icon_theme=args.icon_theme,
        )
    print(f"[OK] Generated GTK 3 dynamic variants -> ~/.local/share/themes/ThemeSwitcherDynamic-[A|B]")

    # 4. Sanitize ~/.config/gtk-3.0/gtk.css to remove global @define-color that blocks live theme switching
    sanitize_user_gtk3_css(args.gtk3_user_css)
    print(f"[OK] Sanitized user GTK 3 config -> {args.gtk3_user_css}")


if __name__ == "__main__":
    main()
