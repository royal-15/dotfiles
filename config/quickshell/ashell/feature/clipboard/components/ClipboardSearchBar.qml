import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs
import qs.components

Item {
    id: root

    property alias text: searchField.text
    property alias searchField: searchField
    property bool confirmingWipe: false

    signal navigateDown()
    signal navigateUp()
    signal activateCurrent()
    signal deleteCurrent()
    signal closeRequested()

    implicitHeight: 44

    Timer {
        id: confirmationTimer
        interval: 4000
        repeat: false
        onTriggered: {
            root.confirmingWipe = false;
        }
    }

    // Apple Focus Ring Halo around clipboard search input
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
                text: "content_paste_search"
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
                placeholderText: "Type to search clipboard history..."
                placeholderTextColor: Colors.textDim
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 13
                background: null
                verticalAlignment: TextInput.AlignVCenter
                selectionColor: Colors.selectedBackground
                selectedTextColor: Colors.selectedText

                Keys.onPressed: event => {
                    // Wipe history shortcut: Ctrl+Shift+Delete
                    if (event.key === Qt.Key_Delete && (event.modifiers & Qt.ControlModifier) && (event.modifiers & Qt.ShiftModifier)) {
                        if (root.confirmingWipe)
                            root.confirmWipe();
                        else
                            root.armWipe();
                        event.accepted = true;
                        return;
                    }

                    // Handling when confirming wipe
                    if (root.confirmingWipe) {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Y) {
                            root.confirmWipe();
                            event.accepted = true;
                            return;
                        }
                        if (event.key === Qt.Key_Escape || event.key === Qt.Key_N) {
                            root.cancelWipe();
                            event.accepted = true;
                            return;
                        }
                    }

                    // Down: Down, Tab (without Shift), Ctrl+N, Ctrl+J
                    if (event.key === Qt.Key_Down || (event.key === Qt.Key_Tab && !(event.modifiers & Qt.ShiftModifier))
                        || ((event.modifiers & Qt.ControlModifier) && (event.key === Qt.Key_N || event.key === Qt.Key_J))) {
                        root.navigateDown();
                        event.accepted = true;
                        return;
                    }

                    // Up: Up, Shift+Tab (Backtab), Ctrl+P, Ctrl+K
                    if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))
                        || ((event.modifiers & Qt.ControlModifier) && (event.key === Qt.Key_P || event.key === Qt.Key_K))) {
                        root.navigateUp();
                        event.accepted = true;
                        return;
                    }

                    // Activate: Return / Enter
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        root.activateCurrent();
                        event.accepted = true;
                        return;
                    }

                    // Delete item: Delete or Shift+Delete (without Ctrl)
                    if (event.key === Qt.Key_Delete && !(event.modifiers & Qt.ControlModifier)) {
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

            // Divider before wipe button
            Rectangle {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 18
                Layout.alignment: Qt.AlignVCenter
                color: Colors.border
            }

            // Clear All / Wipe history button
            Item {
                Layout.preferredHeight: 28
                Layout.preferredWidth: root.confirmingWipe ? 116 : 28
                Layout.alignment: Qt.AlignVCenter

                Behavior on Layout.preferredWidth {
                    NumberAnimation {
                        duration: Motion.durationFast
                        easing.type: Motion.easingStandard
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    color: root.confirmingWipe
                        ? Colors.criticalSoft
                        : (wipeHover.hovered ? Colors.hover : Colors.clear)
                    border.width: root.confirmingWipe ? 1 : 0
                    border.color: Colors.critical
                    clip: true

                    // Normal state: icon button
                    Item {
                        anchors.fill: parent
                        visible: !root.confirmingWipe

                        ToolTip.visible: wipeHover.hovered && !root.confirmingWipe
                        ToolTip.text: "Clear history (Ctrl+Shift+Delete)"
                        ToolTip.delay: 400

                        Text {
                            anchors.centerIn: parent
                            text: "delete_sweep"
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 18
                            color: wipeHover.hovered ? Colors.critical : Colors.textDim
                        }

                        HoverHandler {
                            id: wipeHover
                            cursorShape: Qt.PointingHandCursor
                        }

                        TapHandler {
                            onTapped: root.armWipe()
                        }
                    }

                    // Confirmation state: "Wipe?" + Confirm/Cancel
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 4
                        spacing: 4
                        visible: root.confirmingWipe

                        Text {
                            text: "Wipe all?"
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            color: Colors.text
                            Layout.leftMargin: 2
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Item { Layout.fillWidth: true }

                        // Confirm checkmark
                        Rectangle {
                            Layout.preferredWidth: 20
                            Layout.preferredHeight: 20
                            radius: 4
                            color: confirmHover.hovered ? Colors.critical : Colors.surfaceElevated

                            Text {
                                anchors.centerIn: parent
                                text: "check"
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 14
                                color: Colors.text
                            }

                            HoverHandler {
                                id: confirmHover
                                cursorShape: Qt.PointingHandCursor
                            }

                            TapHandler {
                                onTapped: root.confirmWipe()
                            }
                        }

                        // Cancel button
                        Rectangle {
                            Layout.preferredWidth: 20
                            Layout.preferredHeight: 20
                            radius: 4
                            color: cancelHover.hovered ? Colors.surfaceSoft : Colors.surfaceElevated

                            Text {
                                anchors.centerIn: parent
                                text: "close"
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 14
                                color: Colors.textDim
                            }

                            HoverHandler {
                                id: cancelHover
                                cursorShape: Qt.PointingHandCursor
                            }

                            TapHandler {
                                onTapped: root.cancelWipe()
                            }
                        }
                    }
                }
            }
        }
    }

    function armWipe() {
        root.confirmingWipe = true;
        confirmationTimer.restart();
    }

    function confirmWipe() {
        root.confirmingWipe = false;
        confirmationTimer.stop();
        ClipboardService.wipe();
        searchField.forceActiveFocus();
    }

    function cancelWipe() {
        root.confirmingWipe = false;
        confirmationTimer.stop();
        searchField.forceActiveFocus();
    }

    function focusInput() {
        searchField.forceActiveFocus();
    }
}
