import QtQuick
import QtQuick.Layouts
import qs
import qs.components

Item {
    id: root

    property var itemData: null
    property bool isCurrent: false

    signal clicked()
    signal deleteRequested()

    implicitWidth: ListView.view ? ListView.view.width : 500
    implicitHeight: 44
    height: 44

    Rectangle {
        id: delegateSurface
        anchors.fill: parent
        anchors.leftMargin: 2
        anchors.rightMargin: 2
        radius: 8
        color: root.isCurrent
            ? Colors.selectedBackground
            : (delegateHover.hovered ? Colors.surfaceSoft : Colors.clear)

        scale: tapArea.pressed ? Motion.scalePress : Motion.scaleNormal

        Behavior on scale {
            NumberAnimation {
                duration: Motion.durationFast
                easing.type: Motion.easingPress
            }
        }

        Behavior on color {
            ColorAnimation {
                duration: Motion.durationInstant
                easing.type: Motion.easingStandard
            }
        }

        HoverHandler {
            id: delegateHover
            cursorShape: Qt.PointingHandCursor
        }

        TapHandler {
            id: tapArea
            onTapped: root.clicked()
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 8
            spacing: 10

            // Sequence / ID Badge
            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 22
                Layout.alignment: Qt.AlignVCenter
                radius: 4
                color: root.isCurrent
                    ? Colors.accentSoft
                    : Colors.surfaceMuted

                Text {
                    anchors.centerIn: parent
                    text: root.itemData ? String(root.itemData.id) : ""
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    color: root.isCurrent ? Colors.accent : Colors.textDim
                }
            }

            // Preview Text and Icon
            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 6

                Text {
                    visible: root.itemData ? root.itemData.isBinary : false
                    text: "image"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 16
                    color: root.isCurrent ? Colors.selectedText : Colors.accentAlt
                    Layout.alignment: Qt.AlignVCenter
                }

                Text {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    text: {
                        if (!root.itemData)
                            return "";
                        if (root.itemData.isBinary)
                            return "Binary / Image Content";
                        return root.itemData.preview;
                    }
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 12
                    color: root.isCurrent ? Colors.selectedText : Colors.text
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
            }

            // Binary badge if applicable
            Rectangle {
                visible: root.itemData ? root.itemData.isBinary : false
                Layout.preferredHeight: 18
                Layout.preferredWidth: 44
                Layout.alignment: Qt.AlignVCenter
                radius: 3
                color: Colors.accentAltSoft

                Text {
                    anchors.centerIn: parent
                    text: "IMAGE"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    color: Colors.textDim
                }
            }

            // Delete item button
            Item {
                Layout.preferredWidth: 26
                Layout.preferredHeight: 26
                Layout.alignment: Qt.AlignVCenter
                opacity: (delegateHover.hovered || root.isCurrent) ? 1.0 : 0.0

                Behavior on opacity {
                    NumberAnimation {
                        duration: Motion.durationFast
                        easing.type: Motion.easingStandard
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 6
                    color: deleteHover.hovered ? Colors.criticalSoft : Colors.clear

                    Text {
                        anchors.centerIn: parent
                        text: "delete"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 16
                        color: deleteHover.hovered ? Colors.critical : (root.isCurrent ? Colors.selectedText : Colors.textDim)
                    }

                    HoverHandler {
                        id: deleteHover
                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        onTapped: root.deleteRequested()
                    }
                }
            }
        }
    }
}
