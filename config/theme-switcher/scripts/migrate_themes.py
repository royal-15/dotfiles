#!/usr/bin/env python3
# =============================================================================
# DEPRECATED / ARCHIVED REFERENCE ONLY
# -----------------------------------------------------------------------------
# Themes are now maintained as DECENTRALIZED STATIC FILES directly inside
# themes/<name>/colors/ and themes/<name>/hypr/.
# Do NOT run this script directly to overwrite existing themes, as it will
# overwrite the bespoke, hand-tuned production color schemes.
# =============================================================================
import os
import shutil
import json
import glob
from PIL import Image, ImageFilter

ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
THEMES_DIR = os.path.join(ROOT_DIR, "themes")
CACHE_DIR = os.path.join(ROOT_DIR, "cache", "wallpaper-blur")
STAGING_DIR = "/tmp/new_themes_staging"

# -----------------------------------------------------------------------------
# 1. CURATED THEME ROSTER (4-Axis Spectrum Palettes)
# -----------------------------------------------------------------------------
THEMES = {
    "monochrome": {
        "name": "Monochrome",
        "description": "Achromatic Brutalism & Distraction-free Slate",
        "bg": "#0a0b0e",
        "bg_alt": "#121318",
        "surface": "#16171d",
        "surface_soft": "#1c1d25",
        "surface_elevated": "#23242e",
        "border": "#2c2e3a",
        "text": "#e8e7df",
        "text_dim": "#8f8e87",
        "accent": "#c8c7be",
        "accent_alt": "#8a8980",
        "success": "#7a8a78",
        "warning": "#a39979",
        "critical": "#9e6b6b",
        "gtk_theme": "Graphite-Dark-compact",
        "gtk_icon": "Papirus-Dark",
        "kvantum": "KvGnomeDark#"
    },
    "afterglow": {
        "name": "Afterglow",
        "description": "Warm Sunset Horizon, Terracotta & Autumn Dusk",
        "bg": "#1e1216",
        "bg_alt": "#25181d",
        "surface": "#2a1c22",
        "surface_soft": "#33222a",
        "surface_elevated": "#3c2a33",
        "border": "#4a323d",
        "text": "#f0d6c8",
        "text_dim": "#a88a80",
        "accent": "#e27464",
        "accent_alt": "#dda15e",
        "success": "#789262",
        "warning": "#dda15e",
        "critical": "#d14949",
        "gtk_theme": "Graphite-Dark-compact",
        "gtk_icon": "Papirus-Dark",
        "kvantum": "KvMojave#"
    },
    "twilight": {
        "name": "Twilight",
        "description": "Deep Velvet Violet, Amethyst Stars & Synth Dusk",
        "bg": "#120e1e",
        "bg_alt": "#181329",
        "surface": "#1e1832",
        "surface_soft": "#271f40",
        "surface_elevated": "#30274f",
        "border": "#3f3366",
        "text": "#e6dcfc",
        "text_dim": "#9c8ebd",
        "accent": "#a78bfa",
        "accent_alt": "#c084fc",
        "success": "#6ee7b7",
        "warning": "#fcd34d",
        "critical": "#f43f5e",
        "gtk_theme": "Orchis-Purple-Dark-Compact-Dracula",
        "gtk_icon": "Papirus-Dark",
        "kvantum": "KvArcDark#"
    },
    "moonlit": {
        "name": "Moonlit",
        "description": "Nocturnal Inky Navy, Ocean Midnight & Cold Starlight",
        "bg": "#0b0f17",
        "bg_alt": "#111722",
        "surface": "#151d2b",
        "surface_soft": "#1c2637",
        "surface_elevated": "#233044",
        "border": "#2b3b54",
        "text": "#d4e0ee",
        "text_dim": "#8297b0",
        "accent": "#6ca0dc",
        "accent_alt": "#46729e",
        "success": "#529b7a",
        "warning": "#cfa856",
        "critical": "#c45656",
        "gtk_theme": "Orchis-Teal-Dark-Compact-Dracula",
        "gtk_icon": "Papirus-Dark",
        "kvantum": "KvArcDark#"
    },
    "serenity": {
        "name": "Serenity",
        "description": "Glacial Abyss, Crisp Arctic Cyan & Alpine Frost",
        "bg": "#081217",
        "bg_alt": "#0e1a20",
        "surface": "#122129",
        "surface_soft": "#182c36",
        "surface_elevated": "#203844",
        "border": "#264858",
        "text": "#d2f1f5",
        "text_dim": "#7eaeb6",
        "accent": "#48cae4",
        "accent_alt": "#2a98ab",
        "success": "#48b590",
        "warning": "#d4a359",
        "critical": "#cf5353",
        "gtk_theme": "Orchis-Teal-Dark-Compact-Dracula",
        "gtk_icon": "Papirus-Dark",
        "kvantum": "KvAdaptaDark#"
    },
    "forest": {
        "name": "Forest",
        "description": "Lush Pine Evergreen, Pastoral Sage & Meadow Gold",
        "bg": "#0b1410",
        "bg_alt": "#111c16",
        "surface": "#15241d",
        "surface_soft": "#1c3027",
        "surface_elevated": "#243d31",
        "border": "#2d4d3f",
        "text": "#dbe8d8",
        "text_dim": "#86a48a",
        "accent": "#7eb078",
        "accent_alt": "#cda652",
        "success": "#7eb078",
        "warning": "#cda652",
        "critical": "#c25454",
        "gtk_theme": "Graphite-Dark-compact",
        "gtk_icon": "Papirus-Dark",
        "kvantum": "KvAdaptaDark#"
    },
    "sakura": {
        "name": "Sakura",
        "description": "Delicate Blossom Rose, Dusty Mauve & Spring Twilight",
        "bg": "#181016",
        "bg_alt": "#21161e",
        "surface": "#261a23",
        "surface_soft": "#31222e",
        "surface_elevated": "#3c2a38",
        "border": "#4d3447",
        "text": "#fae3e7",
        "text_dim": "#b58d99",
        "accent": "#f29ca9",
        "accent_alt": "#7ea192",
        "success": "#7ea192",
        "warning": "#d9a566",
        "critical": "#db536a",
        "gtk_theme": "Graphite-Dark-compact",
        "gtk_icon": "Papirus-Dark",
        "kvantum": "KvMojave#"
    },
    "cornerstore": {
        "name": "Cornerstore",
        "description": "Lo-Fi Vintage Coffee, Warm Mustard Amber & Retro Teal",
        "bg": "#14100c",
        "bg_alt": "#1c1712",
        "surface": "#221c16",
        "surface_soft": "#2c241c",
        "surface_elevated": "#372e23",
        "border": "#463a2c",
        "text": "#ede0cb",
        "text_dim": "#aa957c",
        "accent": "#e8a84a",
        "accent_alt": "#528882",
        "success": "#70966a",
        "warning": "#e8a84a",
        "critical": "#c45847",
        "gtk_theme": "Graphite-Dark-compact",
        "gtk_icon": "Papirus-Dark",
        "kvantum": "KvMojave#"
    },
    "neon": {
        "name": "Neon",
        "description": "Pitch OLED Cyberpunk, High-Voltage Cyan & Hot Magenta",
        "bg": "#020406",
        "bg_alt": "#070c12",
        "surface": "#0c131c",
        "surface_soft": "#121c2a",
        "surface_elevated": "#182638",
        "border": "#21364f",
        "text": "#e2f8ff",
        "text_dim": "#7098ab",
        "accent": "#00f0ff",
        "accent_alt": "#ff007f",
        "success": "#00ff9f",
        "warning": "#ffe600",
        "critical": "#ff0055",
        "gtk_theme": "Graphite-Dark-compact",
        "gtk_icon": "Papirus-Dark",
        "kvantum": "KvMojave#"
    }
}

