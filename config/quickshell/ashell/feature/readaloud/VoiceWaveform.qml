import QtQuick
import qs
import qs.components
import qs.feature.readaloud

Item {
    id: root

    property bool isPlaying: ReadAloudService.isPlaying
    property real audioLevel: ReadAloudService.audioLevel
    property int barCount: 4
    property real barWidth: 3.0
    property real barSpacing: 2.5
    property real minHeight: 3.5
    property real maxHeight: 18.0

    property color activeColor1: Colors.accent
    property color activeColor2: Colors.accentAlt
    property color inactiveColor: Colors.textDim

    implicitWidth: barCount * barWidth + (barCount - 1) * barSpacing
    implicitHeight: maxHeight
    width: implicitWidth
    height: implicitHeight

    // Continuous smooth voice oscillation driver
    property real wavePhase: 0.0
    NumberAnimation on wavePhase {
        running: root.isPlaying
        from: 0.0
        to: Math.PI * 2
        duration: 800
        loops: Animation.Infinite
    }

    Row {
        anchors.centerIn: parent
        spacing: root.barSpacing
        height: parent.height

        Repeater {
            model: root.barCount

            Rectangle {
                id: bar
                required property int index
                anchors.verticalCenter: parent.verticalCenter
                width: root.barWidth
                radius: width / 2

                // Envelope weighting based on position (center peaks, outer tapers)
                readonly property real centerDist: Math.abs(index - (root.barCount - 1) / 2.0)
                readonly property real weight: Math.max(0.65, 1.35 - (centerDist * 0.35))

                // Organic voice wave modulation
                readonly property real waveOsc: root.isPlaying
                    ? (0.50 + 0.50 * Math.sin(root.wavePhase + index * 1.25))
                    : 0.0

                // Dynamic height calculation: guarantees visible energetic movement even at low volume
                readonly property real activeBoost: Math.max(root.audioLevel, 0.22)
                readonly property real targetHeight: root.isPlaying
                    ? Math.max(root.minHeight, Math.round(root.minHeight + (root.maxHeight - root.minHeight) * activeBoost * weight * (0.60 + 0.40 * waveOsc)))
                    : root.minHeight

                height: targetHeight

                color: {
                    if (!root.isPlaying)
                        return root.inactiveColor;
                    return (index % 2 === 0) ? root.activeColor1 : root.activeColor2;
                }

                Behavior on height {
                    NumberAnimation {
                        duration: Motion.durationInstant
                        easing.type: Motion.easingStandard
                    }
                }

                Behavior on color {
                    ColorAnimation {
                        duration: Motion.durationNormal
                        easing.type: Motion.easingStandard
                    }
                }
            }
        }
    }
}
