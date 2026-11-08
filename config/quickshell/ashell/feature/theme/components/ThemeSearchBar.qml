import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs
import qs.components

Item {
    id: root

    property alias text: searchField.text
    property alias searchField: searchField

    signal navigateDown()
    signal navigateUp()
    signal navigateLeft()
    signal navigateRight()
    signal activateCurrent()
    signal escapePressed()
    signal cleared()

    implicitHeight: 36

    function focusInput() {
        searchField.forceActiveFocus();
    }

    // Apple Focus Ring Halo around search input box
    Rectangle {
        anchors.fill: searchInputBox
        anchors.margins: -2
        radius: searchInputBox.radius + 2
        color: Colors.accentSoft
        opacity: searchField.activeFocus ? 0.75 : 0.0
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
        id: searchInputBox
        anchors.fill: parent
        radius: 10
        color: searchField.activeFocus ? Colors.surfaceMuted : Colors.surfaceSoft
        border.width: searchField.activeFocus ? 1.5 : 1
        border.color: searchField.activeFocus ? Colors.accent : Colors.border

        Behavior on color {
            ColorAnimation {
                duration: Motion.durationFast
                easing.type: Motion.easingStandard
            }
        }

        Behavior on border.color {
            ColorAnimation {
                duration: Motion.durationFast
                easing.type: Motion.easingStandard
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 8
            spacing: 8

            // Leading Search Icon
            Text {
                text: "search"
                color: searchField.activeFocus ? Colors.accent : Colors.textDim
                font.family: "Material Symbols Rounded"
                font.pixelSize: 18
                Layout.alignment: Qt.AlignVCenter

                Behavior on color {
                    ColorAnimation {
                        duration: Motion.durationFast
                        easing.type: Motion.easingStandard
                    }
                }
            }

            // Search TextField
            TextField {
                id: searchField
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Colors.text
                placeholderText: "Search themes..."
                placeholderTextColor: Colors.textDim
                font.pixelSize: 13
                font.weight: Font.Normal
                background: null
                verticalAlignment: TextInput.AlignVCenter
                selectionColor: Colors.selectedBackground
                selectedTextColor: Colors.selectedText

                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Down || (event.key === Qt.Key_Tab && !(event.modifiers & Qt.ShiftModifier))) {
                        root.navigateDown();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
                        root.navigateUp();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Left && searchField.cursorPosition === 0 && searchField.selectionStart === searchField.selectionEnd) {
                        root.navigateLeft();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Right && searchField.cursorPosition === searchField.text.length && searchField.selectionStart === searchField.selectionEnd) {
                        root.navigateRight();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        root.activateCurrent();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Escape) {
                        root.escapePressed();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Backspace && searchField.text === "") {
                        root.escapePressed();
                        event.accepted = true;
                    }
                }
            }

            // Trailing Clear Button / Esc Chip
            Rectangle {
                visible: root.text.length > 0
                implicitWidth: 20
                implicitHeight: 20
                radius: 10
                color: clearMouseArea.containsMouse ? Colors.surfaceElevated : Colors.clear
                Layout.alignment: Qt.AlignVCenter

                Text {
                    anchors.centerIn: parent
                    text: "close"
                    color: clearMouseArea.containsMouse ? Colors.text : Colors.textDim
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 14
                }

                MouseArea {
                    id: clearMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.text = "";
                        root.cleared();
                    }
                }
            }
        }
    }
}