# -----------------------------------------------------------------------------
# 2. DETERMINISTIC WALLPAPER MAPPINGS
# -----------------------------------------------------------------------------
WALLPAPER_MAPPING = {
    # Monochrome (Achromatic, Grayscale, Minimalist Stone)
    'themes/monochrome/wallpapers/1.png': 'monochrome',
    'themes/monochrome/wallpapers/2.jpg': 'monochrome',
    'themes/monochrome/wallpapers/3.png': 'monochrome',
    'themes/monochrome/wallpapers/4.png': 'monochrome',
    'themes/monochrome/wallpapers/5.png': 'monochrome',
    'themes/sakura/wallpapers/4.jpg': 'monochrome',
    'themes/solstice/wallpapers/3.png': 'monochrome',

    # Afterglow (Warm Sunset Horizon, Golden Hour, Terracotta)
    'themes/solstice/wallpapers/4.png': 'afterglow',
    'themes/neon/wallpapers/10.jpg': 'afterglow',
    'themes/sakura/wallpapers/7.jpg': 'afterglow',
    'themes/afterglow/wallpapers/3.jpg': 'afterglow',

    # Cornerstore (Lo-Fi Vintage, 80s/90s City, Warm Mustard & Sepia)
    'themes/cornerstore/wallpapers/1.png': 'cornerstore',
    'themes/cornerstore/wallpapers/2.jpg': 'cornerstore',
    'themes/solstice/wallpapers/5.jpeg': 'cornerstore',
    'themes/neon/wallpapers/6.jpg': 'cornerstore',
    'themes/monochrome/wallpapers/10.jpg': 'cornerstore',
    'themes/monochrome/wallpapers/9.png': 'cornerstore',
    'themes/sakura/wallpapers/2.jpeg': 'cornerstore',
    'themes/sakura/wallpapers/9.jpg': 'cornerstore',

    # Forest (Lush Pine Evergreen, Pastoral Sage & Meadow Gold)
    'themes/storybook/wallpapers/1.jpg': 'forest',
    'themes/storybook/wallpapers/2.jpg': 'forest',
    'themes/storybook/wallpapers/3.png': 'forest',
    'themes/storybook/wallpapers/4.jpeg': 'forest',
    'themes/serenity/wallpapers/10.jpg': 'forest',
    'themes/monochrome/wallpapers/8.jpg': 'forest',
    'themes/neon/wallpapers/1.png': 'forest',
    'themes/sakura/wallpapers/3.jpeg': 'forest',

    # Sakura (Blossom Rose Petal, Dusty Mauve & Spring Twilight)
    'themes/sakura/wallpapers/1.png': 'sakura',
    'themes/serenity/wallpapers/9.jpg': 'sakura',

    # Twilight (Velvet Violet, Amethyst Sky & Synth Dusk)
    'themes/afterglow/wallpapers/1.png': 'twilight',
    'themes/afterglow/wallpapers/2.jpg': 'twilight',
    'themes/afterglow/wallpapers/4.jpg': 'twilight',
    'themes/afterglow/wallpapers/5.jpg': 'twilight',
    'themes/solstice/wallpapers/2.png': 'twilight',
    'themes/solstice/wallpapers/12.jpg': 'twilight',
    'themes/moonlit/wallpapers/1.jpg': 'twilight',
    'themes/moonlit/wallpapers/9.jpg': 'twilight',
    'themes/neon/wallpapers/7.jpg': 'twilight',
    'themes/neon/wallpapers/12.jpg': 'twilight',
    'themes/sakura/wallpapers/5.jpg': 'twilight',

    # Serenity (Glacial Ice, Crisp Arctic Cyan & Alpine Waters)
    'themes/serenity/wallpapers/1.jpg': 'serenity',
    'themes/serenity/wallpapers/2.jpg': 'serenity',
    'themes/serenity/wallpapers/3.jpg': 'serenity',
    'themes/serenity/wallpapers/4.jpg': 'serenity',
    'themes/serenity/wallpapers/5.jpg': 'serenity',
    'themes/serenity/wallpapers/6.png': 'serenity',
    'themes/serenity/wallpapers/8.jpg': 'serenity',
    'themes/storybook/wallpapers/5.png': 'serenity',
    'themes/neon/wallpapers/14.jpg': 'serenity',
    'themes/neon/wallpapers/5.jpg': 'serenity',
    'themes/moonlit/wallpapers/5.png': 'serenity',
    'themes/solstice/wallpapers/11.png': 'serenity',

    # Neon (Pitch OLED Black, Cyberpunk Electric Cyan & Hot Magenta)
    'themes/neon/wallpapers/3.png': 'neon',
    'themes/neon/wallpapers/4.png': 'neon',
    'themes/neon/wallpapers/8.jpg': 'neon',
    'themes/neon/wallpapers/13.jpg': 'neon',
    'themes/solstice/wallpapers/10.png': 'neon',
    'themes/moonlit/wallpapers/10.jpg': 'neon',
    'themes/sakura/wallpapers/6.jpg': 'neon',

    # Moonlit (Nocturnal Inky Navy, Ocean Midnight & Cold Starlight)
    'themes/moonlit/wallpapers/2.jpg': 'moonlit',
    'themes/moonlit/wallpapers/3.jpg': 'moonlit',
    'themes/moonlit/wallpapers/4.png': 'moonlit',
    'themes/moonlit/wallpapers/6.png': 'moonlit',
    'themes/moonlit/wallpapers/7.png': 'moonlit',
    'themes/moonlit/wallpapers/11.jpg': 'moonlit',
    'themes/neon/wallpapers/2.jpg': 'moonlit',
    'themes/neon/wallpapers/11.jpg': 'moonlit',
    'themes/sakura/wallpapers/8.jpg': 'moonlit',
    'themes/serenity/wallpapers/7.png': 'moonlit',
    'themes/solstice/wallpapers/1.png': 'moonlit',
    'themes/solstice/wallpapers/6.png': 'moonlit',
    'themes/solstice/wallpapers/7.png': 'moonlit',
    'themes/solstice/wallpapers/8.png': 'moonlit',
    'themes/solstice/wallpapers/9.png': 'moonlit',
}

