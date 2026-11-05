pragma Singleton

import QtQuick
import Quickshell

QtObject {
    id: root

    readonly property string homeDir: (Quickshell.env("HOME") && Quickshell.env("HOME") !== "") ? Quickshell.env("HOME") : "/home/rajat"
    readonly property string themeSwitcherDir: homeDir + "/.config/theme-switcher"
    readonly property string currentColorsJson: themeSwitcherDir + "/state/current_colors.json"
    readonly property string activeThemeEnv: themeSwitcherDir + "/state/active_theme.env"
    readonly property string currentWallpaper: themeSwitcherDir + "/state/current_wallpaper"
    readonly property string themesDir: themeSwitcherDir + "/themes"
    readonly property string themeSwitcherBin: themeSwitcherDir + "/scripts/theme_switcher"
    readonly property string wallpaperPreprocessorBin: themeSwitcherDir + "/scripts/wallpaper_preprocess"
}
