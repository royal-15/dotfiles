import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs
import qs.components
import qs.feature.bar
import qs.feature.launcher

Item {
    id: root

    property var monitor: null
    property var workspaceIds: []
    property real externalDimProgress: 0.0

    property string searchQuery: ""
    property int selectedIndex: 0
    property var searchResults: []
    property var pendingLaunchEntry: null

    readonly property bool isOpen: islandSurface.expanded
    readonly property bool isExpanded: islandSurface.expanded
    readonly property bool closingWithAnimation: islandSurface.closingWithAnimation
    readonly property real compactW: islandSurface.compactW
    readonly property real currentR: islandSurface.currentR
    property alias islandSurface: islandSurface
    property alias searchField: searchField

    implicitWidth: islandSurface.width
    implicitHeight: islandSurface.height
    width: islandSurface.width
    height: islandSurface.height

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
                islandSurface.isLaunching = false;
                islandSurface.launchingIndex = -1;
                root.searchQuery = "";
                searchField.text = "";
            } else if (islandSurface.expanded) {
                root.focusSearch();
            }
        }
    }

    Timer {
        id: launchTimer
        interval: 110
        repeat: false
        onTriggered: {
            if (root.pendingLaunchEntry) {
                LauncherService.launch(root.pendingLaunchEntry);
                root.pendingLaunchEntry = null;
            }
            root.requestClose();
        }
    }

    readonly property var iconCache: ({})

    function resolveIcon(iconName) {
        if (!iconName)
            return "";
        if (iconName.startsWith("/") || iconName.startsWith("file://"))
            return iconName.startsWith("/") ? ("file://" + iconName) : iconName;
        if (iconCache[iconName] !== undefined)
            return iconCache[iconName];

        // Prefer bitmap/PNG icons from theme to avoid QtSvg buffer size warnings
        const resolved = Quickshell.iconPath(iconName, false);
        const result = resolved ? (resolved.startsWith("/") ? ("file://" + resolved) : resolved) : "";
        iconCache[iconName] = result;
        return result;
    }

    function updateSearch() {
        const results = LauncherService.search(root.searchQuery);
        root.searchResults = results;
        root.selectedIndex = 0;
        if (appListView.count > 0)
            appListView.positionViewAtIndex(0, ListView.Beginning);
    }

    function focusSearch() {
        if (!islandSurface.expanded || islandSurface.closingWithAnimation)
            return;
        searchField.forceActiveFocus();
    }

    function openForKeyboard() {
        StatusBarPanelCoordinator.openPanel(root);
    }

    function openNow() {
        root.searchQuery = "";
        searchField.text = "";
        updateSearch();

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

        Qt.callLater(() => root.focusSearch());
    }

    function toggleLauncher() {
        if (islandSurface.expanded && !islandSurface.closingWithAnimation)
            requestClose();
        else
            openForKeyboard();
    }

    function closeImmediate() {
        morphAnimation.stop();
        islandSurface.expanded = false;
        islandSurface.closingWithAnimation = false;
        islandSurface.isLaunching = false;
        islandSurface.launchingIndex = -1;
        islandSurface.morphProgress = 0;
        root.searchQuery = "";
        searchField.text = "";
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

    function moveSelection(direction) {
        if (!searchResults || searchResults.length === 0)
            return;
        const total = searchResults.length;
        selectedIndex = (selectedIndex + direction + total) % total;
        appListView.positionViewAtIndex(selectedIndex, ListView.Contain);
    }

    function setSelectedIndex(idx) {
        if (!searchResults || searchResults.length === 0)
            return;
        const total = searchResults.length;
        selectedIndex = Math.max(0, Math.min(total - 1, idx));
        appListView.positionViewAtIndex(selectedIndex, ListView.Contain);
    }

    function launchCurrentSelection() {
        if (!searchResults || searchResults.length === 0)
            return;
        if (selectedIndex >= 0 && selectedIndex < searchResults.length) {
            const entry = searchResults[selectedIndex];
            islandSurface.isLaunching = true;
            islandSurface.launchingIndex = selectedIndex;
            root.pendingLaunchEntry = entry;
            launchTimer.restart();
        }
    }

    function switchWorkspace(wsId) {
        if (Hyprland.usingLua) {
            Hyprland.dispatch(`hl.dsp.focus({ workspace = "${wsId}" })`);
        } else {
            Hyprland.dispatch(`workspace ${wsId}`);
        }
    }

    // Fallback Window Shortcut for Escape
    Shortcut {
        sequence: "Escape"
        context: Qt.WindowShortcut
        enabled: islandSurface.expanded && !islandSurface.closingWithAnimation
        onActivated: {
            if (searchField.text !== "") {
                searchField.text = "";
                root.searchQuery = "";
                root.updateSearch();
            } else {
                root.requestClose();
            }
        }
    }

    Keys.forwardTo: islandSurface.expanded ? [searchField] : []

    // Ambient drop shadow tracking morphing geometry
    Rectangle {
        anchors.fill: islandSurface
        anchors.topMargin: 2
        anchors.bottomMargin: -1
        radius: islandSurface.currentR
        color: Colors.shadow
        opacity: (0.40 + 0.30 * islandSurface.morphProgress) * (islandSurface.expanded ? 1.0 : Math.max(0, 1.0 - root.externalDimProgress))
        visible: opacity > 0.01
        z: -1
    }

    // Unified Dynamic Island Surface: transforms between compact capsule and launcher card
    Rectangle {
        id: islandSurface

        property bool expanded: false
        property real morphProgress: 0
        property bool closingWithAnimation: false
        property bool isLaunching: false
        property int launchingIndex: -1

        readonly property real compactW: Math.max(120, (compactIndicators.implicitWidth > 0 ? compactIndicators.implicitWidth : 120) + 24)
        readonly property real compactH: Decorations.pillHeight
        readonly property real compactR: compactH / 2 // 12.5

        readonly property real targetW: 500
        readonly property real targetH: 460
        readonly property real targetR: Decorations.cornerRadius

        readonly property real currentW: Math.round(compactW + (targetW - compactW) * morphProgress)
        readonly property real currentH: Math.round(compactH + (targetH - compactH) * morphProgress)
        readonly property real currentR: Math.round(compactR + (targetR - compactR) * morphProgress)

        width: currentW
        height: currentH
        radius: currentR

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter

        scale: islandSurface.expanded ? 1.0 : (1.0 - 0.06 * root.externalDimProgress)
        transformOrigin: Item.Center
        opacity: islandSurface.expanded ? 1.0 : Math.max(0, 1.0 - root.externalDimProgress)
        visible: opacity > 0.01

        color: morphProgress > 0.35 ? Colors.panel : (compactHover.hovered ? Colors.surfaceSoft : Colors.surface)
        clip: true

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
            border.width: islandSurface.morphProgress > 0.4 ? 1 : 0
            border.color: Colors.border
            opacity: Math.max(0, Math.min(1, (islandSurface.morphProgress - 0.4) / 0.5))
            z: 20
        }

        // Background click handler to refocus search
        MouseArea {
            anchors.fill: parent
            z: 0
            onClicked: {
                if (islandSurface.expanded)
                    root.focusSearch();
            }
        }

        // ==========================================
        // COMPACT STATE: Workspace Indicators Pill
        // ==========================================
        Item {
            id: compactContainer
            anchors.fill: parent
            z: 10
            visible: islandSurface.morphProgress < 0.25
            opacity: Math.max(0, 1 - islandSurface.morphProgress / 0.25)

            HoverHandler {
                id: compactHover
                cursorShape: Qt.PointingHandCursor
                enabled: root.externalDimProgress < 0.95
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                enabled: root.externalDimProgress < 0.95
                onClicked: root.toggleLauncher()
            }

            WorkspaceIndicators {
                id: compactIndicators
                anchors.centerIn: parent
                monitor: root.monitor
                workspaceIds: root.workspaceIds
                onActiveWorkspaceClicked: root.toggleLauncher()
            }
        }

        // ==========================================
        // EXPANDED STATE: Application Launcher
        // ==========================================

        // Header: Search Bar Container
        Item {
            id: searchHeader
            anchors.top: parent.top
            anchors.topMargin: 12
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.right: parent.right
            anchors.rightMargin: 12
            height: 44
            z: 5

            visible: islandSurface.morphProgress > 0.15
            opacity: Math.max(0, Math.min(1, (islandSurface.morphProgress - 0.15) / 0.35))

            Rectangle {
                id: searchInputBox
                anchors.fill: parent
                radius: 13
                color: searchField.activeFocus ? Colors.surfaceMuted : Colors.surfaceSoft
                border.width: 1
                border.color: searchField.activeFocus ? Colors.accent : Colors.border

                Behavior on color {
                    ColorAnimation {
                        duration: Motion.durationFast
                        easing.type: Motion.easingStandard
                    }
                }

                Behavior on border.color {
                    ColorAnimation {
                        duration: Motion.durationFast
                        easing.type: Motion.easingStandard
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 12
                    spacing: 10

                    Text {
                        text: "search"
                        color: searchField.activeFocus ? Colors.accent : Colors.textDim
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 20
                        Layout.alignment: Qt.AlignVCenter

                        Behavior on color {
                            ColorAnimation {
                                duration: Motion.durationFast
                                easing.type: Motion.easingStandard
                            }
                        }
                    }

                    TextField {
                        id: searchField
                        enabled: islandSurface.expanded && !islandSurface.closingWithAnimation
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: Colors.text
                        placeholderText: "Search applications..."
                        placeholderTextColor: Colors.textDim
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        background: null
                        verticalAlignment: TextInput.AlignVCenter
                        selectionColor: Colors.selectedBackground
                        selectedTextColor: Colors.selectedText

                        onTextChanged: {
                            root.searchQuery = text;
                            root.updateSearch();
                        }

                        // Deterministic keyboard controls
                        Keys.onPressed: event => {
                            // Down Navigation: Down, Tab, Ctrl+N, Ctrl+J
                            if (event.key === Qt.Key_Down || (event.key === Qt.Key_Tab && !(event.modifiers & Qt.ShiftModifier))
                                || ((event.modifiers & Qt.ControlModifier) && (event.key === Qt.Key_N || event.key === Qt.Key_J))) {
                                root.moveSelection(1);
                                event.accepted = true;
                                return;
                            }

                            // Up Navigation: Up, Shift+Tab (Backtab), Ctrl+P, Ctrl+K
                            if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))
                                || ((event.modifiers & Qt.ControlModifier) && (event.key === Qt.Key_P || event.key === Qt.Key_K))) {
                                root.moveSelection(-1);
                                event.accepted = true;
                                return;
                            }

                            // Page Jumps
                            if (event.key === Qt.Key_PageDown) {
                                root.moveSelection(5);
                                event.accepted = true;
                                return;
                            }
                            if (event.key === Qt.Key_PageUp) {
                                root.moveSelection(-5);
                                event.accepted = true;
                                return;
                            }

                            // Home / End Jumps with Ctrl
                            if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_Home) {
                                root.setSelectedIndex(0);
                                event.accepted = true;
                                return;
                            }
                            if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_End) {
                                root.setSelectedIndex(root.searchResults.length - 1);
                                event.accepted = true;
                                return;
                            }

                            // Launch on Return / Enter
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                root.launchCurrentSelection();
                                event.accepted = true;
                                return;
                            }

                            // Dismiss / Clear on Escape
                            if (event.key === Qt.Key_Escape) {
                                if (searchField.text !== "") {
                                    searchField.text = "";
                                    root.searchQuery = "";
                                    root.updateSearch();
                                } else {
                                    root.requestClose();
                                }
                                event.accepted = true;
                                return;
                            }

                            // Alt + 1..9 to switch workspaces in background
                            if (event.modifiers & Qt.AltModifier) {
                                if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
                                    root.switchWorkspace(event.key - Qt.Key_0);
                                    event.accepted = true;
                                    return;
                                }
                            }
                        }
                    }

                    // Clear Query Button
                    Item {
                        Layout.preferredWidth: 26
                        Layout.preferredHeight: 26
                        visible: searchField.text !== ""
                        Layout.alignment: Qt.AlignVCenter

                        Rectangle {
                            anchors.fill: parent
                            radius: 13
                            color: clearMouse.containsMouse ? Colors.hover : Colors.clear

                            Text {
                                anchors.centerIn: parent
                                text: "close"
                                color: clearMouse.containsMouse ? Colors.text : Colors.textDim
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 16
                            }

                            MouseArea {
                                id: clearMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    searchField.text = "";
                                    root.searchQuery = "";
                                    root.updateSearch();
                                    searchField.forceActiveFocus();
                                }
                            }
                        }
                    }
                }
            }
        }

        // Section Label
        Item {
            id: sectionLabel
            anchors.top: searchHeader.bottom
            anchors.topMargin: 8
            anchors.left: parent.left
            anchors.leftMargin: 18
            anchors.right: parent.right
            anchors.rightMargin: 18
            height: 16
            z: 5

            visible: islandSurface.morphProgress > 0.30
            opacity: Math.max(0, Math.min(1, (islandSurface.morphProgress - 0.30) / 0.30))

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.searchQuery.trim() === ""
                    ? "RECENT APPLICATIONS"
                    : (root.searchResults.length > 0 ? "SEARCH RESULTS" : "NO MATCHING APPLICATIONS")
                color: Colors.textDim
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 10
                font.weight: Font.DemiBold
            }
        }

        // Results List Container
        Item {
            id: resultsContainer
            anchors.top: sectionLabel.bottom
            anchors.topMargin: 4
            anchors.bottom: dockDivider.top
            anchors.bottomMargin: 4
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.right: parent.right
            anchors.rightMargin: 10
            clip: true
            z: 5

            visible: islandSurface.morphProgress > 0.35
            opacity: Math.max(0, Math.min(1, (islandSurface.morphProgress - 0.35) / 0.35))

            ListView {
                id: appListView
                anchors.fill: parent
                spacing: 4
                model: root.searchResults
                currentIndex: root.selectedIndex
                boundsBehavior: Flickable.StopAtBounds

                delegate: Item {
                    id: appDelegate
                    required property var modelData
                    required property int index

                    readonly property bool isSelected: root.selectedIndex === index
                    readonly property bool isHovered: itemMouse.containsMouse
                    readonly property bool isLaunchingThis: islandSurface.isLaunching && islandSurface.launchingIndex === index

                    width: appListView.width
                    height: 48

                    Rectangle {
                        anchors.fill: parent
                        radius: 12
                        scale: appDelegate.isLaunchingThis ? 0.96 : 1.0
                        color: appDelegate.isLaunchingThis
                            ? Colors.accent
                            : (appDelegate.isSelected ? Colors.accentSoft : (appDelegate.isHovered ? Colors.hover : Colors.clear))
                        border.width: appDelegate.isSelected ? 1 : 0
                        border.color: Colors.accent

                        Behavior on scale {
                            NumberAnimation {
                                duration: Motion.durationFast
                                easing.type: Motion.easingStandard
                            }
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: Motion.durationFast
                                easing.type: Motion.easingStandard
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 12
                            spacing: 12

                            // App Icon
                            Rectangle {
                                Layout.preferredWidth: 32
                                Layout.preferredHeight: 32
                                Layout.alignment: Qt.AlignVCenter
                                radius: 8
                                color: appDelegate.isLaunchingThis ? Colors.accentSoft : Colors.surface

                                Image {
                                    id: appIcon
                                    anchors.centerIn: parent
                                    width: 22
                                    height: 22
                                    sourceSize.width: 48
                                    sourceSize.height: 48
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true
                                    source: root.resolveIcon(modelData.icon)
                                    visible: status === Image.Ready && source !== ""
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: "apps"
                                    color: Colors.accent
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 18
                                    visible: !appIcon.visible
                                }
                            }

                            // App Info
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 2

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.name || ""
                                    color: appDelegate.isLaunchingThis
                                        ? Colors.selectedText
                                        : Colors.text
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 13
                                    font.weight: appDelegate.isSelected ? Font.Bold : Font.Normal
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.genericName || modelData.comment || modelData.id || ""
                                    color: appDelegate.isLaunchingThis
                                        ? Colors.selectedText
                                        : (appDelegate.isSelected ? Colors.textDim : Colors.textFaint)
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                    visible: text !== ""
                                }
                            }

                            // "Enter to Launch" Hint Badge when selected
                            Rectangle {
                                Layout.alignment: Qt.AlignVCenter
                                Layout.preferredHeight: 22
                                Layout.preferredWidth: enterHintRow.implicitWidth + 12
                                radius: 6
                                color: Colors.accentSoft
                                visible: appDelegate.isSelected && !appDelegate.isLaunchingThis

                                RowLayout {
                                    id: enterHintRow
                                    anchors.centerIn: parent
                                    spacing: 4

                                    Text {
                                        text: "↵"
                                        color: Colors.accent
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 12
                                        font.weight: Font.Bold
                                    }

                                    Text {
                                        text: "Open"
                                        color: Colors.accent
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 10
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: itemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: {
                                root.setSelectedIndex(appDelegate.index);
                            }
                            onClicked: {
                                root.setSelectedIndex(appDelegate.index);
                                root.launchCurrentSelection();
                            }
                        }
                    }
                }
            }
        }

        // Divider separating list and bottom dock
        Rectangle {
            id: dockDivider
            anchors.bottom: bottomDock.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: islandSurface.morphProgress > 0.4 ? 1 : 0
            color: Colors.border
            opacity: Math.max(0, Math.min(1, (islandSurface.morphProgress - 0.4) / 0.35))
            z: 5
        }

        // Bottom Dock: Rounding matches islandSurface bottom corners seamlessly
        Item {
            id: bottomDock
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: Math.round(25 + (42 - 25) * islandSurface.morphProgress)
            z: 5

            visible: islandSurface.morphProgress > 0.20
            opacity: Math.max(0, Math.min(1, (islandSurface.morphProgress - 0.20) / 0.40))

            Rectangle {
                anchors.fill: parent
                color: islandSurface.morphProgress > 0.35 ? Colors.surface : Colors.clear
                bottomLeftRadius: islandSurface.currentR
                bottomRightRadius: islandSurface.currentR
                topLeftRadius: 0
                topRightRadius: 0

                Behavior on color {
                    ColorAnimation {
                        duration: Motion.durationFast
                        easing.type: Motion.easingStandard
                    }
                }
            }

            WorkspaceIndicators {
                anchors.centerIn: parent
                monitor: root.monitor
                workspaceIds: root.workspaceIds
            }
        }
    }
}
