import QtQuick
import QtQuick.Layouts
import qs
import qs.components

Item {
    id: root

    property string wallpaperName: ""
    property string wallpaperUrl: ""
    property bool isActive: false
    property bool isHighlighted: false
    property int index: 0
    property int totalCount: 0

    signal activated()
    signal selectRequested()
    signal doubleActivated()

    implicitWidth: 260
    implicitHeight: 154

    width: 260
    height: ListView.view ? ListView.view.height : implicitHeight

    z: isHighlighted ? 10 : (mouseArea.containsMouse ? 5 : 1)

    Rectangle {
        id: cardBody
        width: root.implicitWidth
        height: root.implicitHeight
        anchors.centerIn: parent
        radius: 14
        color: Colors.surface
        clip: true

        readonly property real baseScale: root.isHighlighted
            ? 1.04
            : (mouseArea.containsMouse ? 0.92 : 0.86)

        scale: mouseArea.pressed ? (baseScale * Motion.scalePress) : baseScale

        opacity: root.isHighlighted
            ? 1.0
            : (mouseArea.containsMouse ? 0.70 : 0.45)

        border.width: root.isActive ? 2 : (root.isHighlighted ? 1.5 : 0)
        border.color: Colors.accent

        Behavior on scale {
            NumberAnimation {
                duration: mouseArea.pressed ? Motion.durationPressDown : Motion.durationNormal
                easing.type: mouseArea.pressed ? Motion.easingPressDown : Motion.easingFluid
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: Motion.durationNormal
                easing.type: Motion.easingStandard
            }
        }

        Behavior on border.width {
            NumberAnimation {
                duration: Motion.durationFast
                easing.type: Motion.easingStandard
            }
        }

        // Clean placeholder displayed while thumbnail loads asynchronously
        Rectangle {
            anchors.fill: parent
            color: Colors.surfaceSoft
            visible: thumbnail.status !== Image.Ready
        }

        // Wallpaper Thumbnail Image (PreserveAspectCrop with native aspect decode)
        Image {
            id: thumbnail
            anchors.fill: parent
            source: root.wallpaperUrl
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            sourceSize.width: 520
            opacity: status === Image.Ready ? 1.0 : 0.0

            Behavior on opacity {
                NumberAnimation {
                    duration: Motion.durationFast
                    easing.type: Motion.easingStandard
                }
            }
        }

        // Apple Glass Checkmark Badge for Active Wallpaper
        Rectangle {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 10
            implicitWidth: 24
            implicitHeight: 24
            radius: 12
            color: Colors.panel
            border.width: 1
            border.color: Colors.accent
            visible: root.isActive
            z: 10

            // Soft ambient drop shadow for the badge
            Rectangle {
                anchors.fill: parent
                anchors.topMargin: 1
                radius: parent.radius
                color: Colors.shadow
                opacity: 0.5
                z: -1
            }

            Text {
                anchors.centerIn: parent
                text: "check"
                font.family: "Material Symbols Rounded"
                font.pixelSize: 15
                color: Colors.accent
            }
        }

        // Full-card MouseArea for focus or activation
        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (root.isHighlighted) {
                    root.activated();
                } else {
                    root.selectRequested();
                }
            }
            onDoubleClicked: root.doubleActivated()
        }
    }
}
