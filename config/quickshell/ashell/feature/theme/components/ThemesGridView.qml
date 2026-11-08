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

    readonly property string searchQuery: searchBar.text
    readonly property bool isSearching: searchQuery.length > 0
    property var filteredThemes: []
    readonly property var activeThemesList: isSearching ? filteredThemes : (ThemeService.availableThemes || [])

    function updateFilteredThemes() {
        if (!isSearching) {
            filteredThemes = ThemeService.availableThemes || [];
            syncActiveSelection();
            return;
        }
        const q = searchQuery.toLowerCase().trim();
        const list = ThemeService.availableThemes || [];
        const matches = [];
        for (let i = 0; i < list.length; i++) {
            const item = list[i];
            if (item && item.name && item.name.toLowerCase().indexOf(q) >= 0) {
                matches.push(item);
            }
        }
        filteredThemes = matches;
        if (matches.length > 0) {
            selectedIndex = Math.max(0, Math.min(matches.length - 1, selectedIndex));
            gridView.positionViewAtIndex(selectedIndex, GridView.Contain);
        } else {
            selectedIndex = -1;
        }
    }

    onSearchQueryChanged: updateFilteredThemes()

    onIsSearchingChanged: {
        if (isSearching) {
            Qt.callLater(() => {
                searchBar.searchField.forceActiveFocus();
                searchBar.searchField.cursorPosition = searchBar.text.length;
            });
        } else {
            root.forceActiveFocus();
            syncActiveSelection();
        }
    }

    function clearSearch() {
        searchBar.text = "";
        root.forceActiveFocus();
        syncActiveSelection();
    }

    function moveSelection(dx, dy) {
        const list = activeThemesList;
        const count = list ? list.length : 0;
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
        const list = activeThemesList;
        if (list && selectedIndex >= 0 && selectedIndex < list.length) {
            const selectedItem = list[selectedIndex];
            if (selectedItem.name === ThemeService.activeTheme) {
                root.openWallpapersRequested();
            } else {
                ThemeService.switchTheme(selectedItem.name);
            }
        }
    }

    function getPrintableChar(event) {
        if (event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))
            return "";

        // First check event.text if populated with a single printable character
        if (event.text && event.text.length === 1) {
            const code = event.text.charCodeAt(0);
            if (code >= 32 && code <= 126)
                return event.text;
        }

        // Direct fallback on Qt.Key enum for Wayland/Hyprland where event.text can be empty on non-input FocusScopes
        if (event.key >= Qt.Key_A && event.key <= Qt.Key_Z) {
            const charStr = String.fromCharCode(event.key);
            return (event.modifiers & Qt.ShiftModifier) ? charStr : charStr.toLowerCase();
        }

        if (event.key >= Qt.Key_0 && event.key <= Qt.Key_9) {
            return String.fromCharCode(event.key);
        }

        if (event.key === Qt.Key_Minus) return "-";
        if (event.key === Qt.Key_Underscore) return "_";

        return "";
    }

    function startSearchWith(ch) {
        searchBar.text = ch;
        updateFilteredThemes();
        Qt.callLater(() => {
            searchBar.searchField.forceActiveFocus();
            searchBar.searchField.cursorPosition = searchBar.text.length;
        });
    }

    Keys.forwardTo: isSearching ? [searchBar.searchField] : []

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
    Keys.onEscapePressed: (event) => {
        if (isSearching) {
            clearSearch();
        } else {
            root.backRequested();
        }
        event.accepted = true;
    }
    Keys.onBackPressed: (event) => {
        if (isSearching) {
            clearSearch();
        } else {
            root.backRequested();
        }
        event.accepted = true;
    }

    Keys.onPressed: (event) => {
        if (!isSearching) {
            if ((event.modifiers & Qt.ControlModifier) && (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab)) {
                root.openWallpapersRequested();
                event.accepted = true;
                return;
            }
            if (event.key === Qt.Key_Backspace) {
                if (!event.isAutoRepeat)
                    root.backRequested();
                event.accepted = true;
                return;
            }
            if (event.key === Qt.Key_2) {
                root.openWallpapersRequested();
                event.accepted = true;
                return;
            }

            // Check if user pressed a letter or printable character to initiate search
            const ch = getPrintableChar(event);
            if (ch !== "") {
                startSearchWith(ch);
                event.accepted = true;
                return;
            }
        }
    }

    // Background focus guard: clicking empty area refocuses the appropriate item
    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: {
            if (root.isSearching) {
                searchBar.searchField.forceActiveFocus();
            } else {
                root.forceActiveFocus();
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        // Top Navigation Header
        ThemeStudioHeader {
            Layout.fillWidth: true
            activeStage: "themes"
            infoText: root.isSearching
                ? (root.activeThemesList ? (root.activeThemesList.length + " matching") : "0 matching")
                : (ThemeService.availableThemes ? (ThemeService.availableThemes.length + " themes") : "0 themes")
            onBackRequested: {
                if (root.isSearching) {
                    root.clearSearch();
                } else {
                    root.backRequested();
                }
            }
            onSwitchStageRequested: (stage) => {
                if (stage === "wallpapers")
                    root.openWallpapersRequested();
            }
        }

        // Animated Search Bar
        ThemeSearchBar {
            id: searchBar
            Layout.fillWidth: true
            implicitHeight: root.isSearching ? 36 : 0
            opacity: root.isSearching ? 1.0 : 0.0
            visible: implicitHeight > 0.1 || opacity > 0.01
            clip: true

            Behavior on implicitHeight {
                NumberAnimation {
                    duration: Motion.durationNormal
                    easing.type: Motion.easingStandard
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: Motion.durationNormal
                    easing.type: Motion.easingStandard
                }
            }

            onNavigateLeft: root.moveSelection(-1, 0)
            onNavigateRight: root.moveSelection(1, 0)
            onNavigateUp: root.moveSelection(0, -1)
            onNavigateDown: root.moveSelection(0, 1)
            onActivateCurrent: root.applySelected()
            onEscapePressed: root.clearSearch()
            onCleared: root.clearSearch()
        }

        // Themes Content Area
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Themes Grid View
            GridView {
                id: gridView
                anchors.fill: parent
                topMargin: 2
                bottomMargin: 2
                clip: true
                cellWidth: 266
                cellHeight: 88
                model: root.activeThemesList
                currentIndex: root.selectedIndex
                visible: root.activeThemesList && root.activeThemesList.length > 0

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
                        if (modelData.name !== ThemeService.activeTheme) {
                            ThemeService.switchTheme(modelData.name);
                        }
                    }
                    onDoubleActivated: {
                        root.selectedIndex = index;
                        gridView.positionViewAtIndex(index, GridView.Contain);
                        if (modelData.name !== ThemeService.activeTheme) {
                            ThemeService.switchTheme(modelData.name);
                        }
                        root.openWallpapersRequested();
                    }
                }
            }

            // Empty State
            ThemeSearchEmptyState {
                anchors.fill: parent
                searchQuery: root.searchQuery
                visible: root.isSearching && (!root.activeThemesList || root.activeThemesList.length === 0)
            }
        }
    }

    function syncActiveSelection() {
        const list = root.activeThemesList;
        if (!list || list.length === 0) {
            root.selectedIndex = -1;
            return;
        }
        const activeIdx = list.findIndex(entry => entry.name === ThemeService.activeTheme);
        if (activeIdx >= 0) {
            root.selectedIndex = activeIdx;
            gridView.positionViewAtIndex(activeIdx, GridView.Contain);
        } else {
            root.selectedIndex = Math.max(0, Math.min(list.length - 1, root.selectedIndex >= 0 ? root.selectedIndex : 0));
            gridView.positionViewAtIndex(root.selectedIndex, GridView.Contain);
        }
    }

    Connections {
        target: ThemeService
        function onAvailableThemesChanged() {
            if (root.isSearching) {
                root.updateFilteredThemes();
            } else {
                root.syncActiveSelection();
            }
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
            if (!isSearching) {
                root.syncActiveSelection();
            }
        }
    }
}
