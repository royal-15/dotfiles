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
    readonly property real margin: 3
    readonly property real spacing: 4
    readonly property real availableWidth: Math.max(0, width - (margin * 2))
    readonly property real tabWidth: Math.max(0, (availableWidth - spacing) / 2)

    Layout.fillWidth: true
    implicitHeight: 34
    radius: 10
    color: Colors.surfaceMuted
    border.width: 0

    // Single physical sliding capsule gliding behind the active tab (Apple Control Center style)
    Rectangle {
        id: slidingCapsule
        y: root.margin
        x: root.margin + (root.activeIndex * (root.tabWidth + root.spacing))
        width: root.tabWidth
        height: root.height - (root.margin * 2)
        radius: 8
        color: Colors.surfaceSoft
        border.width: 1
        border.color: Colors.border
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

                Rectangle {
                    anchors.fill: parent
                    radius: 8
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
                        spacing: 6

                        Text {
                            text: modelData.icon
                            color: tabItem.isActive
                                ? Colors.accent
                                : tabMouse.containsMouse
                                    ? Colors.text
                                    : Colors.textDim
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 15

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
                            font.pixelSize: 12
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
