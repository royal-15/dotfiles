import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs
import qs.components
import qs.feature.media

Item {
    id: root

    implicitWidth: 420
    implicitHeight: 190
    width: implicitWidth
    height: implicitHeight

    signal requestClose()

    property bool isScrubbing: false
    property real scrubSeconds: 0

    readonly property real currentPositionSeconds: isScrubbing ? scrubSeconds : MediaService.currentPosition
    readonly property real totalLengthSeconds: MediaService.trackLength
    readonly property real progressRatio: totalLengthSeconds > 0 ? Math.max(0, Math.min(1, currentPositionSeconds / totalLengthSeconds)) : 0

    RowLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        // Left: Album Art Container
        Item {
            Layout.preferredWidth: 120
            Layout.preferredHeight: 120
            Layout.alignment: Qt.AlignVCenter

            Rectangle {
                id: albumArtFrame
                anchors.fill: parent
                radius: 14
                color: Colors.surfaceSoft
                clip: true

                // Ambient drop shadow for the album art
                Rectangle {
                    anchors.fill: parent
                    radius: 14
                    color: Colors.shadow
                    opacity: 0.3
                    z: -1
                }

                // Fallback Icon
                Text {
                    anchors.centerIn: parent
                    text: "music_note"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 44
                    color: Colors.textDim
                    visible: artImage.status !== Image.Ready
                }

                // Asynchronous Album Art Image
                Image {
                    id: artImage
                    anchors.fill: parent
                    source: MediaService.trackArtUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    visible: status === Image.Ready
                }

                // Subtle border
                Rectangle {
                    anchors.fill: parent
                    radius: 14
                    color: Colors.clear
                    border.width: 1
                    border.color: Colors.border
                }
            }
        }

        // Right: Metadata, Scrubber, Playback Controls
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 8

            // Top Header: Title, Artist, and Close button
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        Layout.fillWidth: true
                        text: MediaService.trackTitle
                        color: Colors.text
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 14
                        font.bold: true
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: MediaService.trackArtist
                        color: Colors.accent
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: MediaService.trackAlbum
                        color: Colors.textFaint
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                        elide: Text.ElideRight
                        visible: text !== ""
                    }
                }

                // Close / Dismiss Button
                Rectangle {
                    Layout.preferredWidth: 26
                    Layout.preferredHeight: 26
                    Layout.alignment: Qt.AlignTop
                    radius: 13
                    color: closeHover.hovered ? Colors.hover : Colors.clear

                    Behavior on color {
                        ColorAnimation {
                            duration: Motion.durationFast
                            easing.type: Motion.easingStandard
                        }
                    }

                    HoverHandler {
                        id: closeHover
                        cursorShape: Qt.PointingHandCursor
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "keyboard_arrow_up"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 18
                        color: closeHover.hovered ? Colors.text : Colors.textDim
                    }

                    TapHandler {
                        onTapped: root.requestClose()
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 4
            }

            // Middle: Seekbar row
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: MediaService.formatTime(root.currentPositionSeconds)
                    color: Colors.textDim
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 10
                    Layout.preferredWidth: 32
                    horizontalAlignment: Text.AlignRight
                }

                // Interactive Scrubber Bar
                Item {
                    id: scrubberContainer
                    Layout.fillWidth: true
                    Layout.preferredHeight: 18

                    HoverHandler {
                        id: scrubberHover
                        cursorShape: Qt.PointingHandCursor
                    }

                    // Track Background
                    Rectangle {
                        id: trackBg
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        height: scrubberHover.hovered || root.isScrubbing ? 5 : 4
                        radius: height / 2
                        color: Colors.surfaceMuted

                        Behavior on height {
                            NumberAnimation {
                                duration: Motion.durationFast
                                easing.type: Motion.easingStandard
                            }
                        }

                        // Filled Progress
                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: Math.max(0, Math.min(parent.width, parent.width * root.progressRatio))
                            radius: parent.radius
                            color: Colors.accent
                        }
                    }

                    // Handle Dot
                    Rectangle {
                        id: scrubHandle
                        x: Math.max(0, Math.min(scrubberContainer.width - width, (scrubberContainer.width * root.progressRatio) - (width / 2)))
                        anchors.verticalCenter: parent.verticalCenter
                        width: scrubberHover.hovered || root.isScrubbing ? 10 : 0
                        height: width
                        radius: width / 2
                        color: Colors.accent
                        opacity: width > 0 ? 1 : 0

                        Behavior on width {
                            NumberAnimation {
                                duration: Motion.durationFast
                                easing.type: Motion.easingStandard
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: MediaService.canSeek

                        function updateScrub(mouse) {
                            if (scrubberContainer.width <= 0 || root.totalLengthSeconds <= 0)
                                return;
                            const ratio = Math.max(0, Math.min(1, mouse.x / scrubberContainer.width));
                            root.scrubSeconds = ratio * root.totalLengthSeconds;
                        }

                        onPressed: mouse => {
                            root.isScrubbing = true;
                            updateScrub(mouse);
                        }

                        onPositionChanged: mouse => {
                            if (root.isScrubbing) {
                                updateScrub(mouse);
                            }
                        }

                        onReleased: mouse => {
                            if (root.isScrubbing) {
                                updateScrub(mouse);
                                MediaService.seekTo(root.scrubSeconds);
                                root.isScrubbing = false;
                            }
                        }

                        onCanceled: {
                            root.isScrubbing = false;
                        }
                    }
                }

                Text {
                    text: MediaService.formatTime(root.totalLengthSeconds)
                    color: Colors.textDim
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 10
                    Layout.preferredWidth: 32
                }
            }

            // Bottom: Controls Row
            MediaControls {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }
}
