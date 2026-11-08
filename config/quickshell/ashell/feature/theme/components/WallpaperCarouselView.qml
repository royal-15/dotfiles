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
    signal openThemesRequested()
    signal closeRequested()

    implicitWidth: 700
    implicitHeight: 290

    readonly property real cardW: 260
    readonly property real cardH: 154

    function moveSelection(direction) {
        const count = ThemeService.availableWallpapers ? ThemeService.availableWallpapers.length : 0;
        if (count <= 1)
            return;
        let next = (selectedIndex + direction) % count;
        if (next < 0)
            next += count;
        selectedIndex = next;
        carouselList.currentIndex = next;
    }

    function selectIndex(idx) {
        const count = ThemeService.availableWallpapers ? ThemeService.availableWallpapers.length : 0;
        if (count === 0)
            return;
        selectedIndex = Math.max(0, Math.min(count - 1, idx));
        carouselList.currentIndex = selectedIndex;
    }

    function applySelected() {
        const list = ThemeService.availableWallpapers;
        if (list && selectedIndex >= 0 && selectedIndex < list.length) {
            const selectedItem = list[selectedIndex];
            if (ThemeService.isWallpaperActive(selectedItem.name)) {
                root.closeRequested();
            } else {
                ThemeService.switchWallpaper(selectedItem.name);
            }
        }
    }

    Keys.onLeftPressed: (event) => { moveSelection(-1); event.accepted = true; }
    Keys.onRightPressed: (event) => { moveSelection(1); event.accepted = true; }
    Keys.onTabPressed: (event) => {
        if (event.modifiers & Qt.ControlModifier) {
            root.openThemesRequested();
        } else {
            moveSelection(1);
        }
        event.accepted = true;
    }
    Keys.onBacktabPressed: (event) => {
        if (event.modifiers & Qt.ControlModifier) {
            root.openThemesRequested();
        } else {
            moveSelection(-1);
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
            root.openThemesRequested();
            event.accepted = true;
        } else if (event.key === Qt.Key_Backspace) {
            if (!event.isAutoRepeat)
                root.backRequested();
            event.accepted = true;
        } else if (event.key === Qt.Key_H) {
            moveSelection(-1);
            event.accepted = true;
        } else if (event.key === Qt.Key_L) {
            moveSelection(1);
            event.accepted = true;
        } else if (event.key === Qt.Key_1 || event.text.toLowerCase() === "t") {
            root.openThemesRequested();
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
            activeStage: "wallpapers"
            infoText: (ThemeService.activeTheme ? ThemeService.activeTheme : "Default") + " • " + (ThemeService.availableWallpapers ? ThemeService.availableWallpapers.length : 0) + " items"
            onBackRequested: root.backRequested()
            onSwitchStageRequested: (stage) => {
                if (stage === "themes")
                    root.openThemesRequested();
            }
        }

        // Centered Carousel Container with Peeking Viewport
        Item {
            id: carouselContainer
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            // Centered Horizontal Carousel
            ListView {
                id: carouselList
                anchors.fill: parent
                orientation: ListView.Horizontal
                spacing: 16
                clip: false
                model: ThemeService.availableWallpapers
                currentIndex: root.selectedIndex

                onCurrentIndexChanged: {
                    if (root.selectedIndex !== currentIndex) {
                        root.selectedIndex = currentIndex;
                    }
                }

                // Center snapping configuration
                preferredHighlightBegin: Math.round((width - root.cardW) / 2)
                preferredHighlightEnd: Math.round((width + root.cardW) / 2)
                highlightRangeMode: ListView.StrictlyEnforceRange
                highlightMoveDuration: Motion.durationNormal
                snapMode: ListView.SnapToItem

                // Padding margins to allow item 0 and item N to reach center
                leftMargin: Math.max(0, Math.round((width - root.cardW) / 2))
                rightMargin: Math.max(0, Math.round((width - root.cardW) / 2))

                delegate: WallpaperCard {
                    required property var modelData
                    required property int index

                    wallpaperName: modelData.name
                    wallpaperUrl: modelData.fullUrl
                    isActive: ThemeService.isWallpaperActive(modelData.name)
                    isHighlighted: ListView.isCurrentItem
                    index: index
                    totalCount: ThemeService.availableWallpapers ? ThemeService.availableWallpapers.length : 0

                    onActivated: {
                        root.selectedIndex = index;
                        carouselList.currentIndex = index;
                        if (!ThemeService.isWallpaperActive(modelData.name)) {
                            ThemeService.switchWallpaper(modelData.name);
                        }
                    }

                    onSelectRequested: {
                        root.selectIndex(index);
                    }

                    onDoubleActivated: {
                        root.selectedIndex = index;
                        carouselList.currentIndex = index;
                        if (!ThemeService.isWallpaperActive(modelData.name)) {
                            ThemeService.switchWallpaper(modelData.name);
                        }
                        root.closeRequested();
                    }
                }
            }

            // Left Edge Soft Vignette Fade
            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 32
                z: 20
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Colors.panel }
                    GradientStop { position: 1.0; color: Colors.clear }
                }
            }

            // Right Edge Soft Vignette Fade
            Rectangle {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 32
                z: 20
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Colors.clear }
                    GradientStop { position: 1.0; color: Colors.panel }
                }
            }
        }
    }

    function syncActiveSelection() {
        const list = ThemeService.availableWallpapers;
        if (!list || list.length === 0) {
            root.selectedIndex = 0;
            carouselList.currentIndex = 0;
            return;
        }
        const activeIdx = list.findIndex(entry => ThemeService.isWallpaperActive(entry.name));
        if (activeIdx >= 0) {
            root.selectedIndex = activeIdx;
            carouselList.currentIndex = activeIdx;
        } else {
            root.selectedIndex = Math.max(0, Math.min(list.length - 1, root.selectedIndex));
            carouselList.currentIndex = root.selectedIndex;
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
