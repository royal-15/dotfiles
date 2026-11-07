import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.components

Item {
    id: root

    property string icon: ""
    property string label: ""
    property color iconColor: Colors.text
    property bool iconGradient: false
    property color iconGradientStart: Colors.accent
    property color iconGradientEnd: Colors.accentAlt
    property color textColor: Colors.text
    property int maxLabelWidth: 200
    property bool isVisible: true
    property bool highlighted: false
    property bool interactive: false
    property bool forceIconOnly: false
    property bool dimmed: false
    property bool isPressed: false
    readonly property bool isHovered: interactive && mouseDetector.containsMouse
    property real badgeScale: 1.0

    // Lifecycle transition progress (0.0 = collapsed/hidden, 1.0 = fully expanded)
    property real openProgress: isVisible ? 1.0 : 0.0
    Behavior on openProgress {
        NumberAnimation {
            duration: Motion.durationNormal
            easing.type: Motion.easingStandard
        }
    }

    // Label expand/collapse transition tracking
    property string lastNonEmptyLabel: ""
    onLabelChanged: {
        if (root.label !== "") {
            lastNonEmptyLabel = root.label;
        }
    }

    readonly property real targetLabelWidth: (!root.forceIconOnly && root.label !== "")
        ? Math.min(labelText.implicitWidth, root.maxLabelWidth)
        : 0
    property real animLabelWidth: targetLabelWidth
    property real animLabelOpacity: (!root.forceIconOnly && root.label !== "") ? 1.0 : 0.0

    Behavior on animLabelWidth {
        NumberAnimation {
            duration: Motion.durationNormal
            easing.type: Motion.easingStandard
        }
    }

    Behavior on animLabelOpacity {
        NumberAnimation {
            duration: Motion.durationFast
            easing.type: Motion.easingStandard
        }
    }

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

    signal clicked()
    signal wheel(var wheel)

    readonly property real targetSurfaceWidth: pillSurface.implicitWidth
    readonly property real currentWidth: Math.round(targetSurfaceWidth * openProgress)

    implicitWidth: currentWidth
    implicitHeight: Decorations.pillHeight
    Layout.preferredWidth: currentWidth
    Layout.preferredHeight: Decorations.pillHeight
    Layout.fillWidth: false
    Layout.rightMargin: (parent && parent.spacing !== undefined)
        ? -Math.round(parent.spacing * (1.0 - openProgress))
        : 0
    width: currentWidth
    height: implicitHeight
    visible: root.isVisible || openProgress > 0.005
    opacity: openProgress * (root.dimmed ? 0.55 : 1.0)
    clip: openProgress < 0.99 || animLabelWidth < (targetLabelWidth - 0.5)

    Behavior on opacity {
        NumberAnimation {
            duration: Motion.durationNormal
            easing.type: Motion.easingStandard
        }
    }

    readonly property real interactionScale: (interactive && isPressed) ? Motion.scalePress : (interactive && isHovered) ? Motion.scaleHover : Motion.scaleNormal
    scale: interactionScale * (0.88 + 0.12 * openProgress)
    transformOrigin: Item.Center

    Behavior on scale {
        NumberAnimation {
            duration: (root.interactive && root.isPressed) ? Motion.durationPressDown : Motion.durationPressRelease
            easing.type: (root.interactive && root.isPressed) ? Motion.easingPressDown : Motion.easingPressRelease
        }
    }

    // Multi-layer ambient drop shadow and Apple-caliber focus ring halo
    Rectangle {
        anchors.fill: pillSurface
        anchors.margins: root.highlighted ? -2 : 0
        anchors.topMargin: root.highlighted ? -2 : 2
        anchors.bottomMargin: root.highlighted ? -2 : -1
        radius: pillSurface.radius + (root.highlighted ? 2 : 0)
        color: root.highlighted ? Colors.accentSoft : Colors.shadow
        opacity: (root.highlighted ? 0.90 : (root.interactive && root.isHovered) ? 0.75 : 0.40) * root.openProgress
        z: -1

        Behavior on opacity {
            NumberAnimation {
                duration: Motion.durationFast
                easing.type: Motion.easingStandard
            }
        }

        Behavior on color {
            ColorAnimation {
                duration: Motion.durationFast
                easing.type: Motion.easingStandard
            }
        }
    }

    Rectangle {
        id: pillSurface

        anchors.centerIn: parent
        readonly property real iconPartWidth: (root.icon !== "") ? iconItem.implicitWidth : 0
        readonly property real labelPartWidth: (root.animLabelWidth > 0.5) ? ((iconPartWidth > 0 ? 7 : 0) + root.animLabelWidth) : 0
        implicitWidth: Math.round(iconPartWidth + labelPartWidth + 22)
        implicitHeight: Decorations.pillHeight
        radius: Decorations.cornerRadius

        color: root.highlighted
            ? Colors.accentSoft
            : (root.interactive && root.isHovered && !root.dimmed)
                ? Colors.surfaceSoft
                : Colors.surface

        border.color: root.highlighted ? Colors.accent : Colors.border
        border.width: root.highlighted ? 1 : 0

        Behavior on border.color {
            ColorAnimation {
                duration: Motion.durationFast
                easing.type: Motion.easingStandard
            }
        }

        Behavior on color {
            ColorAnimation {
                duration: Motion.durationFast
                easing.type: Motion.easingStandard
            }
        }

        RowLayout {
            id: row

            anchors.centerIn: parent
            spacing: (root.icon !== "" && root.animLabelWidth > 0.5) ? 7 : 0

            Item {
                id: iconItem
                implicitWidth: iconGlyph.implicitWidth
                implicitHeight: iconGlyph.implicitHeight
                visible: root.icon !== ""

                Text {
                    id: iconGlyph
                    text: root.icon
                    color: root.dimmed ? Colors.textDim : (root.iconGradient ? Colors.accentAlt : root.iconColor)
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 13

                    Behavior on color {
                        ColorAnimation {
                            duration: Motion.durationFast
                            easing.type: Motion.easingStandard
                        }
                    }
                }
            }

            Flickable {
                id: labelFlickable

                property bool overflowing: labelText.implicitWidth > root.maxLabelWidth

                Layout.maximumWidth: root.maxLabelWidth
                Layout.preferredWidth: Math.round(root.animLabelWidth)
                implicitHeight: labelText.implicitHeight + 2
                clip: true
                opacity: root.animLabelOpacity
                contentWidth: labelText.implicitWidth
                contentHeight: height
                interactive: false
                visible: root.label !== "" || root.animLabelWidth > 0.5

                onVisibleChanged: {
                    if (!visible)
                        contentX = 0;
                }
                onOverflowingChanged: {
                    if (!overflowing)
                        contentX = 0;
                }

                Text {
                    id: labelText

                    text: root.label !== "" ? root.label : root.lastNonEmptyLabel
                    color: root.dimmed ? Colors.textDim : root.textColor
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                    anchors.verticalCenter: parent.verticalCenter
                    scale: root.badgeScale
                    transformOrigin: Item.Center

                    Behavior on color {
                        ColorAnimation {
                            duration: Motion.durationFast
                            easing.type: Motion.easingStandard
                        }
                    }
                }

                SequentialAnimation {
                    id: marqueeAnimation

                    running: labelFlickable.visible && labelFlickable.overflowing && root.animLabelOpacity > 0.95
                    loops: Animation.Infinite

                    PauseAnimation {
                        duration: 4000
                    }

                    NumberAnimation {
                        target: labelFlickable
                        property: "contentX"
                        from: 0
                        to: Math.max(0, labelText.implicitWidth - labelFlickable.width)
                        duration: Math.max(1500, (labelText.implicitWidth - labelFlickable.width) * 32)
                        easing.type: Easing.Linear
                    }

                    PauseAnimation {
                        duration: 1200
                    }

                    NumberAnimation {
                        target: labelFlickable
                        property: "contentX"
                        to: 0
                        duration: Math.max(1500, (labelText.implicitWidth - labelFlickable.width) * 32)
                        easing.type: Easing.Linear
                    }
                }
            }
        }
    }

    // Mouse area for hover, press, click and wheel
    MouseArea {
        id: mouseDetector
        anchors.fill: parent
        enabled: root.interactive && root.isVisible && root.openProgress > 0.5
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPressed: root.isPressed = true
        onReleased: root.isPressed = false
        onCanceled: root.isPressed = false
        onClicked: root.clicked()
        onWheel: wheel => {
            root.isPressed = true;
            wheelPressResetTimer.restart();
            root.wheel(wheel);
        }
    }

    Timer {
        id: wheelPressResetTimer
        interval: 100
        repeat: false
        onTriggered: root.isPressed = false
    }
}
