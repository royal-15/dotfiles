import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs
import qs.components

PanelWindow {
    id: root

    property var modelData: null
    screen: modelData

    // Dynamic Dodge support: dodge right sidebar -> bottom-left; dodge left sidebar -> bottom-right
    property bool rightSidebarOpen: false
    property bool leftSidebarOpen: false
    property alias sidebarOpen: root.rightSidebarOpen

    readonly property bool isLeftPositioned: rightSidebarOpen && !leftSidebarOpen
    readonly property real rightX: (root.width > capsuleContainer.width + 16)
        ? (root.width - capsuleContainer.width - 8)
        : 0
    readonly property real leftX: 8
    readonly property real targetX: isLeftPositioned ? leftX : rightX

    // Lifecycle & Public API
    readonly property bool isOpen: visible && !closingWithAnimation
    property bool closingWithAnimation: false
    property int autoDismissMs: 0
    property real entryProgress: 0.0

    // Content slot
    default property alias content: contentHost.data
    readonly property alias contentItem: contentHost

    signal dismissed()

    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0

    anchors {
        bottom: true
        left: true
        right: true
    }

    margins {
        bottom: Decorations.screenEdgePadding + 10
        left: Decorations.screenEdgePadding
        right: Decorations.screenEdgePadding
    }

    implicitHeight: capsuleContainer.height + 24
    color: Colors.clear
    visible: false

    mask: Region {
        Region {
            item: capsuleSurface
            radius: Decorations.cornerRadius
        }
    }

    function show() {
        if (dismissTimer.running)
            dismissTimer.stop();

        closingWithAnimation = false;
        visible = true;

        entryAnim.stop();
        entryAnim.from = root.entryProgress;
        entryAnim.to = 1.0;
        entryAnim.duration = Math.max(60, Math.round(Motion.durationNormal * (1.0 - root.entryProgress)));
        entryAnim.easing.type = Motion.easingStandard;
        entryAnim.start();

        if (root.autoDismissMs > 0) {
            dismissTimer.interval = root.autoDismissMs;
            dismissTimer.restart();
        }
    }

    function dismiss() {
        if (!visible || closingWithAnimation)
            return;

        if (dismissTimer.running)
            dismissTimer.stop();

        closingWithAnimation = true;
        entryAnim.stop();
        entryAnim.from = root.entryProgress;
        entryAnim.to = 0.0;
        entryAnim.duration = Math.max(60, Math.round(Motion.durationExit * root.entryProgress));
        entryAnim.easing.type = Motion.easingIn;
        entryAnim.start();
    }

    function closeImmediate() {
        if (dismissTimer.running)
            dismissTimer.stop();

        entryAnim.stop();
        closingWithAnimation = false;
        entryProgress = 0.0;
        visible = false;
        dismissed();
    }

    NumberAnimation {
        id: entryAnim
        target: root
        property: "entryProgress"
        onFinished: {
            if (root.closingWithAnimation) {
                root.visible = false;
                root.closingWithAnimation = false;
                root.dismissed();
            }
        }
    }

    Timer {
        id: dismissTimer
        repeat: false
        onTriggered: root.dismiss()
    }

    // Unified motion container holding capsule & ambient shadows in lockstep
    Item {
        id: capsuleContainer
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 8
        x: root.targetX
        width: Math.max(180, contentHost.implicitWidth + 28)
        height: Math.max(40, contentHost.implicitHeight + 14)

        Behavior on x {
            enabled: root.visible && root.width > capsuleContainer.width + 16
            NumberAnimation {
                duration: Motion.durationSlow
                easing.type: Motion.easingFluid
            }
        }

        opacity: root.entryProgress
        transform: [
            Scale {
                origin.x: capsuleContainer.width / 2
                origin.y: capsuleContainer.height / 2
                xScale: 0.92 + 0.08 * root.entryProgress
                yScale: 0.92 + 0.08 * root.entryProgress
            },
            Translate {
                y: Math.round(16 * (1.0 - root.entryProgress))
            }
        ]

        // Layer 1 Ambient drop shadow
        Rectangle {
            anchors.fill: parent
            anchors.margins: -2
            anchors.topMargin: 5
            anchors.bottomMargin: -3
            radius: capsuleSurface.radius + 2
            color: Colors.shadowTip
            opacity: 0.35
            z: -2
        }

        // Layer 2 Ambient drop shadow
        Rectangle {
            anchors.fill: parent
            anchors.topMargin: 2
            anchors.bottomMargin: -1
            radius: capsuleSurface.radius
            color: Colors.shadow
            opacity: 0.50
            z: -1
        }

        // Outer visual capsule
        Rectangle {
            id: capsuleSurface
            anchors.fill: parent
            radius: Decorations.cornerRadius
            color: Colors.panel
            border.color: Colors.border
            border.width: 1

            Item {
                id: contentHost
                anchors.centerIn: parent
                width: childrenRect.width
                height: childrenRect.height
                implicitWidth: childrenRect.width
                implicitHeight: childrenRect.height
            }
        }
    }
}
