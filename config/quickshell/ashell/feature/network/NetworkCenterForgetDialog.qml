import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs
import qs.components

Dialog {
    id: root

    property string itemKind: "wifi"
    property string itemName: ""
    signal confirmed()
    signal dismissed()

    parent: Overlay.overlay
    implicitWidth: 320
    x: Math.round((parent.width - width) / 2)
    y: Math.round((parent.height - height) / 2)
    modal: true
    closePolicy: Popup.NoAutoClose
    title: ""
    standardButtons: Dialog.NoButton
    padding: 18

    Shortcut {
        sequence: "Escape"
        context: Qt.WindowShortcut
        enabled: root.visible
        onActivated: root.close()
    }

    Overlay.modal: Rectangle {
        color: Colors.overlay
    }

    background: Rectangle {
        id: dialogBackground
        color: Colors.surfaceElevated
        radius: Decorations.cornerRadius
        border.color: Colors.border
        border.width: 1
    }

    enter: Transition {
        ParallelAnimation {
            NumberAnimation {
                target: dialogBackground
                property: "opacity"
                from: 0
                to: 1
                duration: Motion.durationNormal
                easing.type: Motion.easingStandard
            }
            NumberAnimation {
                target: dialogBackground
                property: "scale"
                from: 0.96
                to: 1
                duration: Motion.durationNormal
                easing.type: Motion.easingStandard
            }
            NumberAnimation {
                target: dialogContent
                property: "opacity"
                from: 0
                to: 1
                duration: Motion.durationNormal
                easing.type: Motion.easingStandard
            }
            NumberAnimation {
                target: dialogContent
                property: "scale"
                from: 0.96
                to: 1
                duration: Motion.durationNormal
                easing.type: Motion.easingStandard
            }
        }
    }

    exit: Transition {
        ParallelAnimation {
            NumberAnimation {
                target: dialogBackground
                property: "opacity"
                to: 0
                duration: Motion.durationFast
                easing.type: Motion.easingIn
            }
            NumberAnimation {
                target: dialogBackground
                property: "scale"
                to: 0.97
                duration: Motion.durationFast
                easing.type: Motion.easingIn
            }
            NumberAnimation {
                target: dialogContent
                property: "opacity"
                to: 0
                duration: Motion.durationFast
                easing.type: Motion.easingIn
            }
            NumberAnimation {
                target: dialogContent
                property: "scale"
                to: 0.97
                duration: Motion.durationFast
                easing.type: Motion.easingIn
            }
        }
    }

    contentItem: ColumnLayout {
        id: dialogContent
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            spacing: 11

            Rectangle {
                width: 38
                height: 38
                radius: 12
                color: Colors.criticalSoft
                border.width: 0

                Text {
                    anchors.centerIn: parent
                    text: root.itemKind === "wifi" ? "wifi_off" : "link_off"
                    color: Colors.critical
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 20
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                Text {
                    text: root.itemKind === "wifi" ? "Forget network?" : "Unpair device?"
                    color: Colors.text
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                }

                Text {
                    text: root.itemName
                    color: Colors.textDim
                    font.pixelSize: 12
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }
        }

        Text {
            text: root.itemKind === "wifi"
                ? "The saved network details will be removed from this device."
                : "This device will be unpaired and removed from your Bluetooth devices."
            color: Colors.textDim
            font.pixelSize: 12
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignRight
            spacing: 8

            Button {
                id: cancelButton
                Layout.preferredWidth: 84
                implicitHeight: 38
                text: "Cancel"
                onClicked: root.close()
                background: Rectangle {
                    color: parent.down ? Colors.surface : parent.hovered ? Colors.surface : Colors.surfaceSoft
                    radius: 11
                    border.width: parent.hovered ? 1 : 0
                    border.color: Colors.border
                    Behavior on color {
                        ColorAnimation {
                            duration: Motion.durationFast
                            easing.type: Motion.easingStandard
                        }
                    }
                }
                contentItem: Text {
                    text: parent.text
                    color: parent.hovered ? Colors.text : Colors.textDim
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
            }

            Button {
                Layout.fillWidth: true
                implicitHeight: 38
                text: root.itemKind === "wifi" ? "Forget network" : "Unpair device"
                onClicked: {
                    root.close();
                    root.confirmed();
                }
                background: Rectangle {
                    color: parent.down ? Colors.critical : parent.hovered ? Colors.critical : Colors.criticalSoft
                    radius: 11
                    border.width: 0
                    Behavior on color {
                        ColorAnimation {
                            duration: Motion.durationFast
                            easing.type: Motion.easingStandard
                        }
                    }
                }
                contentItem: Text {
                    text: parent.text
                    color: parent.hovered ? Colors.textAccent : Colors.critical
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
            }
        }
    }

    onOpened: cancelButton.forceActiveFocus()
    onClosed: dismissed()
}
