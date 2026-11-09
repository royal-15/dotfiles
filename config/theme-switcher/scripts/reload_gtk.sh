#!/usr/bin/env bash
#
# reload_gtk.sh - Live reload GTK 3 & GTK 4/Libadwaita applications without restart
#

set -euo pipefail

log() {
    printf '[reload_gtk] %s\n' "$*"
}

# 1. In-place touch to notify any GFileMonitor watches
touch_gtk_css() {
    for css_file in \
        "$HOME/.local/share/themes/ThemeSwitcherDynamic-A/gtk-3.0/gtk.css" \
        "$HOME/.local/share/themes/ThemeSwitcherDynamic-B/gtk-3.0/gtk.css" \
        "$HOME/.config/gtk-4.0/gtk.css" \
        "$HOME/.config/gtk-3.0/settings.ini"; do
        if [[ -f "$css_file" ]]; then
            touch "$css_file"
        fi
    done
}

# 2. Dynamic GTK theme alternation: forces running GTK 3 (like Thunar) & GTK 4 apps to reload stylesheet live
bounce_gsettings_theme() {
    local target_theme="ThemeSwitcherDynamic-A"

    if command -v gsettings >/dev/null 2>&1; then
        local current_theme
        current_theme="$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null | tr -d "'\"" || true)"
        if [[ "$current_theme" == "ThemeSwitcherDynamic-A" ]]; then
            target_theme="ThemeSwitcherDynamic-B"
        else
            target_theme="ThemeSwitcherDynamic-A"
        fi

        gsettings set org.gnome.desktop.interface gtk-theme "$target_theme" 2>/dev/null || true
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
        log "GSettings theme set to $target_theme -> GTK live styles refreshed"
    fi

    # Keep GTK 3 fallback settings.ini in sync
    local settings_ini="$HOME/.config/gtk-3.0/settings.ini"
    if [[ -f "$settings_ini" ]]; then
        if grep -q "^gtk-theme-name=" "$settings_ini" 2>/dev/null; then
            sed -i "s/^gtk-theme-name=.*/gtk-theme-name=$target_theme/" "$settings_ini" 2>/dev/null || true
        elif grep -q "^\[Settings\]" "$settings_ini" 2>/dev/null; then
            sed -i "/^\[Settings\]/a gtk-theme-name=$target_theme" "$settings_ini" 2>/dev/null || true
        else
            printf "[Settings]\ngtk-theme-name=%s\n" "$target_theme" >> "$settings_ini"
        fi
    fi

    # Update xfconf xsettings channel if active (for XFCE/Thunar)
    if command -v xfconf-query >/dev/null 2>&1; then
        xfconf-query -c xsettings -p /Net/ThemeName -s "$target_theme" -n -t string 2>/dev/null || true
    fi
}

# 3. Reload xsettingsd if active
reload_xsettingsd() {
    if command -v pgrep >/dev/null 2>&1 && pgrep -x xsettingsd >/dev/null 2>&1; then
        pkill -HUP -x xsettingsd 2>/dev/null || true
        log "xsettingsd signaled with SIGHUP"
    fi
}

main() {
    touch_gtk_css
    bounce_gsettings_theme
    reload_xsettingsd
    log "GTK live reload complete"
}

main "$@"
