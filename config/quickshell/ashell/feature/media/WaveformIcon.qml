import QtQuick
import QtQuick.Layouts
import qs
import qs.components

Item {
    id: root

    property bool isPlaying: false
    property color activeColor1: Colors.accent
    property color activeColor2: Colors.accentAlt
    property color inactiveColor: Colors.textDim

    implicitWidth: 18
    implicitHeight: 14
    width: implicitWidth
    height: implicitHeight

    readonly property var restHeights: [4, 11, 7, 5]

    Row {
        anchors.centerIn: parent
        spacing: 2
        height: root.height

        // Bar 1
        Rectangle {
            id: bar1
            width: 2.5
            height: root.restHeights[0]
            radius: width / 2
            anchors.bottom: parent.bottom
            color: root.isPlaying ? root.activeColor1 : root.inactiveColor

            Behavior on color {
                ColorAnimation {
                    duration: Motion.durationNormal
                    easing.type: Motion.easingStandard
                }
            }

            SequentialAnimation on height {
                running: root.isPlaying
                loops: Animation.Infinite
                NumberAnimation { to: 12; duration: 320; easing.type: Motion.easingInOut }
                NumberAnimation { to: 3; duration: 280; easing.type: Motion.easingInOut }
                NumberAnimation { to: 8; duration: 240; easing.type: Motion.easingInOut }
                NumberAnimation { to: root.restHeights[0]; duration: 300; easing.type: Motion.easingStandard }
            }

            Behavior on height {
                enabled: !root.isPlaying
                NumberAnimation {
                    duration: Motion.durationNormal
                    easing.type: Motion.easingStandard
                }
            }
        }

        // Bar 2
        Rectangle {
            id: bar2
            width: 2.5
            height: root.restHeights[1]
            radius: width / 2
            anchors.bottom: parent.bottom
            color: root.isPlaying ? root.activeColor2 : root.inactiveColor

            Behavior on color {
                ColorAnimation {
                    duration: Motion.durationNormal
                    easing.type: Motion.easingStandard
                }
            }

            SequentialAnimation on height {
                running: root.isPlaying
                loops: Animation.Infinite
                NumberAnimation { to: 4; duration: 250; easing.type: Motion.easingInOut }
                NumberAnimation { to: 13; duration: 350; easing.type: Motion.easingInOut }
                NumberAnimation { to: 6; duration: 220; easing.type: Motion.easingInOut }
                NumberAnimation { to: root.restHeights[1]; duration: 280; easing.type: Motion.easingStandard }
            }

            Behavior on height {
                enabled: !root.isPlaying
                NumberAnimation {
                    duration: Motion.durationNormal
                    easing.type: Motion.easingStandard
                }
            }
        }

        // Bar 3
        Rectangle {
            id: bar3
            width: 2.5
            height: root.restHeights[2]
            radius: width / 2
            anchors.bottom: parent.bottom
            color: root.isPlaying ? root.activeColor1 : root.inactiveColor

            Behavior on color {
                ColorAnimation {
                    duration: Motion.durationNormal
                    easing.type: Motion.easingStandard
                }
            }

            SequentialAnimation on height {
                running: root.isPlaying
                loops: Animation.Infinite
                NumberAnimation { to: 11; duration: 290; easing.type: Motion.easingInOut }
                NumberAnimation { to: 4; duration: 230; easing.type: Motion.easingInOut }
                NumberAnimation { to: 13; duration: 320; easing.type: Motion.easingInOut }
                NumberAnimation { to: root.restHeights[2]; duration: 260; easing.type: Motion.easingStandard }
            }

            Behavior on height {
                enabled: !root.isPlaying
                NumberAnimation {
                    duration: Motion.durationNormal
                    easing.type: Motion.easingStandard
                }
            }
        }

        // Bar 4
        Rectangle {
            id: bar4
            width: 2.5
            height: root.restHeights[3]
            radius: width / 2
            anchors.bottom: parent.bottom
            color: root.isPlaying ? root.activeColor2 : root.inactiveColor

            Behavior on color {
                ColorAnimation {
                    duration: Motion.durationNormal
                    easing.type: Motion.easingStandard
                }
            }

            SequentialAnimation on height {
                running: root.isPlaying
                loops: Animation.Infinite
                NumberAnimation { to: 5; duration: 270; easing.type: Motion.easingInOut }
                NumberAnimation { to: 12; duration: 330; easing.type: Motion.easingInOut }
                NumberAnimation { to: 3; duration: 210; easing.type: Motion.easingInOut }
                NumberAnimation { to: root.restHeights[3]; duration: 290; easing.type: Motion.easingStandard }
            }

            Behavior on height {
                enabled: !root.isPlaying
                NumberAnimation {
                    duration: Motion.durationNormal
                    easing.type: Motion.easingStandard
                }
            }
        }
    }
}
