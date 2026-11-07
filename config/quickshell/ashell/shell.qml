import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs
import qs.components
import qs.feature.bar
import qs.feature.network
import qs.feature.powerprofile
import qs.feature.launcher
import qs.feature.notifications
import qs.feature.osd
import qs.feature.media
import qs.feature.theme
import qs.feature.clipboard
import qs.feature.commandpalette

ShellRoot {
    IpcHandler {
        target: "network"

        function openWifi() {
            NetworkCenterRouter.open("wifi");
        }

        function openBluetooth() {
            NetworkCenterRouter.open("bluetooth");
        }
    }

    IpcHandler {
        target: "powerprofile"

        function open() {
            PowerProfileRouter.open();
        }
    }

    IpcHandler {
        target: "launcher"

        function open() {
            LauncherRouter.open();
        }

        function close() {
            LauncherRouter.close();
        }

        function toggle() {
            LauncherRouter.toggle();
        }
    }

    IpcHandler {
        target: "notifications"

        function open() {
            NotificationCenterRouter.open();
        }

        function close() {
            NotificationCenterRouter.close();
        }

        function toggle() {
            NotificationCenterRouter.toggle();
        }

        function toggleDnd() {
            NotificationService.toggleDnd();
        }

        function clearAll() {
            NotificationService.clearAll();
        }
    }

    IpcHandler {
        target: "osd"

        function volumeUp() {
            OsdService.changeVolume(0.05);
        }

        function volumeDown() {
            OsdService.changeVolume(-0.05);
        }

        function toggleMute() {
            OsdService.toggleMute();
        }

        function showVolume() {
            OsdService.showVolume();
        }
    }

    IpcHandler {
        target: "media"

        function open() {
            MediaRouter.open();
        }

        function close() {
            MediaRouter.close();
        }

        function toggle() {
            MediaRouter.toggle();
        }

        function openPanel() {
            MediaRouter.open();
        }

        function closePanel() {
            MediaRouter.close();
        }

        function togglePanel() {
            MediaRouter.toggle();
        }

        function playPause() {
            MediaRouter.playPause();
        }

        function next() {
            MediaRouter.next();
        }

        function previous() {
            MediaRouter.previous();
        }
    }

    IpcHandler {
        target: "mediapanel"

        function open() {
            MediaRouter.open();
        }

        function close() {
            MediaRouter.close();
        }

        function toggle() {
            MediaRouter.toggle();
        }
    }

    IpcHandler {
        target: "theme"

        function open() {
            ThemeRouter.open("hub");
        }

        function close() {
            ThemeRouter.close();
        }

        function toggle() {
            ThemeRouter.toggle("hub");
        }

        function openThemes() {
            ThemeRouter.open("themes");
        }

        function openWallpapers() {
            ThemeRouter.open("wallpapers");
        }

        function applyTheme(name: string) {
            ThemeService.loadThemeByName(name);
        }

        function applyWallpaper(name: string) {
            ThemeService.setWallpaperFromSystem(name);
        }

        function nextWallpaper() {
            ThemeService.nextWallpaper();
        }
    }

    IpcHandler {
        target: "themestudio"

        function open() {
            ThemeRouter.open("hub");
        }

        function close() {
            ThemeRouter.close();
        }

        function toggle() {
            ThemeRouter.toggle("hub");
        }

        function openThemes() {
            ThemeRouter.open("themes");
        }

        function openWallpapers() {
            ThemeRouter.open("wallpapers");
        }

        function applyTheme(name: string) {
            ThemeService.loadThemeByName(name);
        }

        function applyWallpaper(name: string) {
            ThemeService.setWallpaperFromSystem(name);
        }

        function nextWallpaper() {
            ThemeService.nextWallpaper();
        }
    }

    IpcHandler {
        target: "themeStudio"

        function open() {
            ThemeRouter.open("hub");
        }

        function close() {
            ThemeRouter.close();
        }

        function toggle() {
            ThemeRouter.toggle("hub");
        }

        function openThemes() {
            ThemeRouter.open("themes");
        }

        function openWallpapers() {
            ThemeRouter.open("wallpapers");
        }

        function applyTheme(name: string) {
            ThemeService.loadThemeByName(name);
        }

        function applyWallpaper(name: string) {
            ThemeService.setWallpaperFromSystem(name);
        }

        function nextWallpaper() {
            ThemeService.nextWallpaper();
        }
    }

    IpcHandler {
        target: "clipboard"

        function open() {
            ClipboardRouter.open();
        }

        function close() {
            ClipboardRouter.close();
        }

        function toggle() {
            ClipboardRouter.toggle();
        }

        function wipe() {
            ClipboardService.wipe();
        }

        function refresh() {
            ClipboardService.refresh();
        }
    }

    IpcHandler {
        target: "commandpalette"

        function open() {
            CommandPaletteRouter.open();
        }

        function close() {
            CommandPaletteRouter.close();
        }

        function toggle() {
            CommandPaletteRouter.toggle();
        }

        function refresh() {
            CommandPaletteService.loadData();
        }
    }

    IpcHandler {
        target: "palette"

        function open() {
            CommandPaletteRouter.open();
        }

        function close() {
            CommandPaletteRouter.close();
        }

        function toggle() {
            CommandPaletteRouter.toggle();
        }

        function refresh() {
            CommandPaletteService.loadData();
        }
    }

    Variants {
        model:Quickshell.screens

        delegate: Bar{}

    }

}
