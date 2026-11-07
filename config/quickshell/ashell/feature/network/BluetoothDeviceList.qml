import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs
import qs.components

ListView {
    id: view

    property var devicesModel
    property int deviceCount: 0
    property bool busy: false
    property bool radioEnabled: true
    property bool loaded: false
    property bool searching: false
    property string error: ""
    property bool keyboardFocusActive: false
    property int selectedIndex: -1

    signal deviceAction(int index, string action, string address, string name)
    signal deviceForgetRequested(int index, string address, string name)
    signal deviceHovered(int index)

    Layout.fillWidth: true
    Layout.fillHeight: true
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    topMargin: 3
    bottomMargin: 3
    spacing: 6
    model: devicesModel

    delegate: Item {
        id: btRowItem
        required property string address
        required property string name
        required property bool nearby
        required property bool connected
        required property int battery
        required property int index

        readonly property bool isSelected: view.keyboardFocusActive && view.selectedIndex >= 0 && view.selectedIndex === index

        width: view.width
        height: 64
        z: btRowItem.isSelected ? 5 : (btRowMouse.containsMouse ? 2 : 1)

        // Apple Focus Ring Halo for keyboard selection with anti-cropping headroom
        Rectangle {
            anchors.fill: btRowSurface
            anchors.margins: -1
            radius: btRowSurface.radius + 1
            color: Colors.accentSoft
            scale: btRowSurface.scale
            transformOrigin: Item.Center
            opacity: btRowItem.isSelected ? 0.65 : 0.0
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
            id: btRowSurface
            anchors.centerIn: parent
            width: parent.width - 12
            height: 56
            radius: 12

            scale: btRowMouse.pressed
                ? Motion.scalePress
                : (btRowItem.isSelected || btRowMouse.containsMouse)
                    ? Motion.scaleTileHover
                    : Motion.scaleNormal
            transformOrigin: Item.Center

            Behavior on scale {
                NumberAnimation {
                    duration: btRowMouse.pressed ? Motion.durationPressDown : Motion.durationPressRelease
                    easing.type: btRowMouse.pressed ? Motion.easingPressDown : Motion.easingPressRelease
                }
            }

            color: btRowItem.isSelected
                ? Colors.accentSoft
                : (btRowItem.connected
                    ? Colors.surfaceSoft
                    : (btRowMouse.containsMouse ? Colors.surface : Colors.surfaceSoft))

            border.width: btRowItem.isSelected ? 1.5 : (btRowItem.connected ? 1 : (btRowMouse.containsMouse ? 1 : 0))
            border.color: btRowItem.isSelected ? Colors.accent : Colors.border

            Behavior on color {
                ColorAnimation {
                    duration: Motion.durationFast
                    easing.type: Motion.easingStandard
                }
            }

            MouseArea {
                id: btRowMouse
                anchors.fill: parent
                hoverEnabled: true
                enabled: !view.busy && view.radioEnabled
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onEntered: {
                    view.deviceHovered(index);
                }
                onClicked: {
                    view.deviceAction(index, nearby ? "pair" : connected ? "disconnect" : "connect", address, name);
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 10
                spacing: 10

                Text {
                    text: nearby ? "bluetooth_searching" : connected ? "bluetooth_connected" : "bluetooth"
                    color: connected
                        ? Colors.accent
                        : nearby
                            ? Colors.textDim
                            : Colors.text
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
                        text: name || "Unknown Device"
                        color: Colors.text
                        font.pixelSize: 13
                        font.weight: connected ? Font.DemiBold : Font.Normal
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    RowLayout {
                        spacing: 6
                        Text {
                            text: nearby ? "Available · " + address : connected ? "Connected" : "Paired"
                            color: connected ? Colors.success : Colors.textDim
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }

                        Text {
                            visible: battery >= 0
                            text: "· " + battery + "%"
                            color: battery <= 15 ? Colors.critical : Colors.textDim
                            font.pixelSize: 11
                        }
                    }
                }

                // Action button (Connect / Disconnect / Pair)
                Item {
                    implicitWidth: actionSurface.implicitWidth
                    implicitHeight: 28

                    scale: actionMouse.pressed
                        ? Motion.scalePress
                        : actionMouse.containsMouse
                            ? Motion.scaleHover
                            : Motion.scaleNormal
                    transformOrigin: Item.Center

                    Behavior on scale {
                        NumberAnimation {
                            duration: Motion.durationFast
                            easing.type: Motion.easingStandard
                        }
                    }

                    Rectangle {
                        id: actionSurface
                        anchors.fill: parent
                        implicitWidth: actionText.implicitWidth + 20
                        implicitHeight: 28
                        radius: 8
                        color: connected
                            ? Colors.accentSoft
                            : actionMouse.containsMouse
                                ? Colors.hover
                                : Colors.surfaceSoft
                        border.width: 0

                        Behavior on color {
                            ColorAnimation {
                                duration: Motion.durationFast
                                easing.type: Motion.easingStandard
                            }
                        }

                        Text {
                            id: actionText
                            anchors.centerIn: parent
                            text: !view.radioEnabled ? "Off" : nearby ? "Pair" : connected ? "Disconnect" : "Connect"
                            color: view.radioEnabled ? (connected ? Colors.accent : Colors.text) : Colors.textDim
                            font.pixelSize: 11
                            font.weight: Font.Medium
                        }

                        MouseArea {
                            id: actionMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: !view.busy && view.radioEnabled
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: view.deviceAction(index, nearby ? "pair" : connected ? "disconnect" : "connect", address, name)
                        }
                    }
                }

                // Forget / Unpair button
                Rectangle {
                    visible: !nearby
                    implicitWidth: 28
                    implicitHeight: 28
                    radius: 8
                    color: removeMouse.containsMouse ? Colors.hover : Colors.clear
                    scale: removeMouse.pressed
                        ? Motion.scalePress
                        : (removeMouse.containsMouse ? Motion.scaleHover : Motion.scaleNormal)
                    border.width: 0

                    Behavior on scale {
                        NumberAnimation {
                            duration: removeMouse.pressed ? Motion.durationPressDown : Motion.durationPressRelease
                            easing.type: removeMouse.pressed ? Motion.easingPressDown : Motion.easingPressRelease
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
                        text: "link_off"
                        color: removeMouse.containsMouse ? Colors.critical : Colors.textDim
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
                        id: removeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: !view.busy
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: view.deviceForgetRequested(index, address, name)
                    }
                }
            }


        }
    }

    Text {
        anchors.centerIn: parent
        visible: opacity > 0.01
        opacity: view.deviceCount === 0 ? 1 : 0
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
            ? "Loading devices…"
            : view.searching
                ? "Searching nearby…"
                : view.error
                    ? view.error
                    : !view.radioEnabled
                        ? "Bluetooth is off\nTurn it on to view and pair devices."
                        : view.busy
                            ? "Updating devices…"
                            : "No devices found\nMake sure your device is discoverable, then search again."
        color: view.error ? Colors.critical : Colors.textDim
        font.pixelSize: 12
    }
}