GIF_MAPPINGS = [
    ('themes/monochrome/wallpapers/6_preview.png', 'themes/monochrome/wallpapers/gifs/6.gif', 'monochrome'),
    ('themes/monochrome/wallpapers/7_preview.png', 'themes/monochrome/wallpapers/gifs/7.gif', 'monochrome'),
    ('themes/moonlit/wallpapers/8_preview.png', 'themes/moonlit/wallpapers/gifs/8.gif', 'twilight'),
    ('themes/neon/wallpapers/9_preview.png', 'themes/neon/wallpapers/gifs/9.gif', 'neon'),
]

# -----------------------------------------------------------------------------
# HELPERS
# -----------------------------------------------------------------------------
def hex_to_rgb(hex_str):
    h = hex_str.lstrip('#')
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))

def rgba_str(hex_str, alpha):
    r, g, b = hex_to_rgb(hex_str)
    return f"rgba({r}, {g}, {b}, {alpha:.2f})"

def generate_colors_json(t):
    return {
        "background": t["bg"],
        "backgroundAlt": t["bg_alt"],
        "overlay": rgba_str(t["bg"], 0.60),
        "surface": t["surface"],
        "surfaceSoft": t["surface_soft"],
        "surfaceMuted": t["surface_soft"],
        "surfaceElevated": t["surface_elevated"],
        "panel": rgba_str(t["surface"], 0.88),
        "solid": rgba_str(t["surface"], 0.95),
        "soft": rgba_str(t["bg"], 0.70),
        "tip": rgba_str(t["bg"], 0.96),
        "text": t["text"],
        "textDim": t["text_dim"],
        "textFaint": rgba_str(t["text_dim"], 0.55),
        "textAccent": t["bg"],
        "accent": t["accent"],
        "accentSoft": rgba_str(t["accent"], 0.16),
        "accentAlt": t["accent_alt"],
        "accentAltSoft": rgba_str(t["accent_alt"], 0.16),
        "success": t["success"],
        "successSoft": rgba_str(t["success"], 0.16),
        "warning": t["warning"],
        "critical": t["critical"],
        "criticalSoft": rgba_str(t["critical"], 0.16),
        "selectedBackground": t["accent"],
        "selectedText": t["bg"],
        "hover": rgba_str(t["accent"], 0.08),
        "border": t["border"],
        "shadow": "rgba(0, 0, 0, 0.28)",
        "shadowTip": "rgba(0, 0, 0, 0.34)"
    }

