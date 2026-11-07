import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs
import qs.components
import qs.feature.bar
import qs.feature.media

Item {
    id: root

    property var barWindow: null
    property var launcherItem: null
    property var themeStudioItem: null
    property var clipboardItem: null
    property var commandPaletteItem: null
    property var monitor: null

    readonly property bool isOpen: islandSurface.expanded
    readonly property bool isExpanded: islandSurface.expanded
    readonly property bool closingWithAnimation: islandSurface.closingWithAnimation
    readonly property real morphProgress: islandSurface.morphProgress
    readonly property real currentR: islandSurface.currentR
    property alias islandSurface: islandSurface

    readonly property real launcherMorphProgress: (launcherItem && launcherItem.islandSurface) ? launcherItem.islandSurface.morphProgress : 0.0
    readonly property bool launcherActive: launcherItem ? (launcherItem.isOpen || launcherItem.islandSurface.expanded || launcherMorphProgress > 0) : false

    readonly property real themeStudioMorphProgress: (themeStudioItem && themeStudioItem.islandSurface) ? themeStudioItem.islandSurface.morphProgress : 0.0
    readonly property bool themeStudioActive: themeStudioItem ? (themeStudioItem.isOpen || themeStudioItem.islandSurface.expanded || themeStudioMorphProgress > 0) : false

    readonly property real clipboardMorphProgress: (clipboardItem && clipboardItem.islandSurface) ? clipboardItem.islandSurface.morphProgress : 0.0
    readonly property bool clipboardActive: clipboardItem ? (clipboardItem.isOpen || clipboardItem.islandSurface.expanded || clipboardMorphProgress > 0) : false

    readonly property real commandPaletteMorphProgress: (commandPaletteItem && commandPaletteItem.islandSurface) ? commandPaletteItem.islandSurface.morphProgress : 0.0
    readonly property bool commandPaletteActive: commandPaletteItem ? (commandPaletteItem.isOpen || commandPaletteItem.islandSurface.expanded || commandPaletteMorphProgress > 0) : false

    readonly property real centerMorphProgress: Math.max(launcherMorphProgress, themeStudioMorphProgress, clipboardMorphProgress, commandPaletteMorphProgress)
    readonly property bool centerActive: launcherActive || themeStudioActive || clipboardActive || commandPaletteActive

    // Immediate fade and shrink cutoff (reaches full 1.0 within the first 10% of morphing)
    readonly property real centerShrinkProgress: {
        if (!centerActive)
            return 0.0;
        if (centerMorphProgress <= 0.0)
            return 1.0;
        return Math.min(1.0, centerMorphProgress / 0.10);
    }
    readonly property real launcherShrinkProgress: centerShrinkProgress

    onCenterActiveChanged: {
        if (centerActive) {
            flashTimer.stop();
            root.isFlashing = false;
            root.flashDimProgress = 0;
        }
    }

    // Flash state
    property bool isFlashing: false
    property real flashDimProgress: 0.0

    Behavior on flashDimProgress {
        NumberAnimation {
            duration: Motion.durationMorph
            easing.type: Motion.easingStandard
        }
    }

    onIsFlashingChanged: {
        flashDimProgress = isFlashing ? 1.0 : 0.0;
    }

    onCenterMorphProgressChanged: {
        if (centerMorphProgress > 0.01 && root.isFlashing) {
            flashTimer.stop();
            root.isFlashing = false;
        }
    }

    readonly property real workspaceDimProgress: Math.min(1.0, Math.max(islandSurface.morphProgress, flashDimProgress))

    readonly property real bubbleW: MediaService.hasPlayer ? 34 : 0
    readonly property real flashWidth: Math.min(320, Math.max(180, (flashContentRow ? flashContentRow.implicitWidth : 0) + 24))

    // Geometry calculations
    readonly property real barW: (root.parent && root.parent.width > 0) ? root.parent.width : (root.barWindow && root.barWindow.width > 0 ? root.barWindow.width : 1920)
    readonly property real launcherW: (root.launcherItem && root.launcherItem.compactW > 0) ? root.launcherItem.compactW : 120
    readonly property real satelliteX: Math.round((barW / 2) + (launcherW / 2) + 8)
    readonly property real flashCenteredX: Math.round((barW / 2) - (flashWidth / 2))
    readonly property real targetW: 420
    readonly property real targetH: 190
    readonly property real targetR: Decorations.cornerRadius
    readonly property real targetX: Math.round((barW / 2) - (targetW / 2))

    // Compact dimensions
    readonly property real compactX: Math.round(satelliteX + (flashCenteredX - satelliteX) * flashDimProgress)
    readonly property real compactW: Math.round(bubbleW + (flashWidth - bubbleW) * flashDimProgress)
    readonly property real compactH: Decorations.pillHeight
    readonly property real compactR: compactH / 2

    // Current animated geometry
    readonly property real currentX: Math.round(compactX + (targetX - compactX) * islandSurface.morphProgress)
    readonly property real currentW: Math.round(compactW + (targetW - compactW) * islandSurface.morphProgress)
    readonly property real currentH: Math.round(compactH + (targetH - compactH) * islandSurface.morphProgress)

    x: currentX
    y: Decorations.barItemMarginVertical
    width: currentW
    height: currentH
    scale: 1.0 - centerShrinkProgress
    transformOrigin: Item.Center
    visible: opacity > 0.01 && !centerActive
    opacity: MediaService.hasPlayer ? Math.max(0, 1.0 - centerShrinkProgress) : 0

    Behavior on opacity {
        enabled: !root.centerActive
        NumberAnimation {
            duration: Motion.durationNormal
            easing.type: Motion.easingStandard
        }
    }

    // 3-second Flash Timer on track change
    Timer {
        id: flashTimer
        interval: 3000
        repeat: false
        onTriggered: {
            root.isFlashing = false;
        }
    }

    Connections {
        target: MediaService
        function onTrackChanged() {
            if (!islandSurface.expanded && MediaService.hasPlayer && !root.centerActive) {
                root.isFlashing = true;
                flashTimer.restart();
            }
        }
        function onFeedbackTriggered(icon, text, isError) {
            if (!islandSurface.expanded && !root.centerActive) {
                root.isFlashing = true;
                flashTimer.restart();
            }
        }
    }

    Connections {
        target: root.monitor
        ignoreUnknownSignals: true
        function onActiveWorkspaceChanged() {
            if (root.isFlashing) {
                flashTimer.stop();
                root.isFlashing = false;
            }
        }
    }

    NumberAnimation {
        id: morphAnimation
        target: islandSurface
        property: "morphProgress"
        duration: Motion.durationPanel
        easing.type: Motion.easingStandard
        onFinished: {
            if (islandSurface.closingWithAnimation) {
                islandSurface.expanded = false;
                islandSurface.closingWithAnimation = false;
                root.flashDimProgress = 0;
            }
        }
    }

    function openForKeyboard() {
        StatusBarPanelCoordinator.openPanel(root);
    }

    function openNow() {
        flashTimer.stop();
        root.isFlashing = false;

        if (islandSurface.expanded && islandSurface.closingWithAnimation) {
            islandSurface.closingWithAnimation = false;
            morphAnimation.stop();
            morphAnimation.from = islandSurface.morphProgress;
            morphAnimation.to = 1;
            morphAnimation.duration = Math.max(60, Math.round(Motion.durationPanel * (1 - islandSurface.morphProgress)));
            morphAnimation.easing.type = Motion.easingStandard;
            morphAnimation.restart();
        } else if (!islandSurface.expanded) {
            islandSurface.expanded = true;
            islandSurface.morphProgress = 0;
            morphAnimation.stop();
            morphAnimation.from = 0;
            morphAnimation.to = 1;
            morphAnimation.duration = Motion.durationPanel;
            morphAnimation.easing.type = Motion.easingStandard;
            morphAnimation.restart();
        }
    }

    function requestClose() {
        if (!islandSurface.expanded || islandSurface.closingWithAnimation)
            return;
        islandSurface.closingWithAnimation = true;
        morphAnimation.stop();
        morphAnimation.from = islandSurface.morphProgress;
        morphAnimation.to = 0;
        morphAnimation.duration = Math.max(60, Math.round(Motion.durationExit * islandSurface.morphProgress));
        morphAnimation.easing.type = Motion.easingIn;
        morphAnimation.restart();
    }

    function closeImmediate() {
        morphAnimation.stop();
        islandSurface.expanded = false;
        islandSurface.closingWithAnimation = false;
        islandSurface.morphProgress = 0;
    }

    function toggleIsland() {
        if (islandSurface.expanded && !islandSurface.closingWithAnimation)
            requestClose();
        else
            openForKeyboard();
    }

    // Keyboard dismiss on Escape
    Shortcut {
        sequence: "Escape"
        context: Qt.WindowShortcut
        enabled: islandSurface.expanded && !islandSurface.closingWithAnimation
        onActivated: root.requestClose()
    }

    // Media playback keyboard controls
    Shortcut {
        sequence: "Space"
        context: Qt.WindowShortcut
        enabled: islandSurface.expanded && !islandSurface.closingWithAnimation
        onActivated: MediaService.togglePlaying()
    }

    Shortcut {
        sequence: "Left"
        context: Qt.WindowShortcut
        enabled: islandSurface.expanded && !islandSurface.closingWithAnimation
        onActivated: MediaService.previous()
    }

    Shortcut {
        sequence: "Right"
        context: Qt.WindowShortcut
        enabled: islandSurface.expanded && !islandSurface.closingWithAnimation
        onActivated: MediaService.next()
    }

    Shortcut {
        sequence: "Shift+Left"
        context: Qt.WindowShortcut
        enabled: islandSurface.expanded && !islandSurface.closingWithAnimation
        onActivated: MediaService.seekBy(-5)
    }

    Shortcut {
        sequence: "Shift+Right"
        context: Qt.WindowShortcut
        enabled: islandSurface.expanded && !islandSurface.closingWithAnimation
        onActivated: MediaService.seekBy(5)
    }

    // Ambient drop shadow tracking morphing geometry
    Rectangle {
        anchors.fill: islandSurface
        anchors.topMargin: 2
        anchors.bottomMargin: -1
        radius: islandSurface.currentR
        color: Colors.shadow
        opacity: 0.35 + 0.35 * islandSurface.morphProgress
        z: -1
    }

    // Dynamic Island Surface
    Rectangle {
        id: islandSurface

        property bool expanded: false
        property real morphProgress: 0
        property bool closingWithAnimation: false

        readonly property real currentR: Math.round(root.compactR + (root.targetR - root.compactR) * morphProgress)

        anchors.fill: parent
        radius: currentR
        color: morphProgress > 0.35 ? Colors.panel : (compactHover.hovered ? Colors.surfaceSoft : Colors.surface)
        clip: true
        visible: root.visible

        Behavior on color {
            ColorAnimation {
                duration: Motion.durationFast
                easing.type: Motion.easingStandard
            }
        }

        // Ambient border when expanded
        Rectangle {
            anchors.fill: parent
            radius: islandSurface.currentR
            color: Colors.clear
            border.width: islandSurface.morphProgress > 0.3 ? 1 : 0
            border.color: Colors.border
            opacity: Math.max(0, Math.min(1, (islandSurface.morphProgress - 0.3) / 0.5))
            z: 20
        }

        // ==========================================
        // COMPACT STATE: Waveform / Flash Capsule
        // ==========================================
        Item {
            id: compactContainer
            anchors.fill: parent
            z: 10
            visible: islandSurface.morphProgress < 0.3
            opacity: Math.max(0, 1 - islandSurface.morphProgress / 0.3)

            HoverHandler {
                id: compactHover
                cursorShape: Qt.PointingHandCursor
                onHoveredChanged: {
                    if (hovered && root.isFlashing) {
                        flashTimer.stop();
                    } else if (!hovered && root.isFlashing) {
                        flashTimer.restart();
                    }
                }
            }

            TapHandler {
                onTapped: root.toggleIsland()
            }

            RowLayout {
                id: flashContentRow
                anchors.centerIn: parent
                spacing: 6

                WaveformIcon {
                    isPlaying: MediaService.isPlaying
                    Layout.alignment: Qt.AlignVCenter
                }

                // Transient track info / feedback during flash
                Text {
                    Layout.alignment: Qt.AlignVCenter
                    visible: root.flashDimProgress > 0.02
                    opacity: Math.max(0, Math.min(1, (root.flashDimProgress - 0.1) / 0.8))
                    text: (MediaService.feedbackActive && MediaService.feedbackText !== "")
                        ? MediaService.feedbackText
                        : `${MediaService.trackTitle} — ${MediaService.trackArtist}`
                    color: (MediaService.feedbackActive && MediaService.feedbackIsError) ? Colors.critical : Colors.text
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                    Layout.maximumWidth: 180
                    elide: Text.ElideRight
                }
            }
        }

        // ==========================================
        // EXPANDED STATE: Now Playing Card
        // ==========================================
        MediaCard {
            id: mediaCard
            anchors.fill: parent
            z: 15
            visible: islandSurface.morphProgress > 0.2
            opacity: Math.max(0, Math.min(1, (islandSurface.morphProgress - 0.2) / 0.4))
            onRequestClose: root.requestClose()
        }
    }
}
