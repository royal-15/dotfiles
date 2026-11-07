pragma Singleton

import QtQuick
import qs

QtObject {
    id: root

    // Centralized Animation Engine for ASHELL
    // Durations (in milliseconds)
    readonly property int durationInstant: 75
    readonly property int durationFast: 140
    readonly property int durationNormal: 200
    readonly property int durationPanel: 260
    readonly property int durationExit: 180
    readonly property int durationMorph: 250
    readonly property int durationSlow: 320

    // Standard Easing Curves
    readonly property int easingStandard: Easing.OutCubic
    readonly property int easingIn: Easing.InCubic
    readonly property int easingInOut: Easing.InOutCubic
    readonly property int easingPress: Easing.OutQuad
    readonly property int easingBounce: Easing.OutBack
    readonly property int easingFluid: Easing.OutQuart

    // Standard Scale Factors
    readonly property real scaleNormal: 1.0
    readonly property real scaleHover: 1.025
    readonly property real scaleTileHover: 1.02
    readonly property real scalePress: 0.96
    readonly property real scalePanelAnchor: 0.10

    // Tactile Asymmetric Micro-Interaction Curves
    readonly property int durationPressDown: durationInstant   // 75ms snappy compression
    readonly property int durationPressRelease: durationFast   // 140ms fluid return
    readonly property int easingPressDown: easingPress         // Easing.OutQuad
    readonly property int easingPressRelease: easingStandard   // Easing.OutCubic

    // Elevation & Low-Contrast Borders (preserved for backwards compatibility; borderless design uses 0 width)
    readonly property int borderWidth: 0
    readonly property color subtleBorder: Colors.border
    readonly property color subtleBorderLight: Colors.border
    readonly property color subtleBorderHover: Colors.accent
    readonly property color subtleBorderActive: Colors.accent
    readonly property color subtleBorderFocus: Colors.accent
    readonly property color subtleBorderWarning: Colors.warning
    readonly property color subtleBorderCritical: Colors.critical

    // Ambient Shadow Tokens derived directly from Colors.shadow tokens
    readonly property color shadowAmbient: Colors.shadow
    readonly property color shadowPanel: Colors.shadowTip
    readonly property color shadowPill: Colors.shadow
    readonly property color shadowElevated: Colors.shadow
    readonly property color shadowGlow: Colors.accentSoft
    readonly property color shadowDestructive: Colors.criticalSoft
}
