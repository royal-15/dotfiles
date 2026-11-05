import QtQuick
import QtQuick.Layouts
import qs
import qs.components

Rectangle {
    id: root

    property string themeName: ""
    property var previewColors: null
    property bool isActive: false
    property bool isHighlighted: false

    signal activated()

    implicitWidth: 236
    implicitHeight: 74
    radius: 12

    color: isHighlighted || mouseArea.containsMouse
        ? Colors.surfaceSoft
        : Colors.surface
    border.width: isActive ? 2 : (isHighlighted ? 1 : 0)
    border.color: isActive ? Colors.accent : Colors.border

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
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: root.themeName
                color: root.isActive ? Colors.accent : Colors.text
                font.pixelSize: 13
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Rectangle {
                visible: root.isActive
                implicitWidth: activeLabel.implicitWidth + 10
                implicitHeight: 18
                radius: 9
                color: Colors.accentSoft

                Text {
                    id: activeLabel
                    anchors.centerIn: parent
                    text: "ACTIVE"
                    color: Colors.accent
                    font.pixelSize: 9
                    font.weight: Font.Bold
                }
            }
        }

        // 4 Static Color Preview Balls in a row (zero delegate allocation churn)
        RowLayout {
            spacing: 8
            Layout.alignment: Qt.AlignLeft

            Rectangle {
                implicitWidth: 16
                implicitHeight: 16
                radius: 8
                color: root.previewColors ? root.previewColors.background : Colors.background
                border.width: 1
                border.color: Colors.border
            }

            Rectangle {
                implicitWidth: 16
                implicitHeight: 16
                radius: 8
                color: root.previewColors ? root.previewColors.surfaceSoft : Colors.surfaceSoft
                border.width: 1
                border.color: Colors.border
            }

            Rectangle {
                implicitWidth: 16
                implicitHeight: 16
                radius: 8
                color: root.previewColors ? root.previewColors.accent : Colors.accent
                border.width: 1
                border.color: Colors.border
            }

            Rectangle {
                implicitWidth: 16
                implicitHeight: 16
                radius: 8
                color: root.previewColors ? root.previewColors.accentAlt : Colors.accentAlt
                border.width: 1
                border.color: Colors.border
            }
        }
    }
}
