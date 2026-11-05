import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.components
import qs.feature.osd

PanelWindow {
    id: root

    property var modelData
    property bool closingWithAnimation: false
    property real animProgress: 0.0

    screen: modelData
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0

    anchors {
        bottom: true
    }

    margins {
        bottom: 60
    }

    implicitWidth: 320
    implicitHeight: 64
    color: Colors.clear
    visible: OsdService.volumeOsdVisible || closingWithAnimation

    mask: Region {
        Region {
            item: volumeOsd
            radius: Decorations.cornerRadius
        }
    }

    Connections {
        target: OsdService
        function onVolumeOsdVisibleChanged() {
            if (OsdService.volumeOsdVisible) {
                root.closingWithAnimation = false;
                slideAnim.stop();
                slideAnim.from = root.animProgress;
                slideAnim.to = 1.0;
                slideAnim.duration = Math.max(60, Math.round(Motion.durationNormal * (1.0 - root.animProgress)));
                slideAnim.easing.type = Motion.easingBounce;
                slideAnim.start();
            } else if (root.visible && !root.closingWithAnimation) {
                root.closingWithAnimation = true;
                slideAnim.stop();
                slideAnim.from = root.animProgress;
                slideAnim.to = 0.0;
                slideAnim.duration = Math.max(60, Math.round(Motion.durationExit * root.animProgress));
                slideAnim.easing.type = Motion.easingIn;
                slideAnim.start();
            }
        }
    }

    NumberAnimation {
        id: slideAnim
        target: root
        property: "animProgress"
        onFinished: {
            if (root.closingWithAnimation) {
                root.closingWithAnimation = false;
            }
        }
    }

    VolumeOsd {
        id: volumeOsd
        anchors.fill: parent
        opacity: root.animProgress
        transform: [
            Scale {
                origin.x: root.width / 2
                origin.y: root.height / 2
                xScale: 0.92 + 0.08 * root.animProgress
                yScale: 0.92 + 0.08 * root.animProgress
            },
            Translate {
                y: Math.round(20 * (1.0 - root.animProgress))
            }
        ]
    }
}
