pragma Singleton

import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import qs

Scope {
    id: root

    FileView {
        id: currentColorsFileView
        path: Paths.currentColorsJson
        blockLoading: true
        blockAllReads: true
        watchChanges: true
        onFileChanged: {
            if (!root.isSwitchingTheme) {
                currentColorsFileView.reload();
            }
        }
        onTextChanged: {
            if (!root.isSwitchingTheme) {
                root.reloadCurrentColors();
            }
        }
    }

    FileView {
        id: activeEnvFileView
        path: Paths.activeThemeEnv
        blockLoading: true
        blockAllReads: true
        watchChanges: true
        onFileChanged: {
            if (!root.isSwitchingTheme && !root.isSwitchingWallpaper) {
                activeEnvFileView.reload();
            }
        }
        onTextChanged: {
            if (!root.isSwitchingTheme && !root.isSwitchingWallpaper) {
                root.reloadActiveEnv();
            }
        }
    }

    FileView {
        id: dynamicThemeReader
        blockAllReads: true
        blockLoading: true
        printErrors: false
    }

    // Secondary non-blocking polling fallback: catches external changes to active_theme.env
    // even if Linux inotify drops file watch on atomic renames (mv -f) or broken symlinks.
    // Uses native C++ FileView reload without spawning shell processes.
    Timer {
        id: envPollerTimer
        interval: 3000
        running: true
        repeat: true
        onTriggered: {
            if (!root.isSwitchingTheme && !root.isSwitchingWallpaper) {
                activeEnvFileView.reload();
            }
        }
    }

    function parseEnv(text) {
        if (!text || text.trim() === "")
            return {};
        try {
            const lines = text.split("\n");
            const map = {};
            for (let i = 0; i < lines.length; i++) {
                const line = lines[i].trim();
                if (!line || line.startsWith("#"))
                    continue;
                const parts = line.split("=");
                if (parts.length >= 2) {
                    map[parts[0].trim()] = parts.slice(1).join("=").trim();
                }
            }
            return map;
        } catch (e) {
            console.warn("[ThemeService] Failed to parse env: " + e);
            return {};
        }
    }

    function parseJson(text, source) {
        if (!text || text.trim() === "")
            return null;
        try {
            return JSON.parse(text);
        } catch (e) {
            const snippet = text.length > 80 ? text.slice(0, 80) + "..." : text;
            console.warn("[ThemeService] Failed to parse JSON at " + source + ": " + e + " (raw: " + snippet + ")");
            return null;
        }
    }

    function readDynamicJsonSync(filePath) {
        if (!filePath || filePath === "")
            return null;
        try {
            if (dynamicThemeReader.path !== filePath) {
                dynamicThemeReader.path = filePath;
            }
            dynamicThemeReader.reload();
            const text = dynamicThemeReader.text();
            return parseJson(text, filePath);
        } catch (e) {
            console.warn("[ThemeService] Failed to read dynamic JSON at " + filePath + ": " + e);
            return null;
        }
    }

    // In-memory theme palette cache (themeName -> parsed colors object)
    // Ensures theme switching is a 0ms memory lookup with zero synchronous disk I/O.
    property var themePaletteCache: ({})

    function getThemePalette(name) {
        if (!name || name === "")
            return null;
        if (root.themePaletteCache[name]) {
            return root.themePaletteCache[name];
        }
        const colorsPath = Paths.themesDir + "/" + name + "/colors/colors.json";
        const colors = readDynamicJsonSync(colorsPath);
        if (colors && typeof colors === "object") {
            root.themePaletteCache[name] = colors;
            return colors;
        }
        return null;
    }

    // Deep palette equality comparator to prevent redundant QML binding re-evaluations
    function arePalettesEqual(a, b) {
        if (a === b)
            return true;
        if (!a || !b)
            return false;
        const keysA = Object.keys(a);
        const keysB = Object.keys(b);
        if (keysA.length !== keysB.length)
            return false;
        for (let i = 0; i < keysA.length; i++) {
            const k = keysA[i];
            if (a[k] !== b[k])
                return false;
        }
        return true;
    }

    // Frame-0 synchronous initial loading
    property var activeEnv: {
        const text = activeEnvFileView.text();
        return parseEnv(text);
    }

    property string activeTheme: activeEnv.ACTIVE_THEME ? activeEnv.ACTIVE_THEME : ""
    property string activeWallpaper: activeEnv.ACTIVE_WALLPAPER ? activeEnv.ACTIVE_WALLPAPER : ""

    // Imperative state for active palette
    property var currentColors: ({})

    property var reportedMissingTokens: ({})

    function reportMissingToken(tokenName, fallback) {
        const theme = root.activeTheme !== "" ? root.activeTheme : "active_theme";
        const key = theme + ":" + tokenName;
        if (!root.reportedMissingTokens[key]) {
            root.reportedMissingTokens[key] = true;
            console.warn("[Colors] Missing color token '" + tokenName + "' in theme '" + theme + "'. Using fallback: " + fallback);
        }
    }

    function getColor(tokenName, fallback) {
        const colors = root.currentColors;
        if (colors && colors[tokenName] !== undefined && colors[tokenName] !== null && colors[tokenName] !== "") {
            return colors[tokenName];
        }
        root.reportMissingToken(tokenName, fallback);
        return fallback;
    }

    // Updates currentColors with strict deduplication to eliminate binding churn
    function updateCurrentColors(newColors) {
        if (!newColors || typeof newColors !== "object" || Object.keys(newColors).length === 0)
            return false;
        if (root.arePalettesEqual(root.currentColors, newColors))
            return false;
        root.currentColors = newColors;
        return true;
    }

    // Compares card/filename with active wallpaper, cleanly reconciling animated GIF previews
    // (e.g. "6_preview.png" vs "6.gif")
    function isWallpaperActive(name, target) {
        const active = target !== undefined ? target : root.activeWallpaper;
        if (!name || !active)
            return false;
        if (name === active)
            return true;
        const nameBase = name.replace(/_preview\.[^.]+$/, "").replace(/\.[^.]+$/, "");
        const activeBase = active.replace(/_preview\.[^.]+$/, "").replace(/\.[^.]+$/, "");
        return nameBase === activeBase;
    }

    property var availableThemes: []
    property var availableWallpapers: []

    property bool isSwitchingTheme: false
    property bool isSwitchingWallpaper: false

    Process {
        id: themeProcess
        stderr: SplitParser {
            onRead: data => {
                if (data && data.trim() !== "") {
                    console.warn("[ThemeService:themeProcess] " + data.trim());
                }
            }
        }
        onExited: (exitCode, exitStatus) => {
            root.isSwitchingTheme = false;
            if (exitCode !== 0) {
                console.error("[ThemeService] Theme switch command failed with code " + exitCode + ", status " + exitStatus);
            }
            activeEnvFileView.reload();
            currentColorsFileView.reload();
        }
    }

    Process {
        id: wallpaperProcess
        stderr: SplitParser {
            onRead: data => {
                if (data && data.trim() !== "") {
                    console.warn("[ThemeService:wallpaperProcess] " + data.trim());
                }
            }
        }
        onExited: (exitCode, exitStatus) => {
            root.isSwitchingWallpaper = false;
            if (exitCode !== 0) {
                console.error("[ThemeService] Wallpaper switch command failed with code " + exitCode + ", status " + exitStatus);
            }
            activeEnvFileView.reload();
        }
    }

    FolderListModel {
        id: themesModel
        folder: "file://" + Paths.themesDir
        showDirs: true
        showFiles: false
        showDotAndDotDot: false
        onStatusChanged: {
            if (status === FolderListModel.Ready) {
                root.refreshThemes();
            }
        }
        onCountChanged: {
            if (status === FolderListModel.Ready) {
                root.refreshThemes();
            }
        }
    }

    FolderListModel {
        id: wallpapersModel
        folder: root.activeTheme !== "" ? ("file://" + Paths.themesDir + "/" + root.activeTheme + "/wallpapers") : ""
        showDirs: false
        showFiles: true
        showDotAndDotDot: false
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.PNG", "*.JPG", "*.JPEG", "*.WEBP"]
        onStatusChanged: {
            if (status === FolderListModel.Ready) {
                root.refreshWallpapers();
            }
        }
        onCountChanged: {
            if (status === FolderListModel.Ready) {
                root.refreshWallpapers();
            }
        }
    }

    function reloadCurrentColors() {
        const text = currentColorsFileView.text();
        const colors = parseJson(text, currentColorsFileView.path);
        if (colors && typeof colors === "object") {
            root.updateCurrentColors(colors);
        }
    }

    function reloadActiveEnv() {
        const text = activeEnvFileView.text();
        const env = parseEnv(text);
        root.activeEnv = env;
        if (env.ACTIVE_THEME && env.ACTIVE_THEME !== root.activeTheme && !root.isSwitchingTheme) {
            root.loadThemeByName(env.ACTIVE_THEME);
        }
        if (env.ACTIVE_WALLPAPER && !root.isWallpaperActive(root.activeWallpaper, env.ACTIVE_WALLPAPER) && !root.isSwitchingWallpaper) {
            root.activeWallpaper = env.ACTIVE_WALLPAPER;
        }
    }

    function refreshThemes() {
        const count = themesModel.count;
        const list = [];
        for (let i = 0; i < count; i++) {
            const name = themesModel.get(i, "fileName");
            if (!name || name.startsWith("."))
                continue;

            const colors = getThemePalette(name);
            if (!colors) {
                console.warn("[ThemeService] Failed to load or parse colors.json for theme: " + name);
            }

            function resolvePreviewColor(c, key, fallback) {
                if (c && c[key] !== undefined && c[key] !== null && c[key] !== "") {
                    return c[key];
                }
                return fallback;
            }

            const preview = {
                background: resolvePreviewColor(colors, "background", "#0a0b0d"),
                surfaceSoft: resolvePreviewColor(colors, "surfaceSoft", "#1d1e20"),
                accent: resolvePreviewColor(colors, "accent", "#C0BFB2"),
                accentAlt: resolvePreviewColor(colors, "accentAlt", "#AEB2AB")
            };

            list.push({
                name: name,
                preview: preview
            });
        }

        list.sort((a, b) => a.name.localeCompare(b.name));

        // Avoid re-allocating array reference if themes list is identical
        if (root.availableThemes && root.availableThemes.length === list.length && list.length > 0) {
            let isIdentical = true;
            for (let j = 0; j < list.length; j++) {
                const prev = root.availableThemes[j];
                const curr = list[j];
                if (prev.name !== curr.name ||
                    !prev.preview || !curr.preview ||
                    prev.preview.background !== curr.preview.background ||
                    prev.preview.accent !== curr.preview.accent) {
                    isIdentical = false;
                    break;
                }
            }
            if (isIdentical)
                return;
        }

        root.availableThemes = list;
    }

    function refreshWallpapers() {
        if (wallpapersModel.status !== FolderListModel.Ready)
            return;
        const currentFolder = wallpapersModel.folder.toString();
        const expectedFolder = "file://" + Paths.themesDir + "/" + root.activeTheme + "/wallpapers";
        if (currentFolder !== expectedFolder)
            return;

        const count = wallpapersModel.count;
        const list = [];
        for (let i = 0; i < count; i++) {
            const name = wallpapersModel.get(i, "fileName");
            if (!name || name.startsWith("."))
                continue;

            const filePath = Paths.themesDir + "/" + root.activeTheme + "/wallpapers/" + name;
            list.push({
                name: name,
                path: filePath,
                fullUrl: "file://" + filePath,
                isPreview: name.indexOf("_preview") >= 0
            });
        }

        list.sort((a, b) => {
            const numA = parseInt(a.name, 10);
            const numB = parseInt(b.name, 10);
            if (!isNaN(numA) && !isNaN(numB))
                return numA - numB;
            return a.name.localeCompare(b.name);
        });

        // Avoid re-allocating array reference if wallpapers list is identical
        if (root.availableWallpapers && root.availableWallpapers.length === list.length && list.length > 0) {
            let isIdentical = true;
            for (let j = 0; j < list.length; j++) {
                if (root.availableWallpapers[j].name !== list[j].name) {
                    isIdentical = false;
                    break;
                }
            }
            if (isIdentical)
                return;
        }

        root.availableWallpapers = list;

        // If activeWallpaper is empty or belongs to previous theme, default to the first wallpaper
        if (list.length > 0 && (root.activeWallpaper === "" || !list.some(entry => root.isWallpaperActive(entry.name)))) {
            const firstRegular = list.find(entry => !entry.isPreview);
            root.activeWallpaper = firstRegular ? firstRegular.name : list[0].name;
        }
    }

    function setWallpaperFromSystem(name) {
        if (!name || name === "")
            return;
        if (root.isWallpaperActive(name, root.activeWallpaper))
            return;
        root.activeWallpaper = name;
        activeEnvFileView.reload();
    }

    function loadThemeByName(name) {
        if (!name || name === "" || !/^[A-Za-z0-9_.-]+$/.test(name))
            return;

        const colors = getThemePalette(name);
        if (colors && typeof colors === "object") {
            root.updateCurrentColors(colors);
        }

        const themeChanged = (root.activeTheme !== name);
        if (themeChanged) {
            root.activeTheme = name;
            root.reportedMissingTokens = ({});

            const targetFolder = "file://" + Paths.themesDir + "/" + name + "/wallpapers";
            if (wallpapersModel.folder.toString() === targetFolder) {
                root.refreshWallpapers();
            } else {
                wallpapersModel.folder = targetFolder;
            }
        }

        if (!root.isSwitchingTheme) {
            currentColorsFileView.reload();
            activeEnvFileView.reload();
        }
    }

    function switchTheme(name) {
        if (!name || name === "" || !/^[A-Za-z0-9_.-]+$/.test(name) || root.isSwitchingTheme || root.isSwitchingWallpaper)
            return;

        // If theme is already active and palette applied, do nothing
        if (root.activeTheme === name && root.currentColors && Object.keys(root.currentColors).length > 0)
            return;

        // Optimistically apply the theme immediately from cache for zero-latency UI updates
        root.isSwitchingTheme = true;
        root.loadThemeByName(name);

        themeProcess.command = [Paths.themeSwitcherBin, "switch", "theme", name];
        themeProcess.running = true;
    }

    function switchWallpaper(filename) {
        if (!filename || filename === "" || filename.indexOf("..") >= 0 || filename.startsWith("/") || filename.indexOf("\\") >= 0 || root.isSwitchingWallpaper || root.isSwitchingTheme)
            return;

        if (root.isWallpaperActive(filename, root.activeWallpaper))
            return;

        // Optimistically update active wallpaper for instant UI checkmark response
        root.activeWallpaper = filename;
        root.isSwitchingWallpaper = true;

        wallpaperProcess.command = [Paths.themeSwitcherBin, "switch", "wallpaper", filename];
        wallpaperProcess.running = true;
    }

    function nextWallpaper() {
        if (!availableWallpapers || availableWallpapers.length === 0)
            return;
        const currentIndex = availableWallpapers.findIndex(entry => root.isWallpaperActive(entry.name));
        const nextIndex = (currentIndex + 1) % availableWallpapers.length;
        const target = availableWallpapers[nextIndex];
        if (target) {
            switchWallpaper(target.name);
        }
    }

    Component.onCompleted: {
        reloadActiveEnv();
        if (root.activeTheme !== "") {
            loadThemeByName(root.activeTheme);
        } else {
            reloadCurrentColors();
        }
    }
}
