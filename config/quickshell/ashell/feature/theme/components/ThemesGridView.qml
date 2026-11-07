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
    signal openWallpapersRequested()

    implicitWidth: 560
    implicitHeight: 400

    function moveSelection(dx, dy) {
        const count = ThemeService.availableThemes ? ThemeService.availableThemes.length : 0;
        if (count === 0)
            return;
        const cols = 2;
        let next = selectedIndex + dx + (dy * cols);
        if (next < 0) {
            next = (count - 1);
        } else if (next >= count) {
            next = 0;
        }
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
    Keys.onTabPressed: (event) => {
        if (event.modifiers & Qt.ControlModifier) {
            root.openWallpapersRequested();
        } else {
            moveSelection(1, 0);
        }
        event.accepted = true;
    }
    Keys.onBacktabPressed: (event) => {
        if (event.modifiers & Qt.ControlModifier) {
            root.openWallpapersRequested();
        } else {
            moveSelection(-1, 0);
        }
        event.accepted = true;
    }
    Keys.onReturnPressed: (event) => { applySelected(); event.accepted = true; }
    Keys.onEnterPressed: (event) => { applySelected(); event.accepted = true; }
    Keys.onSpacePressed: (event) => { applySelected(); event.accepted = true; }
    Keys.onEscapePressed: (event) => { root.backRequested(); event.accepted = true; }
    Keys.onBackPressed: (event) => { root.backRequested(); event.accepted = true; }

    Keys.onPressed: (event) => {
        if ((event.modifiers & Qt.ControlModifier) && (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab)) {
            root.openWallpapersRequested();
            event.accepted = true;
        } else if (event.key === Qt.Key_Backspace) {
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
        } else if (event.key === Qt.Key_2 || event.text.toLowerCase() === "w") {
            root.openWallpapersRequested();
            event.accepted = true;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        // Top Navigation Header
        ThemeStudioHeader {
            Layout.fillWidth: true
            activeStage: "themes"
            infoText: ThemeService.availableThemes ? (ThemeService.availableThemes.length + " themes") : "0 themes"
            onBackRequested: root.backRequested()
            onSwitchStageRequested: (stage) => {
                if (stage === "wallpapers")
                    root.openWallpapersRequested();
            }
        }

        // Themes Grid View
        GridView {
            id: gridView
            Layout.fillWidth: true
            Layout.fillHeight: true
            topMargin: 2
            bottomMargin: 2
            clip: true
            cellWidth: 266
            cellHeight: 88
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

    onVisibleChanged: {
        if (visible) {
            root.syncActiveSelection();
        }
    }
}
