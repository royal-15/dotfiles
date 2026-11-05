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
            onTapped: MediaService.toggleShuffle()
        }
    }

    // Previous Track Button
    Rectangle {
        Layout.preferredWidth: 32
        Layout.preferredHeight: 32
        radius: 16
        color: prevHover.hovered && MediaService.canGoPrevious ? Colors.hover : Colors.clear

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
            enabled: MediaService.canGoPrevious
            onTapped: MediaService.previous()
        }
    }

    // Play / Pause Prominent Capsule Button
    Rectangle {
        id: playPauseBtn
        Layout.preferredWidth: 40
        Layout.preferredHeight: 40
        radius: 20
        color: Colors.accent
        scale: playPauseHover.hovered ? (playPausePress.pressed ? Motion.scalePress : Motion.scaleHover) : Motion.scaleNormal

        Behavior on scale {
            NumberAnimation {
                duration: Motion.durationFast
                easing.type: Motion.easingStandard
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

    // Next Track Button
    Rectangle {
        Layout.preferredWidth: 32
        Layout.preferredHeight: 32
        radius: 16
        color: nextHover.hovered && MediaService.canGoNext ? Colors.hover : Colors.clear

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
            enabled: MediaService.canGoNext
            onTapped: MediaService.next()
        }
    }

    Item { Layout.fillWidth: true }
}
