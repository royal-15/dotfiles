import QtQuick
import QtQuick.Layouts
import qs
import qs.components
import qs.feature.readaloud

Item {
    id: root

    implicitWidth: mainRow.implicitWidth
    implicitHeight: 28
    width: implicitWidth
    height: implicitHeight

    RowLayout {
        id: mainRow
        anchors.fill: parent
        spacing: 10

        // TTS Leading Icon
        Text {
            id: ttsIcon
            text: "record_voice_over"
            font.family: "Material Symbols Outlined"
            font.pixelSize: 18
            color: ReadAloudService.isPlaying ? Colors.accent : Colors.textDim
            verticalAlignment: Text.AlignVCenter

            Behavior on color {
                ColorAnimation {
                    duration: Motion.durationNormal
                    easing.type: Motion.easingStandard
                }
            }
        }

        // Voice Input / Audio Recording Waveform (Center-expanding voice capsules)
        VoiceWaveform {
            id: voiceWaveform
            barCount: 5
            barWidth: 3.5
            barSpacing: 3.0
            maxHeight: 20.0
            minHeight: 3.5
            Layout.alignment: Qt.AlignVCenter
        }

        // Status Label
        Text {
            id: statusLabel
            text: {
                if (ReadAloudService.lastError !== "") {
                    if (ReadAloudService.lastError === "no_selection")
                        return "No selection";
                    return "Speech error";
                }
                return ReadAloudService.isPlaying ? "Reading" : "Idle";
            }
            font.pixelSize: 12
            font.weight: Font.Medium
            color: ReadAloudService.lastError !== "" ? Colors.warning : Colors.text
            verticalAlignment: Text.AlignVCenter
            Layout.fillWidth: false
        }

        // Trailing Stop/Dismiss Button
        Rectangle {
            id: stopBtn
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
            Layout.alignment: Qt.AlignVCenter
            radius: 12
            color: stopHover.hovered ? Colors.criticalSoft : Colors.surfaceMuted
            scale: stopTap.pressed ? Motion.scalePress : (stopHover.hovered ? Motion.scaleHover : Motion.scaleNormal)

            Behavior on scale {
                NumberAnimation {
                    duration: Motion.durationInstant
                    easing.type: Motion.easingPress
                }
            }

            Behavior on color {
                ColorAnimation {
                    duration: Motion.durationFast
                    easing.type: Motion.easingStandard
                }
            }

            HoverHandler {
                id: stopHover
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                id: stopTap
                onTapped: ReadAloudService.stop()
            }

            Text {
                anchors.centerIn: parent
                text: "close"
                font.family: "Material Symbols Outlined"
                font.pixelSize: 14
                color: stopHover.hovered ? Colors.critical : Colors.textDim
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter

                Behavior on color {
                    ColorAnimation {
                        duration: Motion.durationFast
                        easing.type: Motion.easingStandard
                    }
                }
            }
        }
    }
}
