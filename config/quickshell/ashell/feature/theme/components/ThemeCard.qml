import QtQuick
import QtQuick.Layouts
import qs
import qs.components

Item {
    id: root

    property string themeName: ""
    property var previewColors: null
    property bool isActive: false
    property bool isHighlighted: false

    signal activated()
    signal doubleActivated()

    implicitWidth: 264
    implicitHeight: 88
    width: GridView.view ? GridView.view.cellWidth : implicitWidth
    height: GridView.view ? GridView.view.cellHeight : implicitHeight

    z: isHighlighted ? 10 : (mouseArea.containsMouse ? 5 : 1)

    // Ambient Drop Shadow on Elevation
    Rectangle {
        anchors.fill: cardBody
        anchors.topMargin: 2
        anchors.bottomMargin: -2
        radius: 12
        color: Colors.shadow
        scale: cardBody.scale
        transformOrigin: Item.Center
        opacity: root.isHighlighted ? 0.40 : (mouseArea.containsMouse ? 0.20 : 0.0)
        visible: opacity > 0.01
        z: -2

        Behavior on scale {
            NumberAnimation {
                duration: mouseArea.pressed ? Motion.durationPressDown : Motion.durationPressRelease
                easing.type: mouseArea.pressed ? Motion.easingPressDown : Motion.easingPressRelease
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: Motion.durationFast
                easing.type: Motion.easingStandard
            }
        }
    }

    // Ambient Focus Halo on Keyboard/Hover Highlight
    Rectangle {
        anchors.fill: cardBody
        anchors.margins: -1
        radius: cardBody.radius + 1
        color: Colors.accentSoft
        scale: cardBody.scale
        transformOrigin: Item.Center
        opacity: root.isHighlighted ? 0.65 : 0.0
        visible: opacity > 0.01
        z: -1

        Behavior on scale {
            NumberAnimation {
                duration: mouseArea.pressed ? Motion.durationPressDown : Motion.durationPressRelease
                easing.type: mouseArea.pressed ? Motion.easingPressDown : Motion.easingPressRelease
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: Motion.durationFast
                easing.type: Motion.easingStandard
            }
        }
    }

    Rectangle {
        id: cardBody
        anchors.fill: parent
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        anchors.topMargin: 4
        anchors.bottomMargin: 4
        radius: 12

        color: root.isHighlighted || mouseArea.containsMouse
            ? Colors.surfaceSoft
            : Colors.surface

        border.width: root.isHighlighted ? 1.5 : (root.isActive ? 1 : 1)
        border.color: root.isHighlighted
            ? Colors.accent
            : (root.isActive ? Colors.accent : Colors.border)

        scale: mouseArea.pressed
            ? Motion.scalePress
            : (root.isHighlighted
                ? Motion.scaleHover
                : (mouseArea.containsMouse ? Motion.scaleTileHover : Motion.scaleNormal))
        transformOrigin: Item.Center

        Behavior on scale {
            NumberAnimation {
                duration: mouseArea.pressed ? Motion.durationPressDown : Motion.durationPressRelease
                easing.type: mouseArea.pressed ? Motion.easingPressDown : Motion.easingPressRelease
            }
        }

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
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.activated()
            onDoubleClicked: root.doubleActivated()
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 0

            // Top Row: Theme Name + Prominent Active Checkmark Badge
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: root.themeName
                    color: root.isActive ? Colors.accent : Colors.text
                    font.pixelSize: 13
                    font.weight: root.isActive ? Font.DemiBold : Font.Medium
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                // Apple Glass Checkmark Badge for Active Theme
                Rectangle {
                    visible: root.isActive
                    implicitWidth: 18
                    implicitHeight: 18
                    radius: 9
                    color: Colors.accentSoft
                    border.width: 1
                    border.color: Colors.accent

                    Text {
                        anchors.centerIn: parent
                        text: "check"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 12
                        color: Colors.accent
                    }
                }
            }

            Item { Layout.fillHeight: true }

            // Bottom Row: Seamless Continuous 4-Color Palette Strip
            RowLayout {
                Layout.fillWidth: true

                Rectangle {
                    implicitWidth: 110
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
                            color: root.previewColors ? root.previewColors.background : Colors.background
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: root.previewColors ? root.previewColors.surfaceSoft : Colors.surfaceSoft
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: root.previewColors ? root.previewColors.accent : Colors.accent
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: root.previewColors ? root.previewColors.accentAlt : Colors.accentAlt
                        }
                    }
                }

                Item { Layout.fillWidth: true }
            }
        }
    }
}