def generate_kitty_conf(t):
    return f"""foreground            {t["text"]}
background            {t["bg"]}
selection_foreground  {t["bg"]}
selection_background  {t["accent"]}
url_color             {t["accent_alt"]}
cursor                {t["text"]}
cursor_text_color     {t["bg"]}

# black
color0   {t["bg"]}
color8   {t["text_dim"]}

# red
color1   {t["critical"]}
color9   {t["critical"]}

# green
color2   {t["success"]}
color10  {t["success"]}

# yellow
color3   {t["warning"]}
color11  {t["warning"]}

# blue
color4  {t["accent_alt"]}
color12 {t["accent_alt"]}

# magenta
color5   {t["accent"]}
color13  {t["accent"]}

# cyan
color6   {t["accent"]}
color14  {t["accent"]}

# white
color7   {t["text"]}
color15  {t["text"]}
"""

def generate_hypr_lua(t):
    acc = t["accent"].lstrip("#")
    alt = t["accent_alt"].lstrip("#")
    bg = t["bg"].lstrip("#")
    return f"""hl.config({{
    general = {{
        col = {{
            active_border = {{
                colors = {{"rgba({acc}ee)", "rgba({alt}ee)"}},
                angle = 45
            }},
            inactive_border = "rgba(595959aa)"
        }}
    }},

    decoration = {{shadow = {{color = 0xee{bg}}}}}
}})
"""

def generate_theme_env(t):
    return f"""GTK_THEME="{t["gtk_theme"]}"
GTK_ICON_THEME="{t["gtk_icon"]}"
GTK_CURSOR_THEME="macOS"
GTK_FONT="Adwaita Sans Regular 11"

QT_STYLE="kvantum-dark"
KVANTUM_THEME="{t["kvantum"]}"
"""

