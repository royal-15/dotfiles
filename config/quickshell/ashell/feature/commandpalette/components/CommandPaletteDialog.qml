import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs
import qs.components

Item {
    id: root

    property bool isOpen: false
    property string editingId: ""
    property string initialLabel: ""
    property string initialSnippet: ""
    property bool hasError: false

    signal saved(string id, string label, string snippet)
    signal dismissed()

    visible: isOpen || modalOpacity > 0.01

    property real modalOpacity: isOpen ? 1.0 : 0.0
    Behavior on modalOpacity {
        NumberAnimation {
            duration: Motion.durationNormal
            easing.type: Motion.easingStandard
        }
    }

    // Modal Scrim Backdrop
    Rectangle {
        anchors.fill: parent
        color: Colors.overlay
        opacity: root.modalOpacity
        radius: Decorations.cornerRadius

        TapHandler {
            onTapped: root.close()
        }
    }

    // Dialog Modal Card
    Rectangle {
        id: dialogCard
        width: Math.min(parent.width - 40, 480)
        height: Math.min(parent.height - 30, 360)
        anchors.centerIn: parent
        radius: Decorations.cornerRadius
        color: Colors.surfaceElevated
        border.width: 1
        border.color: Colors.border
        opacity: root.modalOpacity
        scale: 0.95 + 0.05 * root.modalOpacity

        Behavior on scale {
            NumberAnimation {
                duration: Motion.durationNormal
                easing.type: Motion.easingStandard
            }
        }

        // Ambient drop shadow
        Rectangle {
            anchors.fill: parent
            anchors.topMargin: 4
            anchors.bottomMargin: -2
            radius: parent.radius
            color: Colors.shadowTip
            z: -1
            opacity: 0.5
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            // Header Row
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: root.editingId !== "" ? "edit" : "add_box"
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 22
                    color: Colors.accent
                    Layout.alignment: Qt.AlignVCenter
                }

                Text {
                    text: root.editingId !== "" ? "Edit Command Snippet" : "New Command Snippet"
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                    color: Colors.text
                    Layout.alignment: Qt.AlignVCenter
                }

                Item { Layout.fillWidth: true }

                // Close (X) icon button
                Rectangle {
                    Layout.preferredWidth: 26
                    Layout.preferredHeight: 26
                    radius: 13
                    color: closeHover.hovered ? Colors.hover : Colors.clear
                    scale: closeTap.pressed
                        ? Motion.scalePress
                        : (closeHover.hovered ? Motion.scaleHover : Motion.scaleNormal)
                    transformOrigin: Item.Center

                    Behavior on scale {
                        NumberAnimation {
                            duration: closeTap.pressed ? Motion.durationPressDown : Motion.durationPressRelease
                            easing.type: closeTap.pressed ? Motion.easingPressDown : Motion.easingPressRelease
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "close"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 18
                        color: closeHover.hovered ? Colors.text : Colors.textDim
                    }

                    HoverHandler {
                        id: closeHover
                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        id: closeTap
                        onTapped: root.close()
                    }
                }
            }

            // Label Field (Optional)
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    text: "LABEL (OPTIONAL)"
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    color: Colors.textDim
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36

                    // Focus halo for label field
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -2
                        radius: 10
                        color: Colors.accentSoft
                        opacity: labelField.activeFocus ? 0.75 : 0.0
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
                        id: labelBox
                        anchors.fill: parent
                        radius: 8
                        color: labelField.activeFocus ? Colors.surfaceMuted : Colors.surfaceSoft
                        border.width: labelField.activeFocus ? 1.5 : 1
                        border.color: labelField.activeFocus ? Colors.accent : Colors.border

                        TextField {
                            id: labelField
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            color: Colors.text
                            placeholderText: "e.g. Git: Revert last commit"
                            placeholderTextColor: Colors.textFaint
                            font.pixelSize: 12
                            background: null
                            verticalAlignment: TextInput.AlignVCenter
                            selectionColor: Colors.selectedBackground
                            selectedTextColor: Colors.selectedText

                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Escape) {
                                    root.close();
                                    event.accepted = true;
                                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    snippetArea.forceActiveFocus();
                                    event.accepted = true;
                                }
                            }
                        }
                    }
                }
            }

            // Snippet Field (Multiline)
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "COMMAND SNIPPET (REQUIRED)"
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        color: root.hasError ? Colors.critical : Colors.textDim
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        visible: root.hasError
                        text: "Snippet cannot be empty"
                        font.pixelSize: 10
                        color: Colors.critical
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    // Focus halo for snippet area
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -2
                        radius: 10
                        color: root.hasError ? Colors.criticalSoft : Colors.accentSoft
                        opacity: (snippetArea.activeFocus || root.hasError) ? 0.75 : 0.0
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
                        anchors.fill: parent
                        radius: 8
                        color: snippetArea.activeFocus ? Colors.surfaceMuted : Colors.surfaceSoft
                        border.width: (snippetArea.activeFocus || root.hasError) ? 1.5 : 1
                        border.color: root.hasError ? Colors.critical : (snippetArea.activeFocus ? Colors.accent : Colors.border)

                        ScrollView {
                            anchors.fill: parent
                            anchors.margins: 8
                            clip: true

                            TextArea {
                                id: snippetArea
                                color: Colors.text
                                placeholderText: "Type or paste multi-line shell snippet here..."
                                placeholderTextColor: Colors.textFaint
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 12
                                wrapMode: TextEdit.WrapAnywhere
                                background: null
                                selectionColor: Colors.selectedBackground
                                selectedTextColor: Colors.selectedText

                                onTextChanged: {
                                    if (root.hasError && text.trim() !== "")
                                        root.hasError = false;
                                }

                                Keys.onPressed: event => {
                                    if (event.key === Qt.Key_Escape) {
                                        root.close();
                                        event.accepted = true;
                                        return;
                                    }
                                    if ((event.modifiers & Qt.ControlModifier) && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
                                        root.submit();
                                        event.accepted = true;
                                        return;
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Actions Footer
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "Ctrl+Enter to save"
                    font.pixelSize: 10
                    color: Colors.textFaint
                    Layout.alignment: Qt.AlignVCenter
                }

                Item { Layout.fillWidth: true }

                // Cancel Button
                Rectangle {
                    Layout.preferredWidth: 70
                    Layout.preferredHeight: 32
                    radius: 6
                    color: cancelHover.hovered ? Colors.hover : Colors.surfaceMuted
                    scale: cancelTap.pressed
                        ? Motion.scalePress
                        : (cancelHover.hovered ? Motion.scaleTileHover : Motion.scaleNormal)
                    transformOrigin: Item.Center

                    Behavior on scale {
                        NumberAnimation {
                            duration: cancelTap.pressed ? Motion.durationPressDown : Motion.durationPressRelease
                            easing.type: cancelTap.pressed ? Motion.easingPressDown : Motion.easingPressRelease
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "Cancel"
                        font.pixelSize: 12
                        color: Colors.text
                    }

                    HoverHandler {
                        id: cancelHover
                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        id: cancelTap
                        onTapped: root.close()
                    }
                }

                // Save Button
                Rectangle {
                    Layout.preferredWidth: 70
                    Layout.preferredHeight: 32
                    radius: 6
                    color: saveHover.hovered ? Colors.accent : Colors.accentSoft
                    scale: saveTap.pressed
                        ? Motion.scalePress
                        : (saveHover.hovered ? Motion.scaleTileHover : Motion.scaleNormal)
                    transformOrigin: Item.Center

                    Behavior on scale {
                        NumberAnimation {
                            duration: saveTap.pressed ? Motion.durationPressDown : Motion.durationPressRelease
                            easing.type: saveTap.pressed ? Motion.easingPressDown : Motion.easingPressRelease
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
                        text: "Save"
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: saveHover.hovered ? Colors.textAccent : Colors.accent
                    }

                    HoverHandler {
                        id: saveHover
                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        id: saveTap
                        onTapped: root.submit()
                    }
                }
            }
        }
    }

    function openForNew() {
        root.editingId = "";
        labelField.text = "";
        snippetArea.text = "";
        root.hasError = false;
        root.isOpen = true;
        Qt.callLater(() => labelField.forceActiveFocus());
    }

    function openForEdit(entry) {
        if (!entry)
            return;
        root.editingId = entry.id;
        labelField.text = entry.label || "";
        snippetArea.text = entry.snippet || "";
        root.hasError = false;
        root.isOpen = true;
        Qt.callLater(() => snippetArea.forceActiveFocus());
    }

    function close() {
        root.isOpen = false;
        root.hasError = false;
        root.dismissed();
    }

    function submit() {
        const snippet = snippetArea.text.trim();
        if (!snippet) {
            root.hasError = true;
            snippetArea.forceActiveFocus();
            return;
        }

        const label = labelField.text.trim();
        root.saved(root.editingId, label, snippet);
        root.close();
    }
}
