import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs
import qs.components

Item {
    id: root

    property alias networks: view.networks
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

    signal networkActivated(int index, var network)
    signal networkForgetRequested(int index, var network)
    signal networkHovered(int index)

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

            property var networks: []
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
            model: networks

            delegate: Item {
                id: rowItem
                required property var modelData
                required property int index

                readonly property bool isSelected: view.keyboardFocusActive && view.selectedIndex >= 0 && view.selectedIndex === index
                readonly property bool isInUse: modelData.inUse

                width: view.width
                height: 44
                z: rowItem.isSelected ? 5 : (wifiRowMouse.containsMouse ? 2 : 1)

                // Row surface hover / selected highlight with anti-cropping headroom
                Rectangle {
                    id: rowSurface
                    anchors.fill: parent
                    anchors.topMargin: 2
                    anchors.bottomMargin: 2
                    anchors.leftMargin: 4
                    anchors.rightMargin: 4
                    radius: 8
                    scale: wifiRowMouse.pressed
                        ? Motion.scalePress
                        : (rowItem.isSelected || wifiRowMouse.containsMouse)
                            ? Motion.scaleTileHover
                            : Motion.scaleNormal
                    transformOrigin: Item.Center

                    Behavior on scale {
                        NumberAnimation {
                            duration: Motion.durationFast
                            easing.type: Motion.easingStandard
                        }
                    }

                    color: rowItem.isSelected
                        ? Colors.accentSoft
                        : (wifiRowMouse.containsMouse ? Colors.hover : Colors.clear)

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

                        // Wi-Fi signal icon
                        Text {
                            text: modelData.inUse
                                ? "wifi"
                                : (modelData.signal < 35 ? "wifi_1_bar" : modelData.signal < 70 ? "wifi_2_bar" : "wifi")
                            color: modelData.inUse
                                ? Colors.accent
                                : (wifiRowMouse.containsMouse ? Colors.text : Colors.textDim)
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 16

                            Behavior on color {
                                ColorAnimation {
                                    duration: Motion.durationFast
                                    easing.type: Motion.easingStandard
                                }
                            }
                        }

                        // Network SSID & concise status
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                text: modelData.ssid || "Hidden Network"
                                color: rowItem.isInUse ? Colors.text : (wifiRowMouse.containsMouse ? Colors.text : Colors.text)
                                font.pixelSize: 12
                                font.weight: modelData.inUse ? Font.DemiBold : Font.Normal
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                visible: text !== ""
                                text: modelData.inUse
                                    ? "Connected"
                                    : modelData.savedUuid
                                        ? "Saved"
                                        : ""
                                color: modelData.inUse ? Colors.success : Colors.textDim
                                font.pixelSize: 10
                                font.weight: Font.Medium
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        // Resting status icons: Lock or In-Use Checkmark
                        Text {
                            visible: !(wifiRowMouse.containsMouse || rowItem.isSelected) && (modelData.inUse || (modelData.security && modelData.security !== "--"))
                            text: modelData.inUse ? "check" : "lock"
                            color: modelData.inUse ? Colors.accent : Colors.textFaint
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 15
                        }

                        // Hover/Focus dual actions: Connect/Disconnect pill + Forget button
                        RowLayout {
                            spacing: 6
                            visible: wifiRowMouse.containsMouse || rowItem.isSelected

                            // Connect / Disconnect action pill
                            Rectangle {
                                id: wifiActionSurface
                                implicitWidth: wifiActionText.implicitWidth + 14
                                implicitHeight: 24
                                radius: 12
                                color: modelData.inUse
                                    ? Colors.accentSoft
                                    : (wifiActionMouse.containsMouse ? Colors.hover : Colors.surfaceMuted)
                                border.width: 0

                                Behavior on color {
                                    ColorAnimation {
                                        duration: Motion.durationFast
                                        easing.type: Motion.easingStandard
                                    }
                                }

                                Text {
                                    id: wifiActionText
                                    anchors.centerIn: parent
                                    text: modelData.inUse ? "Disconnect" : "Connect"
                                    color: modelData.inUse ? Colors.accent : Colors.text
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                }

                                MouseArea {
                                    id: wifiActionMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    enabled: !view.busy && view.radioEnabled
                                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    onClicked: root.networkActivated(index, modelData)
                                }
                            }

                            // Hover-revealed Forget / Remove button
                            Rectangle {
                                id: forgetBtn
                                visible: modelData.savedUuid !== ""
                                implicitWidth: 24
                                implicitHeight: 24
                                radius: 6
                                color: forgetWifiMouse.containsMouse ? Colors.criticalSoft : Colors.clear

                                Text {
                                    anchors.centerIn: parent
                                    text: "delete"
                                    color: forgetWifiMouse.containsMouse ? Colors.critical : Colors.textDim
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 15
                                }

                                MouseArea {
                                    id: forgetWifiMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    enabled: !view.busy
                                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    onClicked: root.networkForgetRequested(index, modelData)
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
                        onEntered: root.networkHovered(index)
                        onClicked: root.networkActivated(index, modelData)
                    }
                }

                // Subtle hairline separator between list items (hidden when item or neighbor is focused/scaled)
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: 35
                    anchors.rightMargin: 10
                    height: 1
                    color: Colors.surfaceMuted
                    visible: index < (view.networks.length - 1) && !rowItem.isSelected && !wifiRowMouse.containsMouse
                }
            }
        }

        // Empty state & loading status label
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
}
