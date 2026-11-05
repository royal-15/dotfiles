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

    implicitWidth: 640
    implicitHeight: 260

    function moveSelection(direction) {
        const count = ThemeService.availableWallpapers ? ThemeService.availableWallpapers.length : 0;
        if (count === 0)
            return;
        selectedIndex = Math.max(0, Math.min(count - 1, selectedIndex + direction));
        carouselList.positionViewAtIndex(selectedIndex, ListView.Contain);
    }

    function applySelected() {
        const list = ThemeService.availableWallpapers;
        if (list && selectedIndex >= 0 && selectedIndex < list.length) {
            ThemeService.switchWallpaper(list[selectedIndex].name);
        }
    }

    Keys.onLeftPressed: (event) => { moveSelection(-1); event.accepted = true; }
    Keys.onRightPressed: (event) => { moveSelection(1); event.accepted = true; }
    Keys.onTabPressed: (event) => { moveSelection(1); event.accepted = true; }
    Keys.onBacktabPressed: (event) => { moveSelection(-1); event.accepted = true; }
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
            moveSelection(-1);
            event.accepted = true;
        } else if (event.key === Qt.Key_L) {
            moveSelection(1);
            event.accepted = true;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        // Header Row
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
                text: "Wallpapers"
                color: Colors.text
                font.pixelSize: 15
                font.weight: Font.Bold
                Layout.fillWidth: true
            }

            Text {
                text: ThemeService.activeTheme + " • " + (ThemeService.availableWallpapers ? ThemeService.availableWallpapers.length : 0) + " items"
                color: Colors.textDim
                font.pixelSize: 11
            }
        }

        // Horizontal Carousel
        ListView {
            id: carouselList
            Layout.fillWidth: true
            Layout.fillHeight: true
            orientation: ListView.Horizontal
            spacing: 12
            clip: true
            model: ThemeService.availableWallpapers

            delegate: WallpaperCard {
                required property var modelData
                required property int index

                wallpaperName: modelData.name
                wallpaperUrl: modelData.fullUrl
                isActive: ThemeService.isWallpaperActive(modelData.name)
                isHighlighted: index === root.selectedIndex
                onActivated: {
                    root.selectedIndex = index;
                    carouselList.positionViewAtIndex(index, ListView.Contain);
                    ThemeService.switchWallpaper(modelData.name);
                }
            }
        }
    }

    function syncActiveSelection() {
        const list = ThemeService.availableWallpapers;
        if (!list || list.length === 0) {
            root.selectedIndex = 0;
            return;
        }
        const activeIdx = list.findIndex(entry => ThemeService.isWallpaperActive(entry.name));
        if (activeIdx >= 0) {
            root.selectedIndex = activeIdx;
            carouselList.positionViewAtIndex(activeIdx, ListView.Contain);
        } else {
            root.selectedIndex = Math.max(0, Math.min(list.length - 1, root.selectedIndex));
            carouselList.positionViewAtIndex(root.selectedIndex, ListView.Contain);
        }
    }

    Connections {
        target: ThemeService
        function onAvailableWallpapersChanged() {
            root.syncActiveSelection();
        }
        function onActiveWallpaperChanged() {
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
