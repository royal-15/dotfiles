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
    signal activateCurrent()
    signal deleteCurrent()
    signal toggleExpandCurrent()
    signal addNewRequested()
    signal editCurrentRequested()
    signal closeRequested()

    implicitHeight: 44

    // Apple Focus Ring Halo around command search input
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
        radius: 12
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
            anchors.leftMargin: 12
            anchors.rightMargin: 10
            spacing: 8

            Text {
                text: "terminal"
                color: searchField.activeFocus ? Colors.accent : Colors.textDim
                font.family: "Material Symbols Rounded"
                font.pixelSize: 20
                Layout.alignment: Qt.AlignVCenter

                Behavior on color {
                    ColorAnimation {
                        duration: Motion.durationFast
                        easing.type: Motion.easingStandard
                    }
                }
            }

            TextField {
                id: searchField
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Colors.text
                placeholderText: "Type to search commands (Ctrl+Space toggles multiline)..."
                placeholderTextColor: Colors.textDim
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 13
                background: null
                verticalAlignment: TextInput.AlignVCenter
                selectionColor: Colors.selectedBackground
                selectedTextColor: Colors.selectedText

                Keys.onPressed: event => {
                    // Ctrl + Space: toggle expansion
                    if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_Space) {
                        root.toggleExpandCurrent();
                        event.accepted = true;
                        return;
                    }

                    // Ctrl + N: Add new snippet
                    if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_N) {
                        root.addNewRequested();
                        event.accepted = true;
                        return;
                    }

                    // Ctrl + E: Edit selected snippet
                    if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_E) {
                        root.editCurrentRequested();
                        event.accepted = true;
                        return;
                    }

                    // Down: Down, Tab (without Shift), Ctrl+J
                    if (event.key === Qt.Key_Down || (event.key === Qt.Key_Tab && !(event.modifiers & Qt.ShiftModifier))
                        || ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_J)) {
                        root.navigateDown();
                        event.accepted = true;
                        return;
                    }

                    // Up: Up, Shift+Tab (Backtab), Ctrl+K
                    if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))
                        || ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_K)) {
                        root.navigateUp();
                        event.accepted = true;
                        return;
                    }

                    // Activate / Copy: Return / Enter
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        root.activateCurrent();
                        event.accepted = true;
                        return;
                    }

                    // Delete item: Delete
                    if (event.key === Qt.Key_Delete) {
                        root.deleteCurrent();
                        event.accepted = true;
                        return;
                    }

                    // Escape: Clear query or close
                    if (event.key === Qt.Key_Escape) {
                        if (searchField.text !== "") {
                            searchField.text = "";
                        } else {
                            root.closeRequested();
                        }
                        event.accepted = true;
                        return;
                    }
                }
            }

            // Clear search text button
            Item {
                visible: searchField.text !== ""
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                Layout.alignment: Qt.AlignVCenter

                Rectangle {
                    anchors.fill: parent
                    radius: 12
                    color: clearHover.hovered ? Colors.hover : Colors.clear

                    Text {
                        anchors.centerIn: parent
                        text: "close"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 16
                        color: clearHover.hovered ? Colors.text : Colors.textDim
                    }

                    HoverHandler {
                        id: clearHover
                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        onTapped: {
                            searchField.text = "";
                            searchField.forceActiveFocus();
                        }
                    }
                }
            }

            // Divider before Add button
            Rectangle {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 18
                Layout.alignment: Qt.AlignVCenter
                color: Colors.border
            }

            // Add new command button
            Rectangle {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                Layout.alignment: Qt.AlignVCenter
                radius: 8
                color: addHover.hovered ? Colors.accentSoft : Colors.clear

                Behavior on color {
                    ColorAnimation {
                        duration: Motion.durationFast
                        easing.type: Motion.easingStandard
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: "add"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 20
                    color: addHover.hovered ? Colors.accent : Colors.textDim
                }

                HoverHandler {
                    id: addHover
                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    onTapped: root.addNewRequested()
                }
            }
        }
    }

    function focusInput() {
        searchField.forceActiveFocus();
    }
}
