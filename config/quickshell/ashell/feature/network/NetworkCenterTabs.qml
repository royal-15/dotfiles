import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs
import qs.components

Rectangle {
    id: root

    property string activeTab: "wifi"
    signal tabSelected(string tab)

    Layout.fillWidth: true
    implicitHeight: 44
    radius: 14
    color: Colors.surface
    border.width: 0

    RowLayout {
        anchors.fill: parent
        anchors.margins: 4
        spacing: 6

        Repeater {
            model: [
                { key: "wifi", label: "Wi‑Fi", icon: "wifi" },
                { key: "bluetooth", label: "Bluetooth", icon: "bluetooth" }
            ]

            delegate: Item {
                id: tabItem
                required property var modelData

                readonly property bool isActive: root.activeTab === modelData.key

                Layout.fillWidth: true
                Layout.fillHeight: true

                scale: tabMouse.pressed
                    ? Motion.scalePress
                    : tabMouse.containsMouse
                        ? Motion.scaleTileHover
                        : Motion.scaleNormal
                transformOrigin: Item.Center

                Behavior on scale {
                    NumberAnimation {
                        duration: Motion.durationFast
                        easing.type: Motion.easingStandard
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 11
                    border.width: 0

                    color: tabItem.isActive
                        ? Colors.accentSoft
                        : tabMouse.containsMouse
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
