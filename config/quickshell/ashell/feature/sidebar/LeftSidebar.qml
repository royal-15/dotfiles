import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import qs.components
import qs.feature.bar

PanelWindow {
    id: root

    property var barWindow: null
    property real slideProgress: 0
    property bool closingWithAnimation: false
    property bool panelPointerPressActive: false
    property bool focusGrabEnabled: true
    readonly property bool isOpen: visible && !closingWithAnimation
    readonly property bool ownsKeyboardInput: {
        if (!isOpen)
            return false;

        const focusedMonitor = Hyprland.focusedMonitor;
        if (focusedMonitor)
            return Hyprland.monitorFor(screen) === focusedMonitor;

        const screens = Quickshell.screens;
        return screens.length > 0 && screen === screens[0];
    }

    readonly property real panelWidth: 360
    readonly property real slideDistance: panelWidth + Decorations.screenEdgePadding + 45
    // Anchored to the left: slideTranslateX is negative when off-screen, 0 when resting open
    readonly property real slideTranslateX: -Math.round(root.slideDistance * (1.0 - root.slideProgress))

    readonly property real targetSurfaceHeight: 420

    screen: root.barWindow ? root.barWindow.screen : null
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.ownsKeyboardInput ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0

    anchors {
        top: true
        bottom: true
        left: true
    }

    margins {
        top: Decorations.exclusiveZoneHeight
        bottom: Decorations.screenEdgePadding
        left: 0
    }

    implicitWidth: root.panelWidth + Decorations.screenEdgePadding
    color: Colors.clear
    visible: false
    focusable: root.ownsKeyboardInput

    Item {
        id: windowBounds
        anchors.fill: parent
    }

    // Click-through input mask: mouse clicks pass through transparent regions outside panelSurface when resting
    mask: Region {
        Region {
            item: (root.closingWithAnimation || slideAnimation.running) ? windowBounds : panelSurface
            radius: (root.closingWithAnimation || slideAnimation.running) ? 0 : Decorations.cornerRadius
        }
    }

    HyprlandFocusGrab {
        id: focusGrab
        windows: root.barWindow ? [root, root.barWindow] : [root]
        active: root.ownsKeyboardInput && root.focusGrabEnabled
        onActiveChanged: {
            if (active)
                root.focusCurrentTarget();
        }
        onCleared: {
            const clearedDuringPanelPress = root.panelPointerPressActive;
            Qt.callLater(() => {
                if (!root.ownsKeyboardInput)
                    return;

                if (!clearedDuringPanelPress && !root.panelPointerPressActive && !panelPointer.hovered) {
                    root.requestClose();
                    return;
                }

                root.focusGrabEnabled = false;
                Qt.callLater(() => root.focusGrabEnabled = true);
            });
        }
    }

    Shortcut {
        sequence: "Escape"
        context: Qt.ApplicationShortcut
        autoRepeat: false
        enabled: root.ownsKeyboardInput && root.visible && !root.closingWithAnimation
        onActivated: root.requestClose()
    }

    NumberAnimation {
        id: slideAnimation
        target: root
        property: "slideProgress"
        duration: Motion.durationPanel
        easing.type: Motion.easingFluid
        onFinished: {
            if (root.closingWithAnimation) {
                root.visible = false;
                root.closingWithAnimation = false;
            } else if (root.visible) {
                root.focusCurrentTarget();
            }
        }
    }

    function openNow() {
        if (visible && !closingWithAnimation) {
            focusGrabEnabled = true;
            focusCurrentTarget();
            return;
        }

        focusGrabEnabled = true;
        visible = true;
        closingWithAnimation = false;
        slideProgress = 0;
        slideAnimation.stop();
        slideAnimation.from = 0;
        slideAnimation.to = 1;
        slideAnimation.duration = Motion.durationPanel;
        slideAnimation.easing.type = Motion.easingFluid;
        slideAnimation.restart();

        Qt.callLater(() => focusCurrentTarget());
    }

    function openForKeyboard() {
        openNow();
    }

    function toggle() {
        if (visible && !closingWithAnimation) {
            requestClose();
        } else {
            openNow();
        }
    }

    function closeImmediate() {
        if (!visible)
            return;
        closingWithAnimation = false;
        focusGrabEnabled = true;
        slideAnimation.stop();
        slideProgress = 0;
        visible = false;
    }

    function requestClose() {
        if (!visible || closingWithAnimation)
            return;
        closingWithAnimation = true;
        focusGrabEnabled = true;
        slideAnimation.stop();
        slideAnimation.from = slideProgress;
        slideAnimation.to = 0;
        slideAnimation.duration = Math.max(80, Math.round(Motion.durationPanel * slideProgress));
        slideAnimation.easing.type = Motion.easingStandard;
        slideAnimation.restart();
    }

    function focusCurrentTarget() {
        if (!ownsKeyboardInput || closingWithAnimation)
            return;
        sidebarFocusScope.forceActiveFocus();
        calendarView.focusKeyboardTarget();
    }

    // Multi-layer ambient drop shadow for elevated depth
    Rectangle {
        anchors.fill: panelSurface
        anchors.margins: -2
        anchors.topMargin: 5
        anchors.bottomMargin: -3
        radius: panelSurface.radius + 2
        color: Colors.shadowTip
        opacity: 0.35 * root.slideProgress
        transform: Translate {
            x: root.slideTranslateX
        }
        z: -2
    }

    Rectangle {
        anchors.fill: panelSurface
        anchors.topMargin: 2
        anchors.bottomMargin: -1
        radius: panelSurface.radius
        color: Colors.shadow
        opacity: 0.50 * root.slideProgress
        transform: Translate {
            x: root.slideTranslateX
        }
        z: -1
    }

    // Outer visual card (stays docked to top-left, animates its height)
    Rectangle {
        id: panelSurface
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.leftMargin: Decorations.screenEdgePadding
        width: root.panelWidth
        height: root.targetSurfaceHeight
        radius: Decorations.cornerRadius
        color: Colors.panel
        border.color: Colors.border
        border.width: 1
        clip: true

        Behavior on height {
            NumberAnimation {
                duration: Motion.durationMorph
                easing.type: Motion.easingFluid
            }
        }

        transform: Translate {
            x: root.slideTranslateX
        }

        HoverHandler {
            id: panelPointer
        }

        TapHandler {
            acceptedButtons: Qt.LeftButton
            onPressedChanged: {
                if (pressed) {
                    root.panelPointerPressActive = true;
                } else {
                    Qt.callLater(() => root.panelPointerPressActive = false);
                }
            }
        }

        FocusScope {
            id: sidebarFocusScope
            anchors.fill: parent
            focus: root.ownsKeyboardInput
            Keys.priority: Keys.BeforeItem
            Keys.onPressed: event => {
                if (!root.ownsKeyboardInput)
                    return;
                if (event.key === Qt.Key_Escape) {
                    root.requestClose();
                    event.accepted = true;
                }
            }

            Item {
                id: viewsContainer
                anchors.fill: parent

                CalendarView {
                    id: calendarView
                    anchors.fill: parent
                    isCurrentTab: root.isOpen
                    onCloseRequested: root.requestClose()
                }
            }
        }
    }
}
