import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs
import qs.components

ListView {
    id: view

    property var networks: []
    property bool busy: false
    property bool radioEnabled: true
    property bool loaded: false
    property bool searching: false
    property string error: ""
    property bool keyboardFocusActive: false
    property int selectedIndex: -1

    signal networkActivated(int index, var network)
    signal networkForgetRequested(int index, var network)
    signal networkHovered(int index)

    Layout.fillWidth: true
    Layout.fillHeight: true
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    topMargin: 3
    bottomMargin: 3
    spacing: 6
    model: networks

    delegate: Item {
        id: rowItem
        required property var modelData
        required property int index

        readonly property bool isSelected: view.keyboardFocusActive && view.selectedIndex >= 0 && view.selectedIndex === index
        readonly property bool isInUse: modelData.inUse

        width: view.width
        height: 64
        z: rowItem.isSelected ? 5 : (wifiRowMouse.containsMouse ? 2 : 1)

        // Apple Focus Ring Halo for keyboard selection with anti-cropping headroom
        Rectangle {
            anchors.fill: rowSurface
            anchors.margins: -1
            radius: rowSurface.radius + 1
            color: Colors.accentSoft
            scale: rowSurface.scale
            transformOrigin: Item.Center
            opacity: rowItem.isSelected ? 0.65 : 0.0
            visible: opacity > 0.01
            z: -1

            Behavior on opacity {
                NumberAnimation {
                    duration: Motion.durationFast
                    easing.type: Motion.easingStandard
                }
            }
        }

        Rectangle {
            id: rowSurface
            anchors.centerIn: parent
            width: parent.width - 12
            height: 56
            radius: 12

            scale: wifiRowMouse.pressed
                ? Motion.scalePress
                : (rowItem.isSelected || wifiRowMouse.containsMouse)
                    ? Motion.scaleTileHover
                    : Motion.scaleNormal
            transformOrigin: Item.Center

            Behavior on scale {
                NumberAnimation {
                    duration: wifiRowMouse.pressed ? Motion.durationPressDown : Motion.durationPressRelease
                    easing.type: wifiRowMouse.pressed ? Motion.easingPressDown : Motion.easingPressRelease
                }
            }

            color: rowItem.isSelected
                ? Colors.accentSoft
                : (rowItem.isInUse
                    ? Colors.surfaceSoft
                    : (wifiRowMouse.containsMouse ? Colors.surface : Colors.surfaceSoft))

            border.width: rowItem.isSelected ? 1.5 : (rowItem.isInUse ? 1 : (wifiRowMouse.containsMouse ? 1 : 0))
            border.color: rowItem.isSelected ? Colors.accent : (rowItem.isInUse ? Colors.border : Colors.border)

            Behavior on color {
                ColorAnimation {
                    duration: Motion.durationFast
                    easing.type: Motion.easingStandard
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: modelData.savedUuid !== "" ? 44 : 10
                spacing: 10

                Text {
                    text: modelData.inUse
                        ? "wifi"
                        : (modelData.signal < 35 ? "wifi_1_bar" : modelData.signal < 70 ? "wifi_2_bar" : "wifi")
                    color: modelData.inUse
                        ? Colors.accent
                        : wifiRowMouse.containsMouse
                            ? Colors.text
                            : Colors.textDim
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 18

                    Behavior on color {
                        ColorAnimation {
                            duration: Motion.durationFast
                            easing.type: Motion.easingStandard
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: modelData.ssid || "Hidden network"
                        color: Colors.text
                        font.pixelSize: 13
                        font.weight: modelData.inUse ? Font.DemiBold : Font.Normal
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: !modelData.ssid && !modelData.inUse
                            ? "Hidden · SSID not broadcast"
                            : modelData.inUse
                                ? "Connected · " + modelData.signal + "%"
                                : modelData.savedOnly
                                    ? "Saved network"
                                    : modelData.security && modelData.security !== "--"
                                        ? (modelData.savedUuid ? "Saved · available · " : "Available · ") + modelData.signal + "% · secured"
                                        : (modelData.savedUuid ? "Saved · available · " : "Available · ") + modelData.signal + "%"
                        color: modelData.inUse ? Colors.success : Colors.textDim
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        Layout.fillWidth: true

                        Behavior on color {
                            ColorAnimation {
                                duration: Motion.durationFast
                                easing.type: Motion.easingStandard
                            }
                        }
                    }
                }

                Text {
                    text: modelData.inUse ? "check_circle" : modelData.security && modelData.security !== "--" ? "lock" : ""
                    color: modelData.inUse ? Colors.success : Colors.textFaint
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 16

                    Behavior on color {
                        ColorAnimation {
                            duration: Motion.durationFast
                            easing.type: Motion.easingStandard
                        }
                    }
                }
            }

            MouseArea {
                id: wifiRowMouse
                anchors.fill: parent
                hoverEnabled: true
                enabled: !view.busy && view.radioEnabled && (modelData.ssid !== "" || modelData.savedUuid !== "" || modelData.inUse)
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onEntered: {
                    view.networkHovered(index);
                }
                onClicked: {
                    view.networkActivated(index, modelData);
                }
            }

            Rectangle {
                visible: modelData.savedUuid !== ""
                anchors.right: parent.right
                anchors.rightMargin: 9
                anchors.verticalCenter: parent.verticalCenter
                width: 28
                height: 28
                radius: 8
                color: forgetWifiMouse.containsMouse ? Colors.hover : Colors.clear
                scale: forgetWifiMouse.pressed
                    ? Motion.scalePress
                    : (forgetWifiMouse.containsMouse ? Motion.scaleHover : Motion.scaleNormal)
                border.width: 0

                Behavior on scale {
                    NumberAnimation {
                        duration: forgetWifiMouse.pressed ? Motion.durationPressDown : Motion.durationPressRelease
                        easing.type: forgetWifiMouse.pressed ? Motion.easingPressDown : Motion.easingPressRelease
                    }
                }

                Behavior on color {
                    ColorAnimation {
                        duration: Motion.durationFast
                        easing.type: Motion.easingStandard
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: "delete"
                    color: forgetWifiMouse.containsMouse ? Colors.critical : Colors.textDim
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 16

                    Behavior on color {
                        ColorAnimation {
                            duration: Motion.durationFast
                            easing.type: Motion.easingStandard
                        }
                    }
                }

                MouseArea {
                    id: forgetWifiMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: !view.busy
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: view.networkForgetRequested(index, modelData)
                }
            }
        }
    }

    Text {
        anchors.centerIn: parent
        visible: opacity > 0.01
        opacity: view.networks.length === 0 ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: Motion.durationNormal
                easing.type: Motion.easingStandard
            }
        }
        width: parent.width - 36
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        text: !view.loaded
            ? "Loading networks…"
            : view.searching
                ? "Searching for networks…"
                : view.error
                    ? view.error
                    : !view.radioEnabled
                        ? "Wi‑Fi is off\nTurn it on to see nearby networks."
                        : view.busy
                            ? "Updating networks…"
                            : "No networks found\nTry scanning again in a moment."
        color: view.error ? Colors.critical : Colors.textDim
        font.pixelSize: 12
    }
}
