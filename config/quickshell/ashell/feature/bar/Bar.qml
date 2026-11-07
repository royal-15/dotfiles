import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import qs
import qs.components
import qs.feature.bar
import qs.feature.network
import qs.feature.powerprofile
import qs.feature.launcher
import qs.feature.notifications
import qs.feature.sidebar
import qs.feature.osd
import qs.feature.media
import qs.feature.theme
import qs.feature.clipboard
import qs.feature.commandpalette

PanelWindow {
    id: bar

    property var modelData

    readonly property bool anyRightPanelOpen: rightSidebar.isOpen
    readonly property bool anyPanelOpen: launcher.isOpen || themeStudio.isOpen || rightSidebar.isOpen || mediaIsland.isOpen || clipboard.isOpen || commandPalette.isOpen

    screen: modelData
    implicitHeight: 490
    exclusiveZone: Decorations.exclusiveZoneHeight
    color: Colors.clear
    focusable: (launcher.isOpen && !launcher.closingWithAnimation) || (themeStudio.isOpen && !themeStudio.closingWithAnimation) || (clipboard.isOpen && !clipboard.closingWithAnimation) || (commandPalette.isOpen && !commandPalette.closingWithAnimation) || (mediaIsland.isOpen && !mediaIsland.closingWithAnimation) || StatusBarPanelCoordinator.isSwitching

    anchors {
        top: true
        left: true
        right: true
    }

    margins {
        top: Decorations.barTopOffset
        left: Decorations.barLeftRightMargin
        right: Decorations.barLeftRightMargin
    }

    // Dynamic click-through input mask: only bar pills and the morphing islands catch clicks
    mask: Region {
        Region { item: leftGroup }
        Region {
            item: (commandPalette.isOpen || commandPalette.closingWithAnimation)
                ? commandPalette.islandSurface
                : ((clipboard.isOpen || clipboard.closingWithAnimation)
                    ? clipboard.islandSurface
                    : ((themeStudio.isOpen || themeStudio.closingWithAnimation) ? themeStudio.islandSurface : launcher.islandSurface))
            radius: (commandPalette.isOpen || commandPalette.closingWithAnimation)
                ? commandPalette.islandSurface.currentR
                : ((clipboard.isOpen || clipboard.closingWithAnimation)
                    ? clipboard.islandSurface.currentR
                    : ((themeStudio.isOpen || themeStudio.closingWithAnimation) ? themeStudio.islandSurface.currentR : launcher.islandSurface.currentR))
        }
        Region { item: mediaIsland.islandSurface; radius: mediaIsland.islandSurface.currentR }
        Region { item: rightGroup }
    }

    HyprlandFocusGrab {
        id: launcherFocusGrab
        windows: [bar]
        active: launcher.isOpen && !launcher.closingWithAnimation
        onActiveChanged: {
            if (active)
                launcher.focusSearch();
        }
        onCleared: {
            if (launcher.isOpen && !launcher.closingWithAnimation)
                launcher.requestClose();
        }
    }

    HyprlandFocusGrab {
        id: themeStudioFocusGrab
        windows: [bar]
        active: themeStudio.isOpen && !themeStudio.closingWithAnimation
        onActiveChanged: {
            if (active)
                themeStudio.focusPrimary();
        }
        onCleared: {
            if (themeStudio.isOpen && !themeStudio.closingWithAnimation)
                themeStudio.requestClose();
        }
    }

    HyprlandFocusGrab {
        id: clipboardFocusGrab
        windows: [bar]
        active: clipboard.isOpen && !clipboard.closingWithAnimation
        onActiveChanged: {
            if (active)
                clipboard.focusSearch();
        }
        onCleared: {
            if (clipboard.isOpen && !clipboard.closingWithAnimation)
                clipboard.requestClose();
        }
    }

    HyprlandFocusGrab {
        id: commandPaletteFocusGrab
        windows: [bar]
        active: commandPalette.isOpen && !commandPalette.closingWithAnimation
        onActiveChanged: {
            if (active)
                commandPalette.focusSearch();
        }
        onCleared: {
            if (commandPalette.isOpen && !commandPalette.closingWithAnimation)
                commandPalette.requestClose();
        }
    }

    HyprlandFocusGrab {
        id: mediaFocusGrab
        windows: [bar]
        active: mediaIsland.isOpen && !mediaIsland.closingWithAnimation
        onCleared: {
            if (mediaIsland.isOpen && !mediaIsland.closingWithAnimation)
                mediaIsland.requestClose();
        }
    }

    // Status Bar Capsule Row (fixed at top 35px height)
    Item {
        id: barHeader
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: Decorations.barCapsuleHeight

        RowLayout {
            id: leftGroup

            anchors.left: parent.left
            anchors.leftMargin: Decorations.barItemMarginHorizontal
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Pill {
                label: StatusBarService.clockValue
                textColor: Colors.text
            }

            Pill {
                label: StatusBarService.cpuTemperature
                textColor: StatusBarService.statusColor(StatusBarService.cpuTemperature, 40, 100)
            }
        }

        // Center: Dynamic Island (Workspace Indicators Capsule <-> Application Launcher / Theme Studio / Clipboard)
        Item {
            id: centerGroup
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            height: Decorations.barCapsuleHeight
            width: launcher.compactW

            Launcher {
                id: launcher
                monitor: modelData ? Hyprland.monitorFor(modelData) : null
                workspaceIds: WorkspaceResolver.resolve(modelData ? modelData.name : "")
                externalDimProgress: Math.max(mediaIsland.workspaceDimProgress, themeStudio.workspaceDimProgress, clipboard.workspaceDimProgress, commandPalette.workspaceDimProgress)
                anchors.top: parent.top
                anchors.topMargin: Decorations.barItemMarginVertical
                anchors.horizontalCenter: parent.horizontalCenter
            }

            ThemeStudio {
                id: themeStudio
                compactW: launcher.compactW
                anchors.top: parent.top
                anchors.topMargin: Decorations.barItemMarginVertical
                anchors.horizontalCenter: parent.horizontalCenter
                z: 40
                enabled: isOpen || closingWithAnimation
                visible: isOpen || closingWithAnimation
            }

            Clipboard {
                id: clipboard
                compactW: launcher.compactW
                anchors.top: parent.top
                anchors.topMargin: Decorations.barItemMarginVertical
                anchors.horizontalCenter: parent.horizontalCenter
                z: 42
                enabled: isOpen || closingWithAnimation
                visible: isOpen || closingWithAnimation
            }

            CommandPalette {
                id: commandPalette
                compactW: launcher.compactW
                anchors.top: parent.top
                anchors.topMargin: Decorations.barItemMarginVertical
                anchors.horizontalCenter: parent.horizontalCenter
                z: 43
                enabled: isOpen || closingWithAnimation
                visible: isOpen || closingWithAnimation
            }
        }

        // Satellite Media Island (Equalizer Bubble <-> Morphing Now Playing Card)
        MediaIsland {
            id: mediaIsland
            barWindow: bar
            launcherItem: launcher
            themeStudioItem: themeStudio
            clipboardItem: clipboard
            commandPaletteItem: commandPalette
            monitor: modelData ? Hyprland.monitorFor(modelData) : null
            z: mediaIsland.isOpen ? 50 : 5
        }

        RowLayout {
            id: rightGroup

            anchors.right: parent.right
            anchors.rightMargin: Decorations.barItemMarginHorizontal
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            StatusCapsule {
                id: statusCapsule
                networkActive: rightSidebar.isOpen && rightSidebar.currentTabIndex === 0
                powerActive: rightSidebar.isOpen && rightSidebar.currentTabIndex === 1
                dimmed: bar.anyRightPanelOpen && rightSidebar.currentTabIndex !== 0 && rightSidebar.currentTabIndex !== 1
                onWifiClicked: rightSidebar.toggleTab("network")
                onPowerClicked: rightSidebar.toggleTab("power")
            }

            NotificationPill {
                id: notificationPill
                highlighted: rightSidebar.isOpen && rightSidebar.currentTabIndex === 2
                dimmed: bar.anyRightPanelOpen && rightSidebar.currentTabIndex !== 2
                onClicked: rightSidebar.toggleTab("notifications")
            }
        }
    }

    RightSidebar {
        id: rightSidebar
        barWindow: bar
    }

    Binding {
        target: NotificationService
        property: "anyPanelOpen"
        value: bar.anyPanelOpen
    }

    Connections {
        target: NotificationService
        function onUnreadCountChanged() {
            if (bar.anyPanelOpen && NotificationService.unreadCount > 0) {
                notificationPill.pulseBadge();
            }
        }
    }

    NotificationToastManager {
        modelData: bar.screen
        anyPanelOpen: bar.anyPanelOpen
    }

    OsdManager {
        modelData: bar.screen
    }

    onScreenChanged: {
        if (screen) {
            NetworkCenterRouter.registerPanel(screen, rightSidebar.networkProxy);
            PowerProfileRouter.registerPanel(screen, rightSidebar.powerProfileProxy);
            NotificationCenterRouter.registerPanel(screen, rightSidebar.notificationsProxy);
            LauncherRouter.registerPanel(screen, launcher);
            ThemeRouter.registerPanel(screen, themeStudio);
            ClipboardRouter.registerPanel(screen, clipboard);
            CommandPaletteRouter.registerPanel(screen, commandPalette);
            MediaRouter.registerPanel(screen, mediaIsland);
            StatusBarPanelCoordinator.registerPanel(screen, rightSidebar);
            StatusBarPanelCoordinator.registerPanel(screen, launcher);
            StatusBarPanelCoordinator.registerPanel(screen, themeStudio);
            StatusBarPanelCoordinator.registerPanel(screen, clipboard);
            StatusBarPanelCoordinator.registerPanel(screen, commandPalette);
            StatusBarPanelCoordinator.registerPanel(screen, mediaIsland);
        }
    }

    Component.onCompleted: {
        NetworkCenterRouter.registerPanel(bar.screen, rightSidebar.networkProxy);
        PowerProfileRouter.registerPanel(bar.screen, rightSidebar.powerProfileProxy);
        NotificationCenterRouter.registerPanel(bar.screen, rightSidebar.notificationsProxy);
        LauncherRouter.registerPanel(bar.screen, launcher);
        ThemeRouter.registerPanel(bar.screen, themeStudio);
        ClipboardRouter.registerPanel(bar.screen, clipboard);
        CommandPaletteRouter.registerPanel(bar.screen, commandPalette);
        MediaRouter.registerPanel(bar.screen, mediaIsland);
        StatusBarPanelCoordinator.registerPanel(bar.screen, rightSidebar);
        StatusBarPanelCoordinator.registerPanel(bar.screen, launcher);
        StatusBarPanelCoordinator.registerPanel(bar.screen, themeStudio);
        StatusBarPanelCoordinator.registerPanel(bar.screen, clipboard);
        StatusBarPanelCoordinator.registerPanel(bar.screen, commandPalette);
        StatusBarPanelCoordinator.registerPanel(bar.screen, mediaIsland);
    }
    Component.onDestruction: {
        NetworkCenterRouter.unregisterPanel(rightSidebar.networkProxy);
        PowerProfileRouter.unregisterPanel(rightSidebar.powerProfileProxy);
        NotificationCenterRouter.unregisterPanel(rightSidebar.notificationsProxy);
        LauncherRouter.unregisterPanel(launcher);
        ThemeRouter.unregisterPanel(themeStudio);
        ClipboardRouter.unregisterPanel(clipboard);
        CommandPaletteRouter.unregisterPanel(commandPalette);
        MediaRouter.unregisterPanel(mediaIsland);
        StatusBarPanelCoordinator.unregisterPanel(rightSidebar);
        StatusBarPanelCoordinator.unregisterPanel(launcher);
        StatusBarPanelCoordinator.unregisterPanel(themeStudio);
        StatusBarPanelCoordinator.unregisterPanel(clipboard);
        StatusBarPanelCoordinator.unregisterPanel(commandPalette);
        StatusBarPanelCoordinator.unregisterPanel(mediaIsland);
    }
}
