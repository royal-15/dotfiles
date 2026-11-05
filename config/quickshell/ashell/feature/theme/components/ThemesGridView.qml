import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs
import qs.components
import qs.feature.theme

FocusScope {
    id: root

    property int selectedIndex: 0
    signal backRequested()

    implicitWidth: 540
    implicitHeight: 380

    function moveSelection(dx, dy) {
        const count = ThemeService.availableThemes ? ThemeService.availableThemes.length : 0;
        if (count === 0)
            return;
        const cols = 2;
        let next = selectedIndex + dx + (dy * cols);
        if (next < 0)
            next = 0;
        if (next >= count)
            next = count - 1;
        selectedIndex = next;
        gridView.positionViewAtIndex(selectedIndex, GridView.Contain);
    }

    function applySelected() {
        const list = ThemeService.availableThemes;
        if (list && selectedIndex >= 0 && selectedIndex < list.length) {
            ThemeService.switchTheme(list[selectedIndex].name);
        }
    }

    Keys.onLeftPressed: (event) => { moveSelection(-1, 0); event.accepted = true; }
    Keys.onRightPressed: (event) => { moveSelection(1, 0); event.accepted = true; }
    Keys.onUpPressed: (event) => { moveSelection(0, -1); event.accepted = true; }
    Keys.onDownPressed: (event) => { moveSelection(0, 1); event.accepted = true; }
    Keys.onTabPressed: (event) => { moveSelection(1, 0); event.accepted = true; }
    Keys.onBacktabPressed: (event) => { moveSelection(-1, 0); event.accepted = true; }
    Keys.onReturnPressed: (event) => { applySelected(); event.accepted = true; }
    Keys.onEnterPressed: (event) => { applySelected(); event.accepted = true; }
    Keys.onEscapePressed: (event) => { root.backRequested(); event.accepted = true; }
    Keys.onBackPressed: (event) => { root.backRequested(); event.accepted = true; }

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Backspace) {
            if (!event.isAutoRepeat)
                root.backRequested();
            event.accepted = true;
        } else if (event.key === Qt.Key_H) {
            moveSelection(-1, 0);
            event.accepted = true;
        } else if (event.key === Qt.Key_L) {
            moveSelection(1, 0);
            event.accepted = true;
        } else if (event.key === Qt.Key_K) {
            moveSelection(0, -1);
            event.accepted = true;
        } else if (event.key === Qt.Key_J) {
            moveSelection(0, 1);
            event.accepted = true;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        // Header Row: Back button + Title
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                implicitWidth: backRow.implicitWidth + 14
                implicitHeight: 28
                radius: 14
                color: backMouse.containsMouse ? Colors.surface : Colors.surfaceSoft
                border.width: 1
                border.color: backMouse.containsMouse ? Colors.accent : Colors.border

                Behavior on color {
                    ColorAnimation {
                        duration: Motion.durationFast
                        easing.type: Motion.easingStandard
                    }
                }

                MouseArea {
                    id: backMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.backRequested()
                }

                RowLayout {
                    id: backRow
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: "arrow_back"
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 15
                        color: Colors.accent
                    }

                    Text {
                        text: "Back (Esc)"
                        color: backMouse.containsMouse ? Colors.text : Colors.textDim
                        font.pixelSize: 11
                        font.weight: Font.Medium
                    }
                }
            }

            Text {
                text: "Themes"
                color: Colors.text
                font.pixelSize: 15
                font.weight: Font.Bold
                Layout.fillWidth: true
            }

            Text {
                text: ThemeService.availableThemes ? (ThemeService.availableThemes.length + " available") : ""
                color: Colors.textDim
                font.pixelSize: 11
            }
        }

        // Grid View of Themes with automatic contain scrolling
        GridView {
            id: gridView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            cellWidth: 256
            cellHeight: 84
            model: ThemeService.availableThemes
            currentIndex: root.selectedIndex

            delegate: ThemeCard {
                required property var modelData
                required property int index

                themeName: modelData.name
                previewColors: modelData.preview
                isActive: modelData.name === ThemeService.activeTheme
                isHighlighted: index === root.selectedIndex
                onActivated: {
                    root.selectedIndex = index;
                    gridView.positionViewAtIndex(index, GridView.Contain);
                    ThemeService.switchTheme(modelData.name);
                }
            }
        }
    }

    function syncActiveSelection() {
        const list = ThemeService.availableThemes;
        if (!list || list.length === 0) {
            root.selectedIndex = 0;
            return;
        }
        const activeIdx = list.findIndex(entry => entry.name === ThemeService.activeTheme);
        if (activeIdx >= 0) {
            root.selectedIndex = activeIdx;
            gridView.positionViewAtIndex(activeIdx, GridView.Contain);
        } else {
            root.selectedIndex = Math.max(0, Math.min(list.length - 1, root.selectedIndex));
            gridView.positionViewAtIndex(root.selectedIndex, GridView.Contain);
        }
    }

    Connections {
        target: ThemeService
        function onAvailableThemesChanged() {
            root.syncActiveSelection();
        }
        function onActiveThemeChanged() {
            root.syncActiveSelection();
        }
    }

    Component.onCompleted: {
        root.syncActiveSelection();
    }
}
