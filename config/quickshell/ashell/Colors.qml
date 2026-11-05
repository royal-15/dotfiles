pragma Singleton
import QtQuick
import qs

QtObject {
    // 30 purpose-driven Quickshell color tokens dynamically bound to ThemeService
    readonly property color background: ThemeService.getColor("background", "#0a0b0d")
    readonly property color backgroundAlt: ThemeService.getColor("backgroundAlt", "#111214")
    readonly property color overlay: ThemeService.getColor("overlay", Qt.rgba(0.039, 0.043, 0.051, 0.60))

    readonly property color surface: ThemeService.getColor("surface", "#17181a")
    readonly property color surfaceSoft: ThemeService.getColor("surfaceSoft", "#1d1e20")
    readonly property color surfaceMuted: ThemeService.getColor("surfaceMuted", "#242628")
    readonly property color surfaceElevated: ThemeService.getColor("surfaceElevated", "#242628")

    readonly property color panel: ThemeService.getColor("panel", Qt.rgba(0.090, 0.094, 0.102, 0.88))
    readonly property color solid: ThemeService.getColor("solid", Qt.rgba(0.090, 0.094, 0.102, 0.95))
    readonly property color soft: ThemeService.getColor("soft", Qt.rgba(0.039, 0.043, 0.051, 0.70))
    readonly property color tip: ThemeService.getColor("tip", Qt.rgba(0.031, 0.035, 0.039, 0.96))

    readonly property color text: ThemeService.getColor("text", "#e9e5d4")
    readonly property color textDim: ThemeService.getColor("textDim", "#a3a094")
    readonly property color textFaint: ThemeService.getColor("textFaint", Qt.rgba(0.639, 0.627, 0.580, 0.55))
    readonly property color textAccent: ThemeService.getColor("textAccent", "#0a0b0d")

    readonly property color accent: ThemeService.getColor("accent", "#C0BFB2")
    readonly property color accentSoft: ThemeService.getColor("accentSoft", Qt.rgba(0.753, 0.749, 0.698, 0.16))
    readonly property color accentAlt: ThemeService.getColor("accentAlt", "#AEB2AB")
    readonly property color accentAltSoft: ThemeService.getColor("accentAltSoft", Qt.rgba(0.682, 0.698, 0.671, 0.16))

    readonly property color success: ThemeService.getColor("success", "#8D9492")
    readonly property color successSoft: ThemeService.getColor("successSoft", Qt.rgba(0.553, 0.580, 0.573, 0.16))
    readonly property color warning: ThemeService.getColor("warning", "#9EA39F")
    readonly property color critical: ThemeService.getColor("critical", "#7B8486")
    readonly property color criticalSoft: ThemeService.getColor("criticalSoft", Qt.rgba(0.482, 0.518, 0.525, 0.16))

    readonly property color selectedBackground: ThemeService.getColor("selectedBackground", "#C0BFB2")
    readonly property color selectedText: ThemeService.getColor("selectedText", "#0a0b0d")
    readonly property color hover: ThemeService.getColor("hover", Qt.rgba(0.914, 0.898, 0.831, 0.06))
    readonly property color border: ThemeService.getColor("border", "#7B8486")
    readonly property color shadow: ThemeService.getColor("shadow", Qt.rgba(0.0, 0.0, 0.0, 0.28))
    readonly property color shadowTip: ThemeService.getColor("shadowTip", Qt.rgba(0.0, 0.0, 0.0, 0.34))

    // Static invariant utility constant
    readonly property color clear: "transparent"
}
