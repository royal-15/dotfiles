import QtQuick
import QtQuick.Layouts
import qs
import qs.components

Item {
    id: root

    property int count: 0
    property int totalCount: 0
    property bool isConfirmingDelete: false

    implicitHeight: 28

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 10

        // Counter or Confirmation status
        Text {
            text: {
                if (root.isConfirmingDelete)
                    return "Confirm delete? Press Delete or tap again";
                if (root.totalCount === 0)
                    return "No commands";
                if (root.count !== root.totalCount)
                    return `Showing ${root.count} of ${root.totalCount}`;
                return `${root.count} commands`;
            }
            font.pixelSize: 11
            font.weight: root.isConfirmingDelete ? Font.DemiBold : Font.Normal
            color: root.isConfirmingDelete ? Colors.critical : Colors.textDim
            Layout.alignment: Qt.AlignVCenter

            Behavior on color {
                ColorAnimation {
                    duration: Motion.durationFast
                    easing.type: Motion.easingStandard
                }
            }
        }

        Item { Layout.fillWidth: true }

        // Keyboard Shortcut Hints
        RowLayout {
            spacing: 8
            Layout.alignment: Qt.AlignVCenter

            // Enter key hint: Copy
            Row {
                spacing: 3
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    height: 16
                    width: 18
                    radius: 3
                    color: Colors.surfaceMuted

                    Text {
                        anchors.centerIn: parent
                        text: "↵"
                        font.pixelSize: 10
                        color: Colors.textDim
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Copy"
                    font.pixelSize: 10
                    color: Colors.textFaint
                }
            }

            // Ctrl+Space key hint: Expand
            Row {
                spacing: 3
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    height: 16
                    width: 58
                    radius: 3
                    color: Colors.surfaceMuted

                    Text {
                        anchors.centerIn: parent
                        text: "Ctrl+Space"
                        font.pixelSize: 9
                        font.family: "JetBrainsMono Nerd Font"
                        color: Colors.textDim
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Toggle"
                    font.pixelSize: 10
                    color: Colors.textFaint
                }
            }

            // Ctrl+N key hint: Add
            Row {
                spacing: 3
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    height: 16
                    width: 38
                    radius: 3
                    color: Colors.surfaceMuted

                    Text {
                        anchors.centerIn: parent
                        text: "Ctrl+N"
                        font.pixelSize: 9
                        font.family: "JetBrainsMono Nerd Font"
                        color: Colors.textDim
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Add"
                    font.pixelSize: 10
                    color: Colors.textFaint
                }
            }

            // F2 / Ctrl+E key hint: Edit
            Row {
                spacing: 3
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    height: 16
                    width: editKeyText.implicitWidth + 8
                    radius: 3
                    color: Colors.surfaceMuted

                    Text {
                        id: editKeyText
                        anchors.centerIn: parent
                        text: "F2 / Ctrl+E"
                        font.pixelSize: 9
                        font.family: "JetBrainsMono Nerd Font"
                        color: Colors.textDim
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Edit"
                    font.pixelSize: 10
                    color: Colors.textFaint
                }
            }

            // Escape key hint
            Row {
                spacing: 3
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    height: 16
                    width: 24
                    radius: 3
                    color: Colors.surfaceMuted

                    Text {
                        anchors.centerIn: parent
                        text: "Esc"
                        font.pixelSize: 9
                        color: Colors.textDim
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Close"
                    font.pixelSize: 10
                    color: Colors.textFaint
                }
            }
        }
    }
}
