import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.components
import qs.feature.notifications

Item {
    id: root

    property bool highlighted: false
    property bool dimmed: false
    signal clicked()

    readonly property bool hasUnread: NotificationService.unreadCount > 0
    readonly property bool dndActive: NotificationService.dndEnabled
    readonly property bool isHovered: mouseDetector.containsMouse
    property bool isPressed: false
    property real badgeScale: 1.0

    function pulseBadge() {
        badgePulseAnimation.stop();
        badgeScale = 1.0;
        badgePulseAnimation.restart();
    }

    SequentialAnimation {
        id: badgePulseAnimation
        NumberAnimation {
            target: root
            property: "badgeScale"
            from: 1.0
            to: 1.35
            duration: Math.round(Motion.durationFast / 2)
            easing.type: Motion.easingStandard
        }
        NumberAnimation {
            target: root
            property: "badgeScale"
            to: 1.0
            duration: Motion.durationNormal
            easing.type: Motion.easingBounce
        }
    }

    readonly property real targetWidth: pillSurface.implicitWidth
    property real animWidth: targetWidth
    Behavior on animWidth {
        NumberAnimation {
            duration: Motion.durationNormal
            easing.type: Motion.easingFluid
        }
    }

    implicitWidth: Math.round(animWidth)
    implicitHeight: Decorations.pillHeight
    Layout.preferredWidth: Math.round(animWidth)
    Layout.preferredHeight: Decorations.pillHeight
    Layout.fillWidth: false
    width: Math.round(animWidth)
    height: implicitHeight

    // Apple-like subtle resting opacity; fully opaque when active, hovered, or with unread notifications
    opacity: root.dimmed
        ? 0.50
        : ((root.highlighted || root.isHovered || root.hasUnread) ? 1.0 : 0.75)

    Behavior on opacity {
        NumberAnimation {
            duration: Motion.durationNormal
            easing.type: Motion.easingStandard
        }
    }

    readonly property real interactionScale: isPressed
        ? Motion.scalePress
        : (isHovered ? Motion.scaleHover : Motion.scaleNormal)
    scale: interactionScale
    transformOrigin: Item.Center

    Behavior on scale {
        NumberAnimation {
            duration: root.isPressed ? Motion.durationPressDown : Motion.durationPressRelease
            easing.type: root.isPressed ? Motion.easingPressDown : Motion.easingPressRelease
        }
    }

    // Ambient drop shadow
    Rectangle {
        anchors.fill: pillSurface
        anchors.margins: root.highlighted ? -2 : 0
        anchors.topMargin: root.highlighted ? -2 : 2
        anchors.bottomMargin: root.highlighted ? -2 : -1
        radius: pillSurface.radius + (root.highlighted ? 2 : 0)
        color: root.highlighted ? Colors.accentSoft : Colors.shadow
        opacity: root.highlighted ? 0.85 : (root.isHovered ? 0.65 : 0.35)
        z: -1

        Behavior on opacity {
            NumberAnimation {
                duration: Motion.durationFast
                easing.type: Motion.easingStandard
            }
        }
    }

    // Capsule Surface
    Rectangle {
        id: pillSurface
        anchors.fill: parent
        readonly property real contentW: contentRow.implicitWidth
        implicitWidth: Math.round(contentW + (root.hasUnread ? 16 : 14))
        implicitHeight: Decorations.pillHeight
        radius: Decorations.cornerRadius
        clip: true

        color: root.highlighted
            ? Colors.accentSoft
            : (root.isHovered && !root.dimmed ? Colors.surfaceSoft : Colors.surface)

        border.color: root.highlighted ? Colors.accent : Colors.border
        border.width: root.highlighted ? 1 : 0

        Behavior on color {
            ColorAnimation {
                duration: Motion.durationFast
                easing.type: Motion.easingStandard
            }
        }

        RowLayout {
            id: contentRow
            anchors.centerIn: parent
            spacing: 5

            Text {
                id: iconGlyph
                text: root.dndActive ? "notifications_off" : "notifications"
                font.family: "Material Symbols Rounded"
                font.pixelSize: 13
                color: root.highlighted
                    ? Colors.accent
                    : (root.dndActive
                        ? Colors.textDim
                        : (root.hasUnread
                            ? Colors.accent
                            : (root.isHovered ? Colors.text : Colors.textDim)))

                Behavior on color {
                    ColorAnimation {
                        duration: Motion.durationFast
                        easing.type: Motion.easingStandard
                    }
                }
            }

            // Apple-caliber micro count chip
            Rectangle {
                id: microBadge
                readonly property real targetBadgeScale: root.hasUnread ? 1.0 : 0.0
                property real animBadgeScale: targetBadgeScale
                Behavior on animBadgeScale {
                    NumberAnimation {
                        duration: Motion.durationFast
                        easing.type: Motion.easingBounce
                    }
                }

                visible: animBadgeScale > 0.01
                implicitHeight: 14
                implicitWidth: Math.max(14, badgeCountText.implicitWidth + 6)
                radius: 7
                color: Colors.accent
                scale: animBadgeScale * root.badgeScale
                transformOrigin: Item.Center

                Text {
                    id: badgeCountText
                    anchors.centerIn: parent
                    text: String(NotificationService.unreadCount)
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 9
                    font.bold: true
                    color: Colors.textAccent
                }
            }
        }
    }

    MouseArea {
        id: mouseDetector
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPressed: root.isPressed = true
        onReleased: root.isPressed = false
        onCanceled: root.isPressed = false
        onClicked: root.clicked()
    }
}
