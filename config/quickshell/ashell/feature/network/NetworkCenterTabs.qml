import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs
import qs.components

Rectangle {
    id: root

    property string activeTab: "wifi" // "wifi" or "bluetooth"
    signal tabSelected(string tab)

    readonly property int activeIndex: activeTab === "bluetooth" ? 1 : 0
    readonly property real margin: 4
    readonly property real spacing: 6
    readonly property real availableWidth: Math.max(0, width - (margin * 2))
    readonly property real tabWidth: Math.max(0, (availableWidth - spacing) / 2)

    Layout.fillWidth: true
    implicitHeight: 44
    radius: 14
    color: Colors.surface
    border.width: 0

    // Ambient glow halo underlying the sliding capsule
    Rectangle {
        anchors.fill: slidingCapsule
        anchors.margins: -1
        radius: slidingCapsule.radius + 1
        color: Colors.accentSoft
        opacity: 0.55
        z: 1

        Behavior on x {
            NumberAnimation {
                duration: Motion.durationNormal
                easing.type: Motion.easingFluid
            }
        }
        Behavior on width {
            NumberAnimation {
                duration: Motion.durationNormal
                easing.type: Motion.easingFluid
            }
        }
    }

    // Single physical sliding capsule gliding behind the active tab
    Rectangle {
        id: slidingCapsule
        y: root.margin
        x: root.margin + (root.activeIndex * (root.tabWidth + root.spacing))
        width: root.tabWidth
        height: root.height - (root.margin * 2)
        radius: 11
        color: Colors.accentSoft
        border.width: 1
        border.color: Colors.accent
        z: 2

        Behavior on x {
            NumberAnimation {
                duration: Motion.durationNormal
                easing.type: Motion.easingFluid
            }
        }
        Behavior on width {
            NumberAnimation {
                duration: Motion.durationNormal
                easing.type: Motion.easingFluid
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: root.margin
        spacing: root.spacing
        z: 3

        Repeater {
            model: [
                { key: "wifi", label: "Wi‑Fi", icon: "wifi" },
                { key: "bluetooth", label: "Bluetooth", icon: "bluetooth" }
            ]

            delegate: Item {
                id: tabItem
                required property var modelData
                required property int index

                readonly property bool isActive: root.activeTab === modelData.key

                Layout.fillWidth: true
                Layout.fillHeight: true

                scale: tabMouse.pressed
                    ? Motion.scalePress
                    : (tabMouse.containsMouse && !tabItem.isActive)
                        ? Motion.scaleTileHover
                        : Motion.scaleNormal
                transformOrigin: Item.Center

                Behavior on scale {
                    NumberAnimation {
                        duration: tabMouse.pressed ? Motion.durationPressDown : Motion.durationPressRelease
                        easing.type: tabMouse.pressed ? Motion.easingPressDown : Motion.easingPressRelease
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 11
                    border.width: 0
                    color: (tabMouse.containsMouse && !tabItem.isActive)
                        ? Colors.hover
                        : Colors.clear

                    Behavior on color {
                        ColorAnimation {
                            duration: Motion.durationFast
                            easing.type: Motion.easingStandard
                        }
                    }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 7

                        Text {
                            text: modelData.icon
                            color: tabItem.isActive
                                ? Colors.accent
                                : tabMouse.containsMouse
                                    ? Colors.text
                                    : Colors.textDim
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 16

                            Behavior on color {
                                ColorAnimation {
                                    duration: Motion.durationFast
                                    easing.type: Motion.easingStandard
                                }
                            }
                        }

                        Text {
                            text: modelData.label
                            color: tabItem.isActive
                                ? Colors.text
                                : tabMouse.containsMouse
                                    ? Colors.text
                                    : Colors.textDim
                            font.pixelSize: 13
                            font.weight: tabItem.isActive ? Font.DemiBold : Font.Medium

                            Behavior on color {
                                ColorAnimation {
                                    duration: Motion.durationFast
                                    easing.type: Motion.easingStandard
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: tabMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.tabSelected(modelData.key)
                    }
                }
            }
        }
    }
}
