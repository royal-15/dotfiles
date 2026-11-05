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
    implicitHeight: 180

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
    Keys.onEscapePressed: (event) => { root.closeRequested(); event.accepted = true; }
    Keys.onBackPressed: (event) => { root.closeRequested(); event.accepted = true; }

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Backspace) {
            if (!event.isAutoRepeat)
                root.closeRequested();
            event.accepted = true;
        } else if (event.key === Qt.Key_1 || event.text.toLowerCase() === "t") {
            root.openThemesRequested();
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

        // Header
        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Theme Studio"
                color: Colors.text
                font.pixelSize: 14
                font.weight: Font.Bold
                Layout.fillWidth: true
            }

            Rectangle {
                implicitWidth: escLabel.implicitWidth + 10
                implicitHeight: 20
                radius: 10
                color: Colors.surfaceSoft
                border.width: 1
                border.color: Colors.border

                Text {
                    id: escLabel
                    anchors.centerIn: parent
                    text: "Esc: Close"
                    color: Colors.textDim
                    font.pixelSize: 10
                }
            }
        }

        // Two Cards Row
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            // Themes Card
            Rectangle {
                id: themesCard
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 14
                color: root.selectedIndex === 0 || themesMouse.containsMouse ? Colors.surfaceSoft : Colors.surface
                border.width: root.selectedIndex === 0 ? 2 : 1
                border.color: root.selectedIndex === 0 ? Colors.accent : Colors.border

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

                MouseArea {
                    id: themesMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.selectedIndex = 0;
                        root.openThemesRequested();
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: "palette"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 22
                            color: Colors.accent
                        }

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            implicitWidth: 24
                            implicitHeight: 20
                            radius: 6
                            color: Colors.surfaceMuted
                            border.width: 1
                            border.color: Colors.border

                            Text {
                                anchors.centerIn: parent
                                text: "1"
                                color: Colors.text
                                font.pixelSize: 11
                                font.weight: Font.Bold
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    Text {
                        text: "Themes"
                        color: Colors.text
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                    }

                    Text {
                        text: ThemeService.activeTheme ? ThemeService.activeTheme : "Default"
                        color: Colors.textDim
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
            }

            // Wallpapers Card
            Rectangle {
                id: wallpapersCard
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 14
                color: root.selectedIndex === 1 || wallpapersMouse.containsMouse ? Colors.surfaceSoft : Colors.surface
                border.width: root.selectedIndex === 1 ? 2 : 1
                border.color: root.selectedIndex === 1 ? Colors.accent : Colors.border

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

                MouseArea {
                    id: wallpapersMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.selectedIndex = 1;
                        root.openWallpapersRequested();
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: "wallpaper"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 22
                            color: Colors.accentAlt
                        }

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            implicitWidth: 24
                            implicitHeight: 20
                            radius: 6
                            color: Colors.surfaceMuted
                            border.width: 1
                            border.color: Colors.border

                            Text {
                                anchors.centerIn: parent
                                text: "2"
                                color: Colors.text
                                font.pixelSize: 11
                                font.weight: Font.Bold
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    Text {
                        text: "Wallpapers"
                        color: Colors.text
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                    }

                    Text {
                        text: ThemeService.activeWallpaper ? ThemeService.activeWallpaper : "None"
                        color: Colors.textDim
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
            }
        }
    }
}
