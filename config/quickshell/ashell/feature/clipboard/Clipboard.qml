import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs
import qs.components
import qs.feature.bar
import qs.feature.clipboard
import "components"

Item {
    id: root

    property real compactW: 140
    readonly property real compactH: Decorations.pillHeight
    readonly property real compactR: compactH / 2 // 12.5

    readonly property real targetW: 520
    readonly property real targetH: 440
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
                ClipboardService.searchQuery = "";
            } else if (islandSurface.expanded) {
                root.focusSearch();
            }
        }
    }

    function openForKeyboard() {
        StatusBarPanelCoordinator.openPanel(root);
    }

    function openNow() {
        searchBar.text = "";
        ClipboardService.searchQuery = "";
        ClipboardService.refresh();

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
        ClipboardService.searchQuery = "";
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

    function focusSearch() {
        if (!islandSurface.expanded || islandSurface.closingWithAnimation)
            return;
        searchBar.focusInput();
    }

    Shortcut {
        sequence: "Escape"
        context: Qt.WindowShortcut
        enabled: islandSurface.expanded && !islandSurface.closingWithAnimation
        onActivated: {
            if (searchBar.text !== "") {
                searchBar.text = "";
            } else {
                root.requestClose();
            }
        }
    }

    Keys.forwardTo: islandSurface.expanded ? [searchBar.searchField] : []

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

    // Unified Dynamic Island Surface: transforms between compact capsule and clipboard card
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

        Item {
            anchors.fill: parent
            anchors.margins: 12
            opacity: Math.max(0, (islandSurface.morphProgress - 0.25) / 0.75)
            visible: opacity > 0.01

            ColumnLayout {
                anchors.fill: parent
                spacing: 10

                ClipboardSearchBar {
                    id: searchBar
                    Layout.fillWidth: true
                    onTextChanged: {
                        ClipboardService.searchQuery = text;
                    }
                    onNavigateDown: listView.moveSelection(1)
                    onNavigateUp: listView.moveSelection(-1)
                    onActivateCurrent: listView.activateCurrent()
                    onDeleteCurrent: listView.deleteCurrent()
                    onCloseRequested: root.requestClose()
                }

                ClipboardListView {
                    id: listView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    modelData: ClipboardService.filteredItems
                    onItemActivated: item => {
                        ClipboardService.copyItem(item);
                        root.requestClose();
                    }
                    onItemDeleteRequested: item => {
                        ClipboardService.deleteItem(item);
                    }
                }

                ClipboardFooter {
                    Layout.fillWidth: true
                    count: ClipboardService.filteredItems.length
                    totalCount: ClipboardService.totalCount
                }
            }
        }
    }
}
