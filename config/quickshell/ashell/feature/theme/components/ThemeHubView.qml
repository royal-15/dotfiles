import QtQuick
import QtQuick.Layouts
import qs
import qs.components
import qs.feature.theme

FocusScope {
    id: root

    property int selectedIndex: 0 // 0 = Themes, 1 = Wallpapers

    signal openThemesRequested()
    signal openWallpapersRequested()
    signal closeRequested()

    implicitWidth: 420
    implicitHeight: 190

    function drillDown() {
        if (selectedIndex === 0)
            root.openThemesRequested();
        else
            root.openWallpapersRequested();
    }

    Keys.onLeftPressed: (event) => { selectedIndex = 0; event.accepted = true; }
    Keys.onRightPressed: (event) => { selectedIndex = 1; event.accepted = true; }
    Keys.onTabPressed: (event) => { selectedIndex = (selectedIndex + 1) % 2; event.accepted = true; }
    Keys.onBacktabPressed: (event) => { selectedIndex = (selectedIndex + 1) % 2; event.accepted = true; }
    Keys.onReturnPressed: (event) => { drillDown(); event.accepted = true; }
    Keys.onEnterPressed: (event) => { drillDown(); event.accepted = true; }
    Keys.onSpacePressed: (event) => { drillDown(); event.accepted = true; }
    Keys.onEscapePressed: (event) => { root.closeRequested(); event.accepted = true; }
    Keys.onBackPressed: (event) => { root.closeRequested(); event.accepted = true; }

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Backspace) {
            if (!event.isAutoRepeat)
                root.closeRequested();
            event.accepted = true;
        } else if (event.key === Qt.Key_1 || event.text.toLowerCase() === "t") {
            root.selectedIndex = 0;
            root.openThemesRequested();
            event.accepted = true;
        } else if (event.key === Qt.Key_2 || event.text.toLowerCase() === "w") {
            root.selectedIndex = 1;
            root.openWallpapersRequested();
            event.accepted = true;
        } else if (event.key === Qt.Key_H) {
            selectedIndex = 0;
            event.accepted = true;
        } else if (event.key === Qt.Key_L) {
            selectedIndex = 1;
            event.accepted = true;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 14

        // Minimal Header Row: Title on left, subtle hint on right
        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Theme Studio"
                color: Colors.text
                font.pixelSize: 13
                font.weight: Font.DemiBold
                Layout.fillWidth: true
            }

            Text {
                text: "Esc to dismiss"
                color: Colors.textDim
                font.pixelSize: 11
                font.weight: Font.Normal
            }
        }

        // Two Elevated Action Cards
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 14

            // 1. Themes Card
            ThemeHubCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                title: "Themes"
                subtitle: ThemeService.activeTheme ? ThemeService.activeTheme : "Default"
                isSelected: root.selectedIndex === 0
                onClicked: {
                    root.selectedIndex = 0;
                    root.openThemesRequested();
                }

                Rectangle {
                    implicitWidth: 44
                    implicitHeight: 6
                    radius: 3
                    color: Colors.clear
                    clip: true

                    RowLayout {
                        anchors.fill: parent
                        spacing: 1

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: Colors.background
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: Colors.surfaceSoft
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: Colors.accent
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: Colors.accentAlt
                        }
                    }
                }
            }

            // 2. Wallpapers Card
            ThemeHubCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                title: "Wallpapers"
                subtitle: ThemeService.activeWallpaper ? ThemeService.activeWallpaper : "None"
                isSelected: root.selectedIndex === 1
                onClicked: {
                    root.selectedIndex = 1;
                    root.openWallpapersRequested();
                }

                Text {
                    text: (ThemeService.availableWallpapers ? ThemeService.availableWallpapers.length : 0) + " items"
                    color: Colors.textDim
                    font.pixelSize: 11
                    font.weight: Font.Normal
                }
            }
        }
    }
}
