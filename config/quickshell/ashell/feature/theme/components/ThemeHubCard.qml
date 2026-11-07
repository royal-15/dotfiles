import QtQuick
import QtQuick.Layouts
import qs
import qs.components

Item {
    id: root

    property string title: ""
    property string subtitle: ""
    property bool isSelected: false

    default property alias contentData: customContent.data

    signal clicked()

    implicitWidth: 190
    implicitHeight: 120
    z: isSelected ? 5 : 1

    // Ambient Drop Shadow on Elevation
    Rectangle {
        anchors.fill: cardBody
        anchors.topMargin: 2
        anchors.bottomMargin: -2
        radius: 14
        color: Colors.shadow
        scale: cardBody.scale
        transformOrigin: Item.Center
        opacity: root.isSelected ? 0.35 : (mouseArea.containsMouse ? 0.20 : 0.0)
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

    // Apple Focus Ring Halo on Hub Card selection
    Rectangle {
        anchors.fill: cardBody
        anchors.margins: -1
        radius: cardBody.radius + 1
        color: Colors.accentSoft
        scale: cardBody.scale
        transformOrigin: Item.Center
        opacity: root.isSelected ? 0.65 : 0.0
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
        radius: 14
        color: root.isSelected || mouseArea.containsMouse ? Colors.surfaceSoft : Colors.surface
        border.width: root.isSelected ? 1.5 : 1
        border.color: root.isSelected ? Colors.accent : Colors.border
        scale: mouseArea.pressed
            ? Motion.scalePress
            : (root.isSelected
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
            onClicked: root.clicked()
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 0

            Text {
                text: root.title
                color: root.isSelected ? Colors.accent : Colors.text
                font.pixelSize: 15
                font.weight: Font.DemiBold
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: root.subtitle
                    color: Colors.textDim
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Item {
                    id: customContent
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    implicitWidth: childrenRect.width
                    implicitHeight: childrenRect.height
                }
            }
        }
    }
}
