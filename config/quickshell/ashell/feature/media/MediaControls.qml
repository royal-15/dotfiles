import QtQuick
import QtQuick.Layouts
import qs
import qs.components
import qs.feature.media

RowLayout {
    id: root

    spacing: 12

    Item { Layout.fillWidth: true }

    // Shuffle Button
    Rectangle {
        Layout.preferredWidth: 30
        Layout.preferredHeight: 30
        radius: 15
        color: shuffleHover.hovered ? Colors.hover : Colors.clear
        scale: shufflePress.pressed
            ? Motion.scalePress
            : (shuffleHover.hovered ? Motion.scaleHover : Motion.scaleNormal)
        transformOrigin: Item.Center

        Behavior on scale {
            NumberAnimation {
                duration: shufflePress.pressed ? Motion.durationPressDown : Motion.durationPressRelease
                easing.type: shufflePress.pressed ? Motion.easingPressDown : Motion.easingPressRelease
            }
        }

        HoverHandler {
            id: shuffleHover
            cursorShape: Qt.PointingHandCursor
        }

        Text {
            anchors.centerIn: parent
            text: "shuffle"
            font.family: "Material Symbols Rounded"
            font.pixelSize: 18
            color: MediaService.shuffle ? Colors.accent : (shuffleHover.hovered ? Colors.text : Colors.textDim)
        }

        TapHandler {
            id: shufflePress
            onTapped: MediaService.toggleShuffle()
        }
    }

    // Previous Track Button
    Rectangle {
        Layout.preferredWidth: 32
        Layout.preferredHeight: 32
        radius: 16
        color: prevHover.hovered && MediaService.canGoPrevious ? Colors.hover : Colors.clear
        scale: prevPress.pressed
            ? Motion.scalePress
            : (prevHover.hovered && MediaService.canGoPrevious ? Motion.scaleHover : Motion.scaleNormal)
        transformOrigin: Item.Center

        Behavior on scale {
            NumberAnimation {
                duration: prevPress.pressed ? Motion.durationPressDown : Motion.durationPressRelease
                easing.type: prevPress.pressed ? Motion.easingPressDown : Motion.easingPressRelease
            }
        }

        HoverHandler {
            id: prevHover
            cursorShape: MediaService.canGoPrevious ? Qt.PointingHandCursor : Qt.ArrowCursor
        }

        Text {
            anchors.centerIn: parent
            text: "skip_previous"
            font.family: "Material Symbols Rounded"
            font.pixelSize: 22
            color: MediaService.canGoPrevious ? (prevHover.hovered ? Colors.text : Colors.textDim) : Colors.textFaint
        }

        TapHandler {
            id: prevPress
            enabled: MediaService.canGoPrevious
            onTapped: MediaService.previous()
        }
    }

    // Play / Pause Prominent Capsule Button
    Item {
        Layout.preferredWidth: 40
        Layout.preferredHeight: 40

        // Soft ambient glow halo
        Rectangle {
            anchors.fill: playPauseBtn
            anchors.margins: -1
            radius: 21
            color: Colors.accentSoft
            opacity: playPauseHover.hovered ? 0.85 : 0.40
            scale: playPauseBtn.scale
            z: -1

            Behavior on opacity {
                NumberAnimation {
                    duration: Motion.durationFast
                    easing.type: Motion.easingStandard
                }
            }
        }

        Rectangle {
            id: playPauseBtn
            anchors.fill: parent
            radius: 20
            color: Colors.accent
            scale: playPausePress.pressed
                ? Motion.scalePress
                : (playPauseHover.hovered ? Motion.scaleHover : Motion.scaleNormal)
            transformOrigin: Item.Center

            Behavior on scale {
                NumberAnimation {
                    duration: playPausePress.pressed ? Motion.durationPressDown : Motion.durationPressRelease
                    easing.type: playPausePress.pressed ? Motion.easingPressDown : Motion.easingPressRelease
                }
            }

            HoverHandler {
                id: playPauseHover
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                id: playPausePress
                onTapped: MediaService.togglePlaying()
            }

            Text {
                anchors.centerIn: parent
                text: MediaService.isPlaying ? "pause" : "play_arrow"
                font.family: "Material Symbols Rounded"
                font.pixelSize: 22
                color: Colors.textAccent
            }
        }
    }

    // Next Track Button
    Rectangle {
        Layout.preferredWidth: 32
        Layout.preferredHeight: 32
        radius: 16
        color: nextHover.hovered && MediaService.canGoNext ? Colors.hover : Colors.clear
        scale: nextPress.pressed
            ? Motion.scalePress
            : (nextHover.hovered && MediaService.canGoNext ? Motion.scaleHover : Motion.scaleNormal)
        transformOrigin: Item.Center

        Behavior on scale {
            NumberAnimation {
                duration: nextPress.pressed ? Motion.durationPressDown : Motion.durationPressRelease
                easing.type: nextPress.pressed ? Motion.easingPressDown : Motion.easingPressRelease
            }
        }

        HoverHandler {
            id: nextHover
            cursorShape: MediaService.canGoNext ? Qt.PointingHandCursor : Qt.ArrowCursor
        }

        Text {
            anchors.centerIn: parent
            text: "skip_next"
            font.family: "Material Symbols Rounded"
            font.pixelSize: 22
            color: MediaService.canGoNext ? (nextHover.hovered ? Colors.text : Colors.textDim) : Colors.textFaint
        }

        TapHandler {
            id: nextPress
            enabled: MediaService.canGoNext
            onTapped: MediaService.next()
        }
    }

    Item { Layout.fillWidth: true }
}
