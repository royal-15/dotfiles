import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs
import qs.components
import qs.feature.bar
import qs.feature.theme
import "components"

Item {
    id: root

    property real compactW: 140
    readonly property real compactH: Decorations.pillHeight
    readonly property real compactR: compactH / 2

    property string currentStage: "hub" // "hub", "themes", "wallpapers"

    readonly property bool isOpen: islandSurface.expanded
    readonly property bool isExpanded: islandSurface.expanded
    readonly property bool closingWithAnimation: islandSurface.closingWithAnimation
    readonly property real currentR: islandSurface.currentR
    property alias islandSurface: islandSurface
    readonly property real morphProgress: islandSurface.morphProgress

    readonly property real workspaceDimProgress: {
        if (!islandSurface.expanded && !islandSurface.closingWithAnimation && islandSurface.morphProgress <= 0.0)
            return 0.0;
        return Math.min(1.0, islandSurface.morphProgress / 0.20);
    }

    implicitWidth: islandSurface.width
    implicitHeight: islandSurface.height
    width: islandSurface.width
    height: islandSurface.height

    readonly property real targetStageW: {
        if (currentStage === "themes") return 560;
        if (currentStage === "wallpapers") return 700;
        return 420; // "hub"
    }

    readonly property real targetStageH: {
        if (currentStage === "themes") return 400;
        if (currentStage === "wallpapers") return 290;
        return 190; // "hub"
    }

    readonly property real targetStageR: Decorations.cornerRadius

    NumberAnimation {
        id: morphAnimation
        target: islandSurface
        property: "morphProgress"
        duration: Motion.durationMorph
        easing.type: Motion.easingStandard
        onFinished: {
            if (islandSurface.closingWithAnimation) {
                islandSurface.expanded = false;
                islandSurface.closingWithAnimation = false;
                root.currentStage = "hub";
            } else if (islandSurface.expanded) {
                root.focusPrimary();
            }
        }
    }

    function openStage(stage) {
        root.currentStage = (stage === "themes" || stage === "wallpapers") ? stage : "hub";
        StatusBarPanelCoordinator.openPanel(root, root.currentStage);
    }

    function navigateBack() {
        if (root.currentStage === "themes" || root.currentStage === "wallpapers") {
            root.setStage("hub");
        } else {
            root.requestClose();
        }
    }

    Shortcut {
        sequence: "Escape"
        context: Qt.ApplicationShortcut
        autoRepeat: false
        enabled: islandSurface.expanded && !islandSurface.closingWithAnimation
        onActivated: root.navigateBack()
    }

    Shortcut {
        sequence: "Backspace"
        context: Qt.ApplicationShortcut
        autoRepeat: false
        enabled: islandSurface.expanded && !islandSurface.closingWithAnimation
        onActivated: root.navigateBack()
    }

    Shortcut {
        sequence: "Ctrl+Tab"
        context: Qt.WindowShortcut
        autoRepeat: false
        enabled: islandSurface.expanded && !islandSurface.closingWithAnimation && (root.currentStage === "themes" || root.currentStage === "wallpapers")
        onActivated: {
            root.setStage(root.currentStage === "themes" ? "wallpapers" : "themes");
        }
    }

    Shortcut {
        sequences: ["Ctrl+Shift+Tab", "Ctrl+Backtab"]
        context: Qt.WindowShortcut
        autoRepeat: false
        enabled: islandSurface.expanded && !islandSurface.closingWithAnimation && (root.currentStage === "themes" || root.currentStage === "wallpapers")
        onActivated: {
            root.setStage(root.currentStage === "themes" ? "wallpapers" : "themes");
        }
    }

    function openNow(argument) {
        if (argument && (argument === "themes" || argument === "wallpapers" || argument === "hub"))
            root.currentStage = argument;

        if (islandSurface.expanded && islandSurface.closingWithAnimation) {
            islandSurface.closingWithAnimation = false;
            morphAnimation.stop();
            morphAnimation.from = islandSurface.morphProgress;
            morphAnimation.to = 1;
            morphAnimation.duration = Math.max(60, Math.round(Motion.durationMorph * (1 - islandSurface.morphProgress)));
            morphAnimation.easing.type = Motion.easingStandard;
            morphAnimation.restart();
        } else if (!islandSurface.expanded) {
            islandSurface.expanded = true;
            islandSurface.morphProgress = 0;
            morphAnimation.stop();
            morphAnimation.from = 0;
            morphAnimation.to = 1;
            morphAnimation.duration = Motion.durationMorph;
            morphAnimation.easing.type = Motion.easingStandard;
            morphAnimation.restart();
        }

        Qt.callLater(() => root.focusPrimary());
    }

    function setStage(stage) {
        if (stage && (stage === "themes" || stage === "wallpapers" || stage === "hub")) {
            root.currentStage = stage;
            Qt.callLater(() => root.focusPrimary());
        }
    }

    function closeImmediate() {
        morphAnimation.stop();
        islandSurface.expanded = false;
        islandSurface.closingWithAnimation = false;
        islandSurface.morphProgress = 0;
        root.currentStage = "hub";
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

    function focusPrimary() {
        if (!islandSurface.expanded || islandSurface.closingWithAnimation)
            return;
        if (root.currentStage === "hub")
            hubView.forceActiveFocus();
        else if (root.currentStage === "themes")
            themesView.forceActiveFocus();
        else if (root.currentStage === "wallpapers")
            wallpapersView.forceActiveFocus();
    }

    // Ambient drop shadow tracking morphing geometry
    Rectangle {
        anchors.fill: islandSurface
        anchors.topMargin: 2
        anchors.bottomMargin: -1
        radius: islandSurface.currentR
        color: Colors.shadow
        opacity: (0.40 + 0.35 * islandSurface.morphProgress)
        visible: islandSurface.expanded && opacity > 0.01
        z: -1
    }

    // Morphing Island Surface
    Rectangle {
        id: islandSurface

        property bool expanded: false
        property real morphProgress: 0.0
        property bool closingWithAnimation: false

        // Fluid interpolation of stage dimensions
        property real currentStageTargetW: root.targetStageW
        property real currentStageTargetH: root.targetStageH

        Behavior on currentStageTargetW {
            NumberAnimation {
                duration: Motion.durationMorph
                easing.type: Motion.easingFluid
            }
        }

        Behavior on currentStageTargetH {
            NumberAnimation {
                duration: Motion.durationMorph
                easing.type: Motion.easingFluid
            }
        }

        readonly property real currentW: Math.round(root.compactW + (currentStageTargetW - root.compactW) * morphProgress)
        readonly property real currentH: Math.round(root.compactH + (currentStageTargetH - root.compactH) * morphProgress)
        readonly property real currentR: Math.round(root.compactR + (root.targetStageR - root.compactR) * morphProgress)

        width: currentW
        height: currentH
        radius: currentR

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter

        color: morphProgress > 0.35 ? Colors.panel : Colors.surface

        Behavior on color {
            ColorAnimation {
                duration: Motion.durationFast
                easing.type: Motion.easingStandard
            }
        }
        clip: true
        visible: expanded || morphProgress > 0.01

        border.width: morphProgress > 0.3 ? 1 : 0
        border.color: Colors.border

        Behavior on border.width {
            NumberAnimation { duration: Motion.durationFast }
        }

        Item {
            anchors.fill: parent
            opacity: Math.max(0, (islandSurface.morphProgress - 0.25) / 0.75)
            visible: opacity > 0.01

            // Stage 1: Hub View
            ThemeHubView {
                id: hubView
                width: 420
                height: 190
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                opacity: root.currentStage === "hub" ? 1.0 : 0.0
                visible: opacity > 0.01

                Behavior on opacity {
                    NumberAnimation {
                        duration: Motion.durationNormal
                        easing.type: Motion.easingStandard
                    }
                }

                onOpenThemesRequested: root.setStage("themes")
                onOpenWallpapersRequested: root.setStage("wallpapers")
                onCloseRequested: root.requestClose()
            }

            // Stage 2A: Themes View
            ThemesGridView {
                id: themesView
                width: 560
                height: 400
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                opacity: root.currentStage === "themes" ? 1.0 : 0.0
                visible: opacity > 0.01

                Behavior on opacity {
                    NumberAnimation {
                        duration: Motion.durationNormal
                        easing.type: Motion.easingStandard
                    }
                }

                onBackRequested: root.setStage("hub")
                onOpenWallpapersRequested: root.setStage("wallpapers")
            }

            // Stage 2B: Wallpapers View
            WallpaperCarouselView {
                id: wallpapersView
                width: 700
                height: 290
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                opacity: root.currentStage === "wallpapers" ? 1.0 : 0.0
                visible: opacity > 0.01

                Behavior on opacity {
                    NumberAnimation {
                        duration: Motion.durationNormal
                        easing.type: Motion.easingStandard
                    }
                }

                onBackRequested: root.setStage("hub")
                onOpenThemesRequested: root.setStage("themes")
            }
        }
    }
}
