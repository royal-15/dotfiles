import QtQuick
import QtQuick.Layouts
import qs
import qs.components

Item {
    id: root

    property var itemData: null
    property bool isCurrent: false
    property bool isExpanded: false

    signal clicked()
    signal copyRequested()
    signal editRequested()
    signal deleteRequested()
    signal toggleExpandRequested()

    readonly property var snippetLines: (itemData && itemData.snippet) ? itemData.snippet.split("\n") : []
    readonly property int lineCount: snippetLines.length
    readonly property bool isLongSnippet: lineCount > 3

    implicitWidth: ListView.view ? ListView.view.width : 520
    width: ListView.view ? ListView.view.width : 520
    implicitHeight: delegateSurface.implicitHeight + 6
    height: implicitHeight
    z: root.isCurrent ? 5 : (delegateHover.hovered ? 2 : 1)

    Behavior on height {
        NumberAnimation {
            duration: Motion.durationFast
            easing.type: Motion.easingStandard
        }
    }

    // Focus halo for current command palette item with anti-cropping margin headroom
    Rectangle {
        anchors.fill: delegateSurface
        anchors.margins: -1
        radius: delegateSurface.radius + 1
        color: Colors.accentSoft
        scale: delegateSurface.scale
        transformOrigin: Item.Center
        opacity: root.isCurrent ? 0.65 : 0.0
        visible: opacity > 0.01
        z: -1

        Behavior on opacity {
            NumberAnimation {
                duration: Motion.durationFast
                easing.type: Motion.easingStandard
            }
        }
    }

    Rectangle {
        id: delegateSurface
        anchors.top: parent.top
        anchors.topMargin: 2
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 6
        anchors.rightMargin: 6
        radius: 8
        color: root.isCurrent
            ? Colors.accentSoft
            : (delegateHover.hovered ? Colors.surfaceSoft : Colors.clear)

        border.width: root.isCurrent ? 1 : 0
        border.color: Colors.accent

        scale: tapArea.pressed
            ? Motion.scalePress
            : (root.isCurrent ? Motion.scaleTileHover : Motion.scaleNormal)
        transformOrigin: Item.Center

        Behavior on scale {
            NumberAnimation {
                duration: tapArea.pressed ? Motion.durationPressDown : Motion.durationPressRelease
                easing.type: tapArea.pressed ? Motion.easingPressDown : Motion.easingPressRelease
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

        implicitHeight: contentColumn.implicitHeight + 16
        height: implicitHeight

        ColumnLayout {
            id: contentColumn
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 8
            spacing: 6

            // Header: Optional Label + Action Buttons
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // Terminal / Snippet Icon
                Text {
                    text: "code"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 16
                    color: Colors.accent
                    Layout.alignment: Qt.AlignVCenter
                }

                // Label (if present) or fallback command name
                Text {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    text: (root.itemData && root.itemData.label) ? root.itemData.label : (root.itemData ? root.itemData.snippet.split("\n")[0] : "")
                    font.pixelSize: 12
                    font.weight: root.isCurrent ? Font.Bold : Font.DemiBold
                    color: Colors.text
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                // Collapsible Lines Badge for long snippets
                Rectangle {
                    visible: root.isLongSnippet
                    Layout.preferredHeight: 18
                    Layout.preferredWidth: expandBadgeRow.implicitWidth + 8
                    Layout.alignment: Qt.AlignVCenter
                    radius: 4
                    color: root.isCurrent ? Colors.surfaceMuted : Colors.surfaceSoft

                    RowLayout {
                        id: expandBadgeRow
                        anchors.centerIn: parent
                        spacing: 2

                        Text {
                            text: root.isExpanded ? "collapse" : (root.lineCount + " lines")
                            font.pixelSize: 9
                            font.family: "JetBrainsMono Nerd Font"
                            color: root.isCurrent ? Colors.accent : Colors.textDim
                        }

                        Text {
                            text: root.isExpanded ? "expand_less" : "expand_more"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 12
                            color: root.isCurrent ? Colors.accent : Colors.textDim
                        }
                    }

                    HoverHandler {
                        id: badgeHover
                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        onTapped: root.toggleExpandRequested()
                    }
                }

                // Copy Action Button
                Rectangle {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    Layout.alignment: Qt.AlignVCenter
                    radius: 4
                    color: copyHover.hovered ? Colors.accentSoft : Colors.clear
                    opacity: (delegateHover.hovered || root.isCurrent) ? 1.0 : 0.0

                    Behavior on opacity {
                        NumberAnimation { duration: Motion.durationFast }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "content_copy"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 15
                        color: copyHover.hovered ? Colors.accent : (root.isCurrent ? Colors.text : Colors.textDim)
                    }

                    HoverHandler {
                        id: copyHover
                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        onTapped: root.copyRequested()
                    }
                }

                // Edit Action Button
                Rectangle {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    Layout.alignment: Qt.AlignVCenter
                    radius: 4
                    color: editHover.hovered ? Colors.hover : Colors.clear
                    opacity: (delegateHover.hovered || root.isCurrent) ? 1.0 : 0.0

                    Behavior on opacity {
                        NumberAnimation { duration: Motion.durationFast }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "edit"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 15
                        color: editHover.hovered ? Colors.text : (root.isCurrent ? Colors.text : Colors.textDim)
                    }

                    HoverHandler {
                        id: editHover
                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        onTapped: root.editRequested()
                    }
                }

                // Delete Action Button
                Rectangle {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    Layout.alignment: Qt.AlignVCenter
                    radius: 4
                    color: deleteHover.hovered ? Colors.criticalSoft : Colors.clear
                    opacity: (delegateHover.hovered || root.isCurrent) ? 1.0 : 0.0

                    Behavior on opacity {
                        NumberAnimation { duration: Motion.durationFast }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "delete"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 15
                        color: deleteHover.hovered ? Colors.critical : (root.isCurrent ? Colors.textDim : Colors.textFaint)
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

            // Snippet Code Block Box
            Rectangle {
                Layout.fillWidth: true
                radius: 6
                color: root.isCurrent ? Colors.surfaceMuted : Colors.surfaceSoft
                border.width: 1
                border.color: root.isCurrent ? Colors.accentAlt : Colors.border
                clip: true

                implicitHeight: snippetText.implicitHeight + 12

                Text {
                    id: snippetText
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 6
                    text: root.itemData ? root.itemData.snippet : ""
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                    color: root.isCurrent ? Colors.text : Colors.textDim
                    wrapMode: Text.WrapAnywhere
                    maximumLineCount: (root.isLongSnippet && !root.isExpanded) ? 3 : 100
                    elide: (root.isLongSnippet && !root.isExpanded) ? Text.ElideRight : Text.ElideNone
                }
            }
        }
    }
}
