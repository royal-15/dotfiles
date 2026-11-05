import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs
import qs.components

Dialog {
    id: root

    property string deviceName: ""
    property string prompt: ""
    property string passkey: ""
    property bool started: false
    property bool inputRequired: false
    signal pairRequested()
    signal promptSubmitted(string value)
    signal cancelRequested()
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
        onActivated: root.cancelRequested()
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

    function focusPairingTarget() {
        if (inputRequired)
            pairingPin.forceActiveFocus();
        else if (started && actionButton.enabled)
            actionButton.forceActiveFocus();
        else
            cancelButton.forceActiveFocus();
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
                color: Colors.accentSoft
                border.width: 0

                Text {
                    anchors.centerIn: parent
                    text: "bluetooth"
                    color: Colors.accent
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 20
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                Text {
                    text: root.started ? "Pairing device" : "Pair Bluetooth device"
                    color: Colors.text
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                }

                Text {
                    text: root.deviceName
                    color: Colors.textDim
                    font.pixelSize: 12
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }
        }

        Text {
            text: root.prompt + (root.passkey && root.prompt.indexOf(root.passkey) < 0 ? "\nPasskey: " + root.passkey : "")
            color: Colors.textDim
            font.pixelSize: 12
            wrapMode: Text.Wrap
            Layout.fillWidth: true
        }

        TextField {
            id: pairingPin
            visible: root.inputRequired
            placeholderText: "PIN or passkey"
            echoMode: TextInput.Normal
            Layout.fillWidth: true
            implicitHeight: 40
            color: Colors.text
            background: Rectangle {
                color: pairingPin.activeFocus ? Colors.surfaceMuted : Colors.surfaceSoft
                radius: 11
                border.width: 0
                Behavior on color {
                    ColorAnimation {
                        duration: Motion.durationFast
                        easing.type: Motion.easingStandard
                    }
                }
            }
            onAccepted: if (actionButton.enabled) actionButton.clicked()
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
                onClicked: root.cancelRequested()
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
                id: actionButton
                Layout.fillWidth: true
                implicitHeight: 38
                text: !root.started ? "Pair" : root.inputRequired ? "Submit" : "Confirm"
                enabled: !root.started || (root.inputRequired ? pairingPin.text.length > 0 : !!root.passkey || /confirm passkey|authorize service/i.test(root.prompt))
                onClicked: {
                    if (!root.started)
                        root.pairRequested();
                    else
                        root.promptSubmitted(root.inputRequired ? pairingPin.text : "yes");
                }
                background: Rectangle {
                    color: parent.enabled
                        ? (parent.down ? Colors.accentAlt : Colors.accent)
                        : Colors.surfaceMuted
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
                    color: parent.enabled ? Colors.selectedText : Colors.textDim
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
            }
        }
    }

    onOpened: focusPairingTarget()
    onClosed: dismissed()
}
