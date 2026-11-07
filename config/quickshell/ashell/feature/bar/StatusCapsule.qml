import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.components

Item {
    id: root

    property bool networkActive: false
    property bool powerActive: false
    property bool dimmed: false

    signal wifiClicked()
    signal powerClicked()

    // ─── Transient Network Feedback State ─────────────────────────────────────
    property bool feedbackActive: false
    property string feedbackIcon: ""
    property string feedbackText: ""
    property string lastFeedbackText: ""
    property int remainingFeedbackMs: 0

    onFeedbackTextChanged: {
        if (feedbackText !== "")
            lastFeedbackText = feedbackText;
    }

    readonly property real targetFeedbackWidth: root.feedbackActive ? (feedbackLabel.implicitWidth + 4) : 0
    property real animFeedbackWidth: targetFeedbackWidth
    Behavior on animFeedbackWidth {
        NumberAnimation {
            duration: Motion.durationNormal
            easing.type: Motion.easingFluid
        }
    }

    property real animFeedbackOpacity: root.feedbackActive ? 1.0 : 0.0
    Behavior on animFeedbackOpacity {
        NumberAnimation {
            duration: Motion.durationFast
            easing.type: Motion.easingStandard
        }
    }

    function triggerNetworkFeedback(icon, text) {
        if (!text || text === "")
            return;

        // Deduplicate identical active feedback
        if (feedbackActive && feedbackText === text && feedbackIcon === icon)
            return;

        feedbackIcon = icon;
        feedbackText = text;

        if (feedbackActive) {
            // Rapid update: crossfade in-place and extend duration by 2s (max 6s)
            feedbackCrossfadeAnim.restart();
            remainingFeedbackMs = Math.min(6000, remainingFeedbackMs + 2000);
        } else {
            // Cold start: open smoothly and start 3s countdown
            feedbackActive = true;
            remainingFeedbackMs = 3000;
            feedbackTimer.restart();
        }
    }

    Timer {
        id: feedbackTimer
        interval: 100
        repeat: true
        running: root.feedbackActive
        onTriggered: {
            root.remainingFeedbackMs -= 100;
            if (root.remainingFeedbackMs <= 0) {
                root.feedbackActive = false;
                stop();
            }
        }
    }

    SequentialAnimation {
        id: feedbackCrossfadeAnim
        NumberAnimation {
            target: feedbackContentGroup
            property: "opacity"
            to: 0.2
            duration: Math.round(Motion.durationFast / 2)
            easing.type: Motion.easingStandard
        }
        NumberAnimation {
            target: feedbackContentGroup
            property: "opacity"
            to: 1.0
            duration: Math.round(Motion.durationFast / 2)
            easing.type: Motion.easingStandard
        }
    }

    Connections {
        target: StatusBarService
        function onNetworkStatusEvent(icon, label) {
            root.triggerNetworkFeedback(icon, label);
        }
    }

    // ─── Battery Percentage Animation State ──────────────────────────────────
    readonly property bool showPct: !StatusBarService.isAcConnected && StatusBarService.batteryPercent !== "" && StatusBarService.hasBattery
    property string lastNonEmptyPct: ""

    onShowPctChanged: {
        if (StatusBarService.batteryPercent !== "")
            lastNonEmptyPct = StatusBarService.batteryPercent;
    }

    readonly property real targetPctWidth: showPct ? (batteryPctText.implicitWidth + 3) : 0
    property real animPctWidth: targetPctWidth
    Behavior on animPctWidth {
        NumberAnimation {
            duration: Motion.durationNormal
            easing.type: Motion.easingFluid
        }
    }

    property real animPctOpacity: showPct ? 1.0 : 0.0
    Behavior on animPctOpacity {
        NumberAnimation {
            duration: Motion.durationFast
            easing.type: Motion.easingStandard
        }
    }

    // ─── Geometry & Dimensions ────────────────────────────────────────────────
    readonly property real targetCapsuleWidth: Math.round(capsuleRow.implicitWidth + 8)
    implicitWidth: targetCapsuleWidth
    implicitHeight: Decorations.pillHeight
    Layout.preferredWidth: targetCapsuleWidth
    Layout.preferredHeight: Decorations.pillHeight
    Layout.fillWidth: false
    width: targetCapsuleWidth
    height: implicitHeight

    opacity: root.dimmed ? 0.55 : 1.0
    Behavior on opacity {
        NumberAnimation {
            duration: Motion.durationNormal
            easing.type: Motion.easingStandard
        }
    }

    // Multi-layer ambient drop shadow
    Rectangle {
        anchors.fill: capsuleSurface
        anchors.topMargin: 2
        anchors.bottomMargin: -1
        radius: capsuleSurface.radius
        color: Colors.shadow
        opacity: 0.38
        z: -1
    }

    // Unified Outer Translucent Capsule
    Rectangle {
        id: capsuleSurface
        anchors.fill: parent
        radius: Decorations.cornerRadius
        color: Colors.surface
        border.width: 0
        clip: true

        RowLayout {
            id: capsuleRow
            anchors.centerIn: parent
            spacing: 2

            // ─── Segment 1: Network Representative ───────────────────────────
            Item {
                id: networkSegment
                implicitHeight: Decorations.pillHeight - 4
                implicitWidth: Math.round(networkSegmentRow.implicitWidth + 12)
                Layout.preferredHeight: implicitHeight
                Layout.preferredWidth: implicitWidth
                Layout.alignment: Qt.AlignVCenter

                Rectangle {
                    id: networkSegmentHighlight
                    anchors.fill: parent
                    radius: Decorations.cornerRadius - 2
                    color: root.networkActive
                        ? Colors.accentSoft
                        : (networkMouse.containsMouse ? Colors.surfaceSoft : Colors.clear)
                    border.width: root.networkActive ? 1 : 0
                    border.color: Colors.accent

                    Behavior on color {
                        ColorAnimation {
                            duration: Motion.durationFast
                            easing.type: Motion.easingStandard
                        }
                    }
                }

                RowLayout {
                    id: networkSegmentRow
                    anchors.centerIn: parent
                    spacing: (root.animFeedbackWidth > 0.5) ? 5 : 0

                    Text {
                        id: networkGlyph
                        text: root.feedbackActive ? root.feedbackIcon : StatusBarService.wifiIcon()
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 13
                        color: root.networkActive
                            ? Colors.accent
                            : (networkMouse.containsMouse
                                ? Colors.text
                                : (StatusBarService.wifiConnected ? Colors.text : Colors.textDim))

                        Behavior on color {
                            ColorAnimation {
                                duration: Motion.durationFast
                                easing.type: Motion.easingStandard
                            }
                        }
                    }

                    // Transient feedback label with fluid width animation
                    Item {
                        id: feedbackContentGroup
                        Layout.preferredWidth: Math.round(root.animFeedbackWidth)
                        implicitWidth: Math.round(root.animFeedbackWidth)
                        Layout.preferredHeight: feedbackLabel.implicitHeight
                        implicitHeight: feedbackLabel.implicitHeight
                        width: Math.round(root.animFeedbackWidth)
                        height: feedbackLabel.implicitHeight
                        clip: true
                        visible: root.animFeedbackWidth > 0.5
                        opacity: root.animFeedbackOpacity

                        Text {
                            id: feedbackLabel
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.feedbackActive ? root.feedbackText : root.lastFeedbackText
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 12
                            color: root.networkActive ? Colors.accent : Colors.text
                        }
                    }
                }

                MouseArea {
                    id: networkMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.feedbackActive) {
                            root.feedbackActive = false;
                            feedbackTimer.stop();
                        }
                        root.wifiClicked();
                    }
                }
            }

            // ─── Hairline Divider ────────────────────────────────────────────
            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: 1
                implicitHeight: 11
                color: Colors.border
                opacity: 0.42
            }

            // ─── Segment 2: Battery Representative ───────────────────────────
            Item {
                id: batterySegment
                implicitHeight: Decorations.pillHeight - 4
                implicitWidth: Math.round(batterySegmentRow.implicitWidth + 12)
                Layout.preferredHeight: implicitHeight
                Layout.preferredWidth: implicitWidth
                Layout.alignment: Qt.AlignVCenter

                Rectangle {
                    id: batterySegmentHighlight
                    anchors.fill: parent
                    radius: Decorations.cornerRadius - 2
                    color: root.powerActive
                        ? Colors.accentSoft
                        : (batteryMouse.containsMouse ? Colors.surfaceSoft : Colors.clear)
                    border.width: root.powerActive ? 1 : 0
                    border.color: Colors.accent

                    Behavior on color {
                        ColorAnimation {
                            duration: Motion.durationFast
                            easing.type: Motion.easingStandard
                        }
                    }
                }

                RowLayout {
                    id: batterySegmentRow
                    anchors.centerIn: parent
                    spacing: (root.animPctWidth > 0.5) ? 4 : 0

                    Text {
                        id: batteryGlyph
                        text: StatusBarService.batteryIcon()
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 13
                        color: root.powerActive
                            ? Colors.accent
                            : (batteryMouse.containsMouse ? Colors.text : StatusBarService.batteryColor())

                        Behavior on color {
                            ColorAnimation {
                                duration: Motion.durationFast
                                easing.type: Motion.easingStandard
                            }
                        }
                    }

                    // Percentage label (smoothly collapses when connected to AC)
                    Item {
                        id: batteryPctContainer
                        Layout.preferredWidth: Math.round(root.animPctWidth)
                        implicitWidth: Math.round(root.animPctWidth)
                        Layout.preferredHeight: batteryPctText.implicitHeight
                        implicitHeight: batteryPctText.implicitHeight
                        width: Math.round(root.animPctWidth)
                        height: batteryPctText.implicitHeight
                        clip: true
                        visible: root.animPctWidth > 0.5
                        opacity: root.animPctOpacity

                        Text {
                            id: batteryPctText
                            anchors.verticalCenter: parent.verticalCenter
                            text: (StatusBarService.batteryPercent !== "" ? StatusBarService.batteryPercent : root.lastNonEmptyPct) + "%"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 12
                            color: root.powerActive ? Colors.accent : Colors.text
                        }
                    }
                }

                MouseArea {
                    id: batteryMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.powerClicked()
                }
            }
        }
    }
}
