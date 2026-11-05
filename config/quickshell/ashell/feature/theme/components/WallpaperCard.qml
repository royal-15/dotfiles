import QtQuick
import QtQuick.Layouts
import qs
import qs.components

Rectangle {
    id: root

    property string wallpaperName: ""
    property string wallpaperUrl: ""
    property bool isActive: false
    property bool isHighlighted: false

    signal activated()

    implicitWidth: 220
    implicitHeight: 140
    radius: 12
    color: Colors.surface
    clip: true

    border.width: isActive ? 2 : (isHighlighted ? 1 : 0)
    border.color: isActive ? Colors.accent : Colors.border

    Behavior on border.color {
        ColorAnimation {
            duration: Motion.durationFast
            easing.type: Motion.easingStandard
        }
    }

    // Soft placeholder card displayed while thumbnail loads asynchronously
    Rectangle {
        anchors.fill: parent
        color: Colors.surfaceSoft
        visible: thumbnail.status !== Image.Ready

        Text {
            anchors.centerIn: parent
            text: "image"
            font.family: "Material Symbols Outlined"
            font.pixelSize: 28
            color: Colors.textDim
            opacity: 0.4
        }
    }

    Image {
        id: thumbnail
        anchors.fill: parent
        source: root.wallpaperUrl
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        sourceSize.width: 320
        sourceSize.height: 180
        opacity: root.isHighlighted || root.isActive || mouseArea.containsMouse ? 1.0 : 0.85

        Behavior on opacity {
            NumberAnimation {
                duration: Motion.durationFast
                easing.type: Motion.easingStandard
            }
        }
    }

    // Subtle bottom gradient shadow for label readability
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 38
        gradient: Gradient {
            GradientStop { position: 0.0; color: Colors.clear }
            GradientStop { position: 1.0; color: Colors.shadow }
        }
    }

    // Bottom label row
    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 8
        spacing: 6

        Text {
            text: root.wallpaperName
            color: Colors.text
            font.pixelSize: 11
            font.weight: Font.DemiBold
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        Rectangle {
            visible: root.isActive
            implicitWidth: 14
            implicitHeight: 14
            radius: 7
            color: Colors.accent

            Text {
                anchors.centerIn: parent
                text: "check"
                font.family: "Material Symbols Outlined"
                font.pixelSize: 10
                color: Colors.textAccent
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}
