import QtQuick
import QtQuick.Layouts
import qs
import qs.components

Item {
    id: root

    property int count: 0
    property int totalCount: 0

    implicitHeight: 28

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 12

        // Counter
        Text {
            text: {
                if (root.totalCount === 0)
                    return "History empty";
                if (root.count !== root.totalCount)
                    return `Showing ${root.count} of ${root.totalCount} items`;
                return `${root.count} items`;
            }
            font.pixelSize: 11
            color: Colors.textDim
            Layout.alignment: Qt.AlignVCenter
        }

        Item { Layout.fillWidth: true }

        // Keyboard Shortcut Hints
        RowLayout {
            spacing: 8
            Layout.alignment: Qt.AlignVCenter

            // Enter key hint
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

            // Delete key hint
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
                        text: "Del"
                        font.pixelSize: 9
                        color: Colors.textDim
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Remove"
                    font.pixelSize: 10
                    color: Colors.textFaint
                }
            }

            // Wipe history hint
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
                        text: "Ctrl+⇧+Del"
                        font.pixelSize: 8
                        color: Colors.textDim
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Wipe"
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
