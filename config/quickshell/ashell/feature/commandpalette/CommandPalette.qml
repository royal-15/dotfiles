import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs
import qs.components
import qs.feature.bar
import qs.feature.commandpalette
import "components"

Item {
    id: root

    property real compactW: 140
    readonly property real compactH: Decorations.pillHeight
    readonly property real compactR: compactH / 2

    readonly property real targetW: 560
    readonly property real targetH: 460
    readonly property real targetR: Decorations.cornerRadius

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
                searchBar.text = "";
                CommandPaletteService.searchQuery = "";
                if (dialog.isOpen)
                    dialog.close();
            } else if (islandSurface.expanded) {
                root.focusSearch();
            }
        }
    }

    function openForKeyboard() {
        StatusBarPanelCoordinator.openPanel(root);
    }

    function openNow(argument) {
        searchBar.text = "";
        CommandPaletteService.searchQuery = "";
        listView.resetSelection();
        if (dialog.isOpen)
            dialog.close();
        CommandPaletteService.loadData();

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

    function closeImmediate() {
        morphAnimation.stop();
        islandSurface.expanded = false;
        islandSurface.closingWithAnimation = false;
        islandSurface.morphProgress = 0;
        searchBar.text = "";
        CommandPaletteService.searchQuery = "";
        if (dialog.isOpen)
            dialog.close();
    }

    function requestClose() {
        if (dialog.isOpen) {
            dialog.close();
            return;
        }

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

    function focusSearch() {
        if (!islandSurface.expanded || islandSurface.closingWithAnimation)
            return;
        if (dialog.isOpen)
            return;
        searchBar.focusInput();
    }

    function focusPrimaryTarget() {
        focusSearch();
    }

    Shortcut {
        sequence: "Escape"
        context: Qt.WindowShortcut
        enabled: islandSurface.expanded && !islandSurface.closingWithAnimation
        onActivated: {
            if (dialog.isOpen) {
                dialog.close();
            } else if (searchBar.text !== "") {
                searchBar.text = "";
            } else {
                root.requestClose();
            }
        }
    }

    // Global 's' key listener to refocus search when panel has focus outside search field
    Keys.onPressed: event => {
        if (dialog.isOpen)
            return;

        if (event.key === Qt.Key_S && !searchBar.searchField.activeFocus && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier))) {
            root.focusSearch();
            event.accepted = true;
        }
    }

    Keys.forwardTo: (islandSurface.expanded && !dialog.isOpen) ? [searchBar.searchField] : []

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

    // Unified Dynamic Island Surface: transforms between compact capsule and command palette card
    Rectangle {
        id: islandSurface

        property bool expanded: false
        property real morphProgress: 0.0
        property bool closingWithAnimation: false

        readonly property real currentW: Math.round(root.compactW + (root.targetW - root.compactW) * morphProgress)
        readonly property real currentH: Math.round(root.compactH + (root.targetH - root.compactH) * morphProgress)
        readonly property real currentR: Math.round(root.compactR + (root.targetR - root.compactR) * morphProgress)

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

        // Background click handler to refocus search bar
        MouseArea {
            anchors.fill: parent
            z: 0
            onClicked: {
                if (islandSurface.expanded && !dialog.isOpen)
                    root.focusSearch();
            }
        }

        // Inner Content Container with smooth crossfade
        Item {
            width: root.targetW - 24
            height: root.targetH - 24
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 12
            opacity: Math.max(0, (islandSurface.morphProgress - 0.25) / 0.75)
            visible: opacity > 0.01
            z: 1

            ColumnLayout {
                anchors.fill: parent
                spacing: 10

                CommandPaletteSearchBar {
                    id: searchBar
                    Layout.fillWidth: true
                    onTextChanged: {
                        CommandPaletteService.searchQuery = text;
                    }
                    onNavigateDown: listView.moveSelection(1)
                    onNavigateUp: listView.moveSelection(-1)
                    onActivateCurrent: listView.activateCurrent()
                    onDeleteCurrent: listView.deleteCurrent()
                    onToggleExpandCurrent: listView.toggleExpandCurrent()
                    onAddNewRequested: dialog.openForNew()
                    onEditCurrentRequested: listView.editCurrent()
                    onCloseRequested: root.requestClose()
                }

                CommandPaletteListView {
                    id: listView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    modelData: CommandPaletteService.filteredItems
                    onItemActivated: item => {
                        CommandPaletteService.copyEntry(item);
                        root.requestClose();
                    }
                    onItemCopyRequested: item => {
                        CommandPaletteService.copyEntry(item);
                        root.requestClose();
                    }
                    onItemEditRequested: item => {
                        dialog.openForEdit(item);
                    }
                    onItemDeleteRequested: item => {
                        CommandPaletteService.deleteEntry(item.id);
                    }
                }

                CommandPaletteFooter {
                    Layout.fillWidth: true
                    count: CommandPaletteService.filteredItems.length
                    totalCount: CommandPaletteService.totalCount
                }
            }

            // In-Palette Modal Dialog Overlay for Add / Edit
            CommandPaletteDialog {
                id: dialog
                anchors.fill: parent
                z: 100
                onSaved: (id, label, snippet) => {
                    if (id && id !== "") {
                        CommandPaletteService.updateEntry(id, label, snippet);
                    } else {
                        CommandPaletteService.addEntry(label, snippet);
                    }
                    root.focusSearch();
                }
                onDismissed: {
                    root.focusSearch();
                }
            }
        }
    }
}
