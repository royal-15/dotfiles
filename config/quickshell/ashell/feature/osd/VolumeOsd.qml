import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.components
import qs.feature.osd

Item {
    id: root

    implicitWidth: 320
    implicitHeight: 64

    // Ambient drop shadow
    Rectangle {
        anchors.fill: osdSurface
        anchors.topMargin: 4
        anchors.bottomMargin: -2
        radius: osdSurface.radius
        color: Colors.shadow
        opacity: 0.65
        z: -1
    }

    Rectangle {
        id: osdSurface
        anchors.fill: parent
        radius: Decorations.cornerRadius
        color: Colors.panel
        border.color: Colors.border
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            anchors.topMargin: 10
            anchors.bottomMargin: 12
            spacing: 8

            // Top Row: [Device Icon + Device Name | Volume %]
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    id: iconText
                    text: OsdService.liveDeviceIcon
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 18
                    color: OsdService.liveMuted ? Colors.textDim : Colors.accent
                    verticalAlignment: Text.AlignVCenter
                    scale: 1.0

                    SequentialAnimation {
                        id: iconBounceAnim
                        NumberAnimation {
                            target: iconText
                            property: "scale"
                            to: 1.25
                            duration: Motion.durationFast / 2
                            easing.type: Motion.easingStandard
                        }
                        NumberAnimation {
                            target: iconText
                            property: "scale"
                            to: 1.0
                            duration: Motion.durationFast / 2
                            easing.type: Motion.easingBounce
                        }
                    }
                }

                Connections {
                    target: OsdService
                    function onLiveMutedChanged() {
                        iconBounceAnim.restart();
                    }
                }

                Text {
                    id: deviceLabel
                    text: OsdService.liveDeviceName
                    color: Colors.textDim
                    font.pixelSize: 12
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    id: percentLabel
                    text: OsdService.liveMuted ? "Muted" : `${Math.round(OsdService.liveVolume * 100)}%`
                    color: Colors.text
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    verticalAlignment: Text.AlignVCenter
                }
            }

            // Bottom Row: Slider Track and Animated Level Fill
            Item {
                id: sliderContainer
                Layout.fillWidth: true
                Layout.preferredHeight: osdMouseArea.containsMouse ? 10 : 8

                Behavior on Layout.preferredHeight {
                    NumberAnimation {
                        duration: Motion.durationFast
                        easing.type: Motion.easingStandard
                    }
                }

                Rectangle {
                    id: sliderTrack
                    anchors.fill: parent
                    radius: height / 2
                    color: Colors.surfaceMuted
                    border.width: 0

                    Rectangle {
                        id: sliderFill
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        radius: height / 2
                        width: Math.max(0, Math.min(sliderTrack.width, sliderTrack.width * OsdService.liveVolume))
                        color: OsdService.liveMuted ? Colors.textDim : Colors.accent

                        Behavior on width {
                            enabled: !osdMouseArea.pressed
                            NumberAnimation {
                                duration: Motion.durationFast
                                easing.type: Motion.easingStandard
                            }
                        }
                    }
                }
            }
        }

        // Full interactive mouse area supporting hover, direct 1:1 drag seek, and scroll wheel
        MouseArea {
            id: osdMouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onEntered: OsdService.isHovered = true
            onExited: OsdService.isHovered = false

            onWheel: wheel => {
                OsdService.changeVolume(wheel.angleDelta.y > 0 ? 0.05 : -0.05);
            }

            onPressed: mouse => {
                seekFromMouse(mouse.x);
            }

            onPositionChanged: mouse => {
                if (pressed)
                    seekFromMouse(mouse.x);
            }

            function seekFromMouse(mouseX) {
                const trackX = 16;
                const trackW = root.width - 32;
                if (trackW <= 0)
                    return;
                const ratio = (mouseX - trackX) / trackW;
                OsdService.setVolume(ratio);
            }
        }
    }
}
