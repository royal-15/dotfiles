import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import qs.components
import qs.feature.bar
import qs.feature.network
import qs.feature.powerprofile
import qs.feature.notifications

PanelWindow {
    id: root

    property var barWindow: null
    property string activeTab: "network" // "network" (or "wifi", "bluetooth"), "power", "notifications"
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
    readonly property bool networkDialogOpen: currentTabIndex === 0 && networkView.dialogOpen

    // Tab indexing: 0 = network, 1 = power, 2 = notifications
    function tabIndex(name) {
        if (name === "network" || name === "wifi" || name === "bluetooth")
            return 0;
        if (name === "power")
            return 1;
        if (name === "notifications")
            return 2;
        return 0;
    }

    readonly property int currentTabIndex: tabIndex(activeTab)
    property int previousTabIndex: 0
    property int tabTransitionDirection: 1 // +1 for moving to the right, -1 for moving to the left
    property real tabSwitchProgress: 1.0
    readonly property real slideTranslateX: Math.round(((root.width > 0 ? root.width : root.implicitWidth) + root.margins.right) * (1.0 - root.slideProgress))

    // Adaptive height based on active tab
    readonly property real targetSurfaceHeight: {
        if (currentTabIndex === 2)
            return (root.height > 0) ? root.height : 600; // Full height below bar
        if (currentTabIndex === 0)
            return Math.min(540, (root.height > 0) ? root.height : 540);
        if (currentTabIndex === 1)
            return Math.min(260, (root.height > 0) ? root.height : 260);
        return 300;
    }

    screen: root.barWindow ? root.barWindow.screen : null
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.ownsKeyboardInput ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0

    anchors {
        top: true
        bottom: true
        right: true
    }

    margins {
        top: Decorations.exclusiveZoneHeight
        bottom: Decorations.screenEdgePadding
        right: Decorations.screenEdgePadding
    }

    implicitWidth: 360
    color: Colors.clear
    visible: false
    focusable: root.ownsKeyboardInput

    // Click-through input mask: mouse clicks pass through the transparent region outside panelSurface
    mask: Region {
        Region {
            item: panelSurface
            radius: Decorations.cornerRadius
        }
    }

    HyprlandFocusGrab {
        id: focusGrab
        windows: root.barWindow ? [root, root.barWindow] : [root]
        active: root.ownsKeyboardInput && root.focusGrabEnabled && !root.networkDialogOpen
        onActiveChanged: {
            if (active)
                root.focusCurrentTab();
        }
        onCleared: {
            // A click inside the panel can clear the grab before the target's
            // clicked handler runs. Let that interaction finish before using
            // the pointer location to decide whether this was an outside click.
            const clearedDuringPanelPress = root.panelPointerPressActive;
            Qt.callLater(() => {
                if (!root.ownsKeyboardInput || root.networkDialogOpen)
                    return;

                if (!clearedDuringPanelPress && !root.panelPointerPressActive && !panelPointer.hovered) {
                    root.requestClose();
                    return;
                }

                // HyprlandFocusGrab.active becomes false when the compositor
                // clears the grab. Toggle its binding input to start a fresh
                // grab while the pointer is still interacting with this panel.
                root.focusGrabEnabled = false;
                Qt.callLater(() => root.focusGrabEnabled = true);
            });
        }
    }

    Shortcut {
        sequence: "Alt+1"
        context: Qt.ApplicationShortcut
        autoRepeat: false
        enabled: root.ownsKeyboardInput && !root.networkDialogOpen
        onActivated: root.openTab("network")
    }

    Shortcut {
        sequence: "Alt+2"
        context: Qt.ApplicationShortcut
        autoRepeat: false
        enabled: root.ownsKeyboardInput && !root.networkDialogOpen
        onActivated: root.openTab("power")
    }

    Shortcut {
        sequence: "Alt+3"
        context: Qt.ApplicationShortcut
        autoRepeat: false
        enabled: root.ownsKeyboardInput && !root.networkDialogOpen
        onActivated: root.openTab("notifications")
    }

    NumberAnimation {
        id: slideAnimation
        target: root
        property: "slideProgress"
        duration: Motion.durationPanel
        easing.type: Motion.easingStandard
        onFinished: {
            if (root.closingWithAnimation) {
                root.visible = false;
                root.closingWithAnimation = false;
            } else if (root.visible) {
                root.focusCurrentTab();
            }
        }
    }

    NumberAnimation {
        id: tabCrossfadeAnimation
        target: root
        property: "tabSwitchProgress"
        from: 0.0
        to: 1.0
        duration: Motion.durationNormal
        easing.type: Motion.easingStandard
    }

    function openTab(tabName, subArg) {
        const targetIndex = tabIndex(tabName);
        if (visible && !closingWithAnimation) {
            focusGrabEnabled = true;
            // Warm tab switch
            if (currentTabIndex !== targetIndex) {
                previousTabIndex = currentTabIndex;
                tabTransitionDirection = (targetIndex > currentTabIndex) ? 1 : -1;
                activeTab = tabName;
                tabSwitchProgress = 0.0;
                tabCrossfadeAnimation.restart();
            }
            if (targetIndex === 0 && subArg)
                networkView.openNow(subArg);
            else if (targetIndex === 0)
                networkView.openNow();
            else if (targetIndex === 1)
                powerView.resetState();
            else if (targetIndex === 2)
                notificationView.markAllChecked();
            focusCurrentTab();
            return;
        }

        // Cold open
        activeTab = tabName;
        previousTabIndex = targetIndex;
        tabSwitchProgress = 1.0;
        focusGrabEnabled = true;
        if (targetIndex === 0 && subArg)
            networkView.openNow(subArg);
        else if (targetIndex === 0)
            networkView.openNow();
        else if (targetIndex === 1)
            powerView.resetState();
        else if (targetIndex === 2)
            notificationView.markAllChecked();

        visible = true;
        closingWithAnimation = false;
        slideProgress = 0;
        slideAnimation.stop();
        slideAnimation.from = 0;
        slideAnimation.to = 1;
        slideAnimation.duration = Motion.durationPanel;
        slideAnimation.easing.type = Motion.easingStandard;
        slideAnimation.restart();

        Qt.callLater(() => focusCurrentTab());
    }

    function toggleTab(tabName) {
        const targetIndex = tabIndex(tabName);
        if (visible && !closingWithAnimation && currentTabIndex === targetIndex) {
            requestClose();
        } else {
            openTab(tabName);
        }
    }

    function cycleTab(direction) {
        const newIndex = (currentTabIndex + direction + 3) % 3;
        const names = ["network", "power", "notifications"];
        openTab(names[newIndex]);
    }

    function closeImmediate() {
        if (!visible)
            return;
        closingWithAnimation = false;
        focusGrabEnabled = true;
        slideAnimation.stop();
        tabCrossfadeAnimation.stop();
        slideProgress = 0;
        networkView.closeImmediate();
        powerView.resetState();
        visible = false;
    }

    function requestClose() {
        if (!visible || closingWithAnimation)
            return;
        closingWithAnimation = true;
        focusGrabEnabled = true;
        networkView.closeImmediate();
        powerView.resetState();
        slideAnimation.stop();
        slideAnimation.from = slideProgress;
        slideAnimation.to = 0;
        slideAnimation.duration = Math.max(60, Math.round(Motion.durationExit * slideProgress));
        slideAnimation.easing.type = Motion.easingIn;
        slideAnimation.restart();
    }

    function handleEscape() {
        if (currentTabIndex === 0) {
            if (networkView.handleEscape())
                return;
        } else if (currentTabIndex === 1) {
            if (powerView.confirmingAction !== "") {
                powerView.resetState();
                return;
            }
        }
        requestClose();
    }

    function focusCurrentTab() {
        if (!ownsKeyboardInput || closingWithAnimation || networkDialogOpen)
            return;
        sidebarFocusScope.forceActiveFocus();
        if (currentTabIndex === 0)
            networkView.focusKeyboardTarget();
        else if (currentTabIndex === 1)
            powerView.focusKeyboardTarget();
        else if (currentTabIndex === 2)
            notificationView.focusKeyboardTarget();
    }

    // Multi-layer ambient drop shadow for elevated depth
    Rectangle {
        anchors.fill: panelSurface
        anchors.topMargin: 3
        anchors.bottomMargin: -2
        radius: panelSurface.radius
        color: Colors.shadow
        opacity: 0.55 * root.slideProgress
        transform: Translate {
            x: root.slideTranslateX
        }
        z: -1
    }

    // Outer visual card (stays docked to top-right, animates its height)
    Rectangle {
        id: panelSurface
        anchors.top: parent.top
        anchors.right: parent.right
        width: parent.width
        height: root.targetSurfaceHeight
        radius: Decorations.cornerRadius
        color: Colors.panel
        border.color: Colors.border
        border.width: 1
        clip: true

        Behavior on height {
            NumberAnimation {
                duration: Motion.durationNormal
                easing.type: Motion.easingStandard
            }
        }

        transform: Translate {
            x: root.slideTranslateX
        }
        opacity: root.slideProgress

        HoverHandler {
            id: panelPointer
        }

        TapHandler {
            acceptedButtons: Qt.LeftButton
            onPressedChanged: {
                if (pressed) {
                    root.panelPointerPressActive = true;
                } else {
                    // Keep the guard active through MouseArea.onClicked and
                    // other release handlers for this same pointer event.
                    Qt.callLater(() => root.panelPointerPressActive = false);
                }
            }
        }

        FocusScope {
            id: sidebarFocusScope
            anchors.fill: parent
            focus: root.ownsKeyboardInput && !root.networkDialogOpen
            Keys.priority: Keys.BeforeItem
            Keys.onPressed: event => {
                if (!root.ownsKeyboardInput || root.networkDialogOpen)
                    return;
                if ((event.modifiers & Qt.ControlModifier) !== 0 && event.key === Qt.Key_Tab) {
                    root.cycleTab((event.modifiers & Qt.ShiftModifier) ? -1 : 1);
                    event.accepted = true;
                } else if (event.key === Qt.Key_Escape) {
                    root.handleEscape();
                    event.accepted = true;
                }
            }

            Item {
                id: viewsContainer
                anchors.fill: parent

                // 1. NetworkCenterView
                Item {
                    id: networkViewWrapper
                    anchors.fill: parent
                    visible: root.currentTabIndex === 0 || (root.previousTabIndex === 0 && root.tabSwitchProgress < 0.99)
                    enabled: root.currentTabIndex === 0
                    opacity: (root.currentTabIndex === 0)
                        ? root.tabSwitchProgress
                        : (1.0 - root.tabSwitchProgress)

                    transform: Translate {
                        x: (root.currentTabIndex === 0)
                            ? Math.round(8 * root.tabTransitionDirection * (1.0 - root.tabSwitchProgress))
                            : Math.round(-8 * root.tabTransitionDirection * root.tabSwitchProgress)
                    }

                    NetworkCenterView {
                        id: networkView
                        anchors.fill: parent
                        isCurrentTab: root.isOpen && root.currentTabIndex === 0
                        onCloseRequested: root.requestClose()
                    }
                }

                // 2. PowerProfileView
                Item {
                    id: powerViewWrapper
                    anchors.fill: parent
                    visible: root.currentTabIndex === 1 || (root.previousTabIndex === 1 && root.tabSwitchProgress < 0.99)
                    enabled: root.currentTabIndex === 1
                    opacity: (root.currentTabIndex === 1)
                        ? root.tabSwitchProgress
                        : (1.0 - root.tabSwitchProgress)

                    transform: Translate {
                        x: (root.currentTabIndex === 1)
                            ? Math.round(8 * root.tabTransitionDirection * (1.0 - root.tabSwitchProgress))
                            : Math.round(-8 * root.tabTransitionDirection * root.tabSwitchProgress)
                    }

                    PowerProfileView {
                        id: powerView
                        anchors.fill: parent
                        isCurrentTab: root.isOpen && root.currentTabIndex === 1
                        onCloseRequested: root.requestClose()
                    }
                }

                // 3. NotificationCenterView
                Item {
                    id: notificationViewWrapper
                    anchors.fill: parent
                    visible: root.currentTabIndex === 2 || (root.previousTabIndex === 2 && root.tabSwitchProgress < 0.99)
                    enabled: root.currentTabIndex === 2
                    opacity: (root.currentTabIndex === 2)
                        ? root.tabSwitchProgress
                        : (1.0 - root.tabSwitchProgress)

                    transform: Translate {
                        x: (root.currentTabIndex === 2)
                            ? Math.round(8 * root.tabTransitionDirection * (1.0 - root.tabSwitchProgress))
                            : Math.round(-8 * root.tabTransitionDirection * root.tabSwitchProgress)
                    }

                    NotificationCenterView {
                        id: notificationView
                        anchors.fill: parent
                        isCurrentTab: root.isOpen && root.currentTabIndex === 2
                        onCloseRequested: root.requestClose()
                    }
                }
            }
        }
    }

    // Proxy adapters for 100% backward compatibility with Routers & StatusBarPanelCoordinator
    readonly property var networkProxy: QtObject {
        readonly property bool visible: root.visible && root.currentTabIndex === 0
        readonly property bool isOpen: root.isOpen && root.currentTabIndex === 0
        readonly property bool closingWithAnimation: root.closingWithAnimation
        readonly property string activeTab: networkView.activeTab
        readonly property bool wifiBusy: NetworkCenterState.wifiBusy
        readonly property bool bluetoothBusy: NetworkCenterState.bluetoothBusy

        function openNow(tab) { root.openTab("network", tab); }
        function openForKeyboard(tab) { root.openTab("network", tab); }
        function closeImmediate() { root.closeImmediate(); }
        function requestClose() { root.requestClose(); }
        function toggleCenter() { root.toggleTab("network"); }
        function refreshWifi() { networkView.refreshWifi(); }
        function refreshBluetooth() { networkView.refreshBluetooth(); }
    }

    readonly property var powerProfileProxy: QtObject {
        readonly property bool visible: root.visible && root.currentTabIndex === 1
        readonly property bool isOpen: root.isOpen && root.currentTabIndex === 1
        readonly property bool closingWithAnimation: root.closingWithAnimation

        function openNow() { root.openTab("power"); }
        function openForKeyboard() { root.openTab("power"); }
        function closeImmediate() { root.closeImmediate(); }
        function requestClose() { root.requestClose(); }
        function togglePanel() { root.toggleTab("power"); }
    }

    readonly property var notificationsProxy: QtObject {
        readonly property bool visible: root.visible && root.currentTabIndex === 2
        readonly property bool isOpen: root.isOpen && root.currentTabIndex === 2
        readonly property bool closingWithAnimation: root.closingWithAnimation

        function openNow() { root.openTab("notifications"); }
        function openForKeyboard() { root.openTab("notifications"); }
        function closeImmediate() { root.closeImmediate(); }
        function requestClose() { root.requestClose(); }
        function toggleCenter() { root.toggleTab("notifications"); }
    }
}
