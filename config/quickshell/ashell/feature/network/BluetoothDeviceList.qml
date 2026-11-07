import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs
import qs.components

Item {
    id: root

    property alias devicesModel: view.model
    property alias deviceCount: view.deviceCount
    property alias busy: view.busy
    property alias radioEnabled: view.radioEnabled
    property alias loaded: view.loaded
    property alias searching: view.searching
    property alias error: view.error
    property alias keyboardFocusActive: view.keyboardFocusActive
    property alias selectedIndex: view.selectedIndex
    readonly property alias count: view.count

    function positionViewAtIndex(index, mode) {
        view.positionViewAtIndex(index, mode);
    }

    signal deviceAction(int index, string action, string address, string name)
    signal deviceForgetRequested(int index, string address, string name)
    signal deviceHovered(int index)

    Layout.fillWidth: true
    Layout.fillHeight: true

    // Apple Unified Inset Group Container
    Rectangle {
        id: containerSurface
        anchors.fill: parent
        radius: 12
        color: Colors.surfaceSoft
        border.width: 1
        border.color: Colors.border
        clip: true

        ListView {
            id: view

            property int deviceCount: 0
            property bool busy: false
            property bool radioEnabled: true
            property bool loaded: false
            property bool searching: false
            property string error: ""
            property bool keyboardFocusActive: false
            property int selectedIndex: -1

            anchors.fill: parent
            anchors.margins: 2
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            topMargin: 3
            bottomMargin: 3
            spacing: 0

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
                height: 44
                z: btRowItem.isSelected ? 5 : (btRowMouse.containsMouse ? 2 : 1)

                // Row surface hover / selected highlight with anti-cropping headroom
                Rectangle {
                    id: btRowSurface
                    anchors.fill: parent
                    anchors.topMargin: 2
                    anchors.bottomMargin: 2
                    anchors.leftMargin: 4
                    anchors.rightMargin: 4
                    radius: 8
                    scale: btRowMouse.pressed
                        ? Motion.scalePress
                        : (btRowItem.isSelected || btRowMouse.containsMouse)
                            ? Motion.scaleTileHover
                            : Motion.scaleNormal
                    transformOrigin: Item.Center

                    Behavior on scale {
                        NumberAnimation {
                            duration: Motion.durationFast
                            easing.type: Motion.easingStandard
                        }
                    }

                    color: btRowItem.isSelected
                        ? Colors.accentSoft
                        : (btRowMouse.containsMouse ? Colors.hover : Colors.clear)

                    Behavior on color {
                        ColorAnimation {
                            duration: Motion.durationFast
                            easing.type: Motion.easingStandard
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 9

                        // Bluetooth device glyph
                        Text {
                            text: nearby ? "bluetooth_searching" : connected ? "bluetooth_connected" : "bluetooth"
                            color: connected
                                ? Colors.accent
                                : (btRowMouse.containsMouse ? Colors.text : Colors.textDim)
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 16

                            Behavior on color {
                                ColorAnimation {
                                    duration: Motion.durationFast
                                    easing.type: Motion.easingStandard
                                }
                            }
                        }

                        // Device name & concise status
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                text: name || "Unknown Device"
                                color: connected ? Colors.text : (btRowMouse.containsMouse ? Colors.text : Colors.text)
                                font.pixelSize: 12
                                font.weight: connected ? Font.DemiBold : Font.Normal
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            RowLayout {
                                spacing: 4
                                Text {
                                    text: nearby ? "Available" : connected ? "Connected" : "Paired"
                                    color: connected ? Colors.success : Colors.textDim
                                    font.pixelSize: 10
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                }

                                Text {
                                    visible: battery >= 0
                                    text: "· " + battery + "%"
                                    color: battery <= 15 ? Colors.critical : Colors.textDim
                                    font.pixelSize: 10
                                }
                            }
                        }

                        // Hover/Focus dual actions: Connect/Disconnect/Pair pill + Forget/Unpair button
                        RowLayout {
                            spacing: 6
                            visible: btRowMouse.containsMouse || btRowItem.isSelected

                            // Connect / Disconnect / Pair action pill
                            Rectangle {
                                id: actionSurface
                                implicitWidth: actionText.implicitWidth + 14
                                implicitHeight: 24
                                radius: 12
                                color: connected
                                    ? Colors.accentSoft
                                    : (actionMouse.containsMouse ? Colors.hover : Colors.surfaceMuted)
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
                                    onClicked: root.deviceAction(index, nearby ? "pair" : connected ? "disconnect" : "connect", address, name)
                                }
                            }

                            // Hover-revealed Forget / Unpair button
                            Rectangle {
                                visible: !nearby
                                implicitWidth: 24
                                implicitHeight: 24
                                radius: 6
                                color: removeMouse.containsMouse ? Colors.criticalSoft : Colors.clear

                                Text {
                                    anchors.centerIn: parent
                                    text: "link_off"
                                    color: removeMouse.containsMouse ? Colors.critical : Colors.textDim
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 15
                                }

                                MouseArea {
                                    id: removeMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    enabled: !view.busy
                                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    onClicked: root.deviceForgetRequested(index, address, name)
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: btRowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: !view.busy && view.radioEnabled
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onEntered: root.deviceHovered(index)
                        onClicked: root.deviceAction(index, nearby ? "pair" : connected ? "disconnect" : "connect", address, name)
                    }
                }

                // Subtle hairline separator between list items
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 35
                    anchors.rightMargin: 10
                    height: 1
                    color: Colors.surfaceMuted
                    visible: index < (view.count - 1) && !btRowItem.isSelected && !btRowMouse.containsMouse
                }
            }
        }

        // Empty state & loading status label
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
}