# -----------------------------------------------------------------------------
# MAIN MIGRATION
# -----------------------------------------------------------------------------
def main():
    print(">>> 1. Creating staging directory...")
    if os.path.exists(STAGING_DIR):
        shutil.rmtree(STAGING_DIR)
    os.makedirs(STAGING_DIR, exist_ok=True)

    # 1. Initialize all theme directories and config files
    for key, t in THEMES.items():
        theme_path = os.path.join(STAGING_DIR, key)
        colors_path = os.path.join(theme_path, "colors")
        hypr_path = os.path.join(theme_path, "hypr")
        wallpapers_path = os.path.join(theme_path, "wallpapers")

        os.makedirs(colors_path, exist_ok=True)
        os.makedirs(hypr_path, exist_ok=True)
        os.makedirs(wallpapers_path, exist_ok=True)

        # Write colors.json
        with open(os.path.join(colors_path, "colors.json"), "w") as f:
            json.dump(generate_colors_json(t), f, indent=4)

        # Write kitty_colors.conf
        with open(os.path.join(colors_path, "kitty_colors.conf"), "w") as f:
            f.write(generate_kitty_conf(t))

        # Write hypr/theme_decorations.lua
        with open(os.path.join(hypr_path, "theme_decorations.lua"), "w") as f:
            f.write(generate_hypr_lua(t))

        # Write theme.env
        with open(os.path.join(theme_path, "theme.env"), "w") as f:
            f.write(generate_theme_env(t))

    print(">>> 2. Copying and organizing wallpapers...")
    theme_wall_counts = {k: 0 for k in THEMES}

    # Copy static wallpapers
    for src_rel, target_theme in WALLPAPER_MAPPING.items():
        src_path = os.path.join(ROOT_DIR, src_rel)
        theme_wall_counts[target_theme] += 1
        idx = theme_wall_counts[target_theme]
        ext = os.path.splitext(src_path)[1]
        dest_filename = f"{idx}{ext}"
        dest_path = os.path.join(STAGING_DIR, target_theme, "wallpapers", dest_filename)
        shutil.copy2(src_path, dest_path)

    # Copy gifs and previews
    for prev_rel, gif_rel, target_theme in GIF_MAPPINGS:
        prev_src = os.path.join(ROOT_DIR, prev_rel)
        gif_src = os.path.join(ROOT_DIR, gif_rel)

        theme_wall_counts[target_theme] += 1
        idx = theme_wall_counts[target_theme]

        gifs_dir = os.path.join(STAGING_DIR, target_theme, "wallpapers", "gifs")
        os.makedirs(gifs_dir, exist_ok=True)

        dest_prev = os.path.join(STAGING_DIR, target_theme, "wallpapers", f"{idx}_preview.png")
        dest_gif = os.path.join(gifs_dir, f"{idx}.gif")

        shutil.copy2(prev_src, dest_prev)
        shutil.copy2(gif_src, dest_gif)

    # Print summary of wallpapers per theme
    print("\n=== Final Wallpaper Distribution ===")
    for key, count in sorted(theme_wall_counts.items(), key=lambda x: -x[1]):
        print(f"  {key:12}: {count:2d} wallpapers")

    # 3. Generating blur cache for fast switching
    print("\n>>> 3. Generating blur cache...")
    os.makedirs(CACHE_DIR, exist_ok=True)
    # Clean up blur cache for old themes
    for d in glob.glob(os.path.join(CACHE_DIR, "*")):
        shutil.rmtree(d, ignore_errors=True)

    for key in THEMES:
        t_cache = os.path.join(CACHE_DIR, key)
        os.makedirs(t_cache, exist_ok=True)
        t_walls = os.path.join(STAGING_DIR, key, "wallpapers")
        for img in sorted(os.listdir(t_walls)):
            img_path = os.path.join(t_walls, img)
            if not os.path.isfile(img_path) or "_preview" in img:
                continue
            ext = os.path.splitext(img)[1].lower()
            if ext not in [".jpg", ".jpeg", ".png", ".webp"]:
                continue
            try:
                with Image.open(img_path) as im:
                    # Resize slightly for fast blur and efficient memory
                    blurred = im.convert("RGB").filter(ImageFilter.GaussianBlur(radius=40))
                    blur_out = os.path.join(t_cache, img)
                    blurred.save(blur_out)
            except Exception as e:
                print(f"  Warning blurring {img_path}: {e}")

    # 4. Atomically swap themes
    print("\n>>> 4. Swapping new themes into production...")
    # Remove existing themes directory
    shutil.rmtree(THEMES_DIR)
    shutil.copytree(STAGING_DIR, THEMES_DIR)
    shutil.rmtree(STAGING_DIR)

    print("\n>>> Migration successfully completed!")

if __name__ == "__main__":
    main()
