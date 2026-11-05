import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.components
import qs.feature.notifications

Item {
    id: root

    property int count: 0
    signal clearAllRequested()

    implicitWidth: 320
    implicitHeight: 40

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 8

        Text {
            text: "Notifications"
            font.pixelSize: 14
            font.weight: Font.Bold
            color: Colors.text
            verticalAlignment: Text.AlignVCenter
        }

        // Count badge
        Item {
            implicitWidth: countText.implicitWidth + 12
            implicitHeight: 18
            visible: root.count > 0

            Rectangle {
                anchors.fill: parent
                radius: 9
                color: Colors.surfaceMuted
            }

            Text {
                id: countText
                anchors.centerIn: parent
                text: String(root.count)
                font.pixelSize: 10
                font.weight: Font.DemiBold
                color: Colors.textDim
            }
        }

        Item {
            Layout.fillWidth: true
        }

        // Do Not Disturb Toggle Button
        Item {
            implicitWidth: 30
            implicitHeight: 26

            Rectangle {
                anchors.fill: parent
                radius: 13
                color: NotificationService.dndEnabled
                    ? Colors.accentSoft
                    : (dndMouse.containsMouse ? Colors.hover : Colors.clear)

                Behavior on color {
                    ColorAnimation {
                        duration: Motion.durationFast
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                text: NotificationService.dndEnabled ? "notifications_off" : "notifications"
                font.family: "Material Symbols Outlined"
                font.pixelSize: 16
                color: NotificationService.dndEnabled ? Colors.accent : (dndMouse.containsMouse ? Colors.text : Colors.textDim)
            }

            MouseArea {
                id: dndMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: NotificationService.toggleDnd()
            }
        }

        // Clear All Button
        Item {
            implicitWidth: clearText.implicitWidth + 14
            implicitHeight: 26
            visible: root.count > 0

            Rectangle {
                anchors.fill: parent
                radius: 13
                color: clearMouse.containsMouse ? Colors.hover : Colors.clear

                Behavior on color {
                    ColorAnimation {
                        duration: Motion.durationFast
                    }
                }
            }

            Text {
                id: clearText
                anchors.centerIn: parent
                text: "Clear All"
                font.pixelSize: 11
                font.weight: Font.Medium
                color: clearMouse.containsMouse ? Colors.accent : Colors.textDim
            }

            MouseArea {
                id: clearMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.clearAllRequested()
            }
        }
    }
}
