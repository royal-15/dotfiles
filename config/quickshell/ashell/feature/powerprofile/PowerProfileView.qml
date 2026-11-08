import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs
import qs.components
import qs.feature.bar
import qs.feature.powerprofile

Item {
    id: root

    property int selectedIndex: 0
    property string confirmingAction: ""
    property string hoveredActionKey: ""
    property bool isCurrentTab: false
    signal closeRequested()
    signal closeImmediateRequested()

    onIsCurrentTabChanged: {
        if (isCurrentTab)
            PowerProfileService.refreshUptime();
    }

    readonly property var sessionActions: [
        { key: "lock", label: "Lock", subtitle: "Lock session", icon: "lock", destructive: false, shortcut: "L" },
        { key: "logout", label: "Log Out", subtitle: "Log out of Hyprland", icon: "logout", destructive: true, shortcut: "O" },
        { key: "reboot", label: "Restart", subtitle: "Restart computer", icon: "restart_alt", destructive: true, shortcut: "R" },
        { key: "poweroff", label: "Shut Down", subtitle: "Shut down computer", icon: "power_settings_new", destructive: true, shortcut: "S" }
    ]

    readonly property int totalProfiles: PowerProfileService.profiles.length
    readonly property int totalItems: totalProfiles + sessionActions.length
    readonly property string selectedProfile: selectedIndex >= 0 && selectedIndex < totalProfiles ? PowerProfileService.profiles[selectedIndex] : ""

    implicitWidth: 360
    implicitHeight: 216

    Timer {
        id: confirmResetTimer
        interval: 3000
        repeat: false
        onTriggered: root.confirmingAction = ""
    }

    function resetState() {
        confirmingAction = "";
        hoveredActionKey = "";
        confirmResetTimer.stop();
        syncSelectionToActive();
    }

    function syncSelectionToActive() {
        const activeIndex = PowerProfileService.profiles.indexOf(StatusBarService.powerProfile);
        if (activeIndex >= 0)
            selectedIndex = activeIndex;
        else
            selectedIndex = Math.max(0, Math.min(selectedIndex, totalProfiles - 1));
    }

    function focusKeyboardTarget() {
        if (!isCurrentTab)
            return;
        panelFocusScope.forceActiveFocus();
    }

    function handleKey(event) {
        if (event.key === Qt.Key_Escape) {
            if (root.confirmingAction !== "") {
                root.confirmingAction = "";
                confirmResetTimer.stop();
            } else {
                root.closeRequested();
            }
            return true;
        }

        // Direct session action shortcuts without Ctrl/Alt/Meta: L, O, R, S
        if ((event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier)) === 0) {
            let directActionKey = "";
            if (event.key === Qt.Key_L) directActionKey = "lock";
            else if (event.key === Qt.Key_O) directActionKey = "logout";
            else if (event.key === Qt.Key_R) directActionKey = "reboot";
            else if (event.key === Qt.Key_S) directActionKey = "poweroff";

            if (directActionKey !== "") {
                for (let i = 0; i < sessionActions.length; i++) {
                    if (sessionActions[i].key === directActionKey) {
                        selectedIndex = totalProfiles + i;
                        break;
                    }
                }
                triggerSessionAction(directActionKey, true);
                return true;
            }
        }

        if ((event.modifiers & Qt.ControlModifier) !== 0) {
            return false;
        } else if (event.key === Qt.Key_Left) {
            moveH(-1);
            return true;
        } else if (event.key === Qt.Key_Right) {
            moveH(1);
            return true;
        } else if (event.key === Qt.Key_Up) {
            moveV(-1);
            return true;
        } else if (event.key === Qt.Key_Down) {
            moveV(1);
            return true;
        } else if (event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
            moveSelection(-1);
            return true;
        } else if (event.key === Qt.Key_Tab) {
            moveSelection(1);
            return true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            if (!event.isAutoRepeat) {
                if (root.confirmingAction !== "")
                    triggerSessionAction(root.confirmingAction, true);
                else
                    activateCurrentSelection();
            }
            return true;
        }
        return false;
    }

    function moveSelection(direction) {
        if (totalItems === 0)
            return;
        selectedIndex = (selectedIndex + direction + totalItems) % totalItems;
    }

    function moveH(direction) {
        if (totalItems === 0)
            return;
        if (selectedIndex < totalProfiles) {
            selectedIndex = (selectedIndex + direction + totalProfiles) % totalProfiles;
        } else {
            const sessionIdx = selectedIndex - totalProfiles;
            const newSessionIdx = (sessionIdx + direction + sessionActions.length) % sessionActions.length;
            selectedIndex = totalProfiles + newSessionIdx;
        }
    }

    function moveV(direction) {
        if (totalItems === 0)
            return;
        if (selectedIndex < totalProfiles) {
            if (direction > 0) {
                const targetAction = Math.min(sessionActions.length - 1, Math.round(selectedIndex * (sessionActions.length - 1) / Math.max(1, totalProfiles - 1)));
                selectedIndex = totalProfiles + targetAction;
            }
        } else {
            if (direction < 0) {
                const sessionIdx = selectedIndex - totalProfiles;
                const targetProfile = Math.min(totalProfiles - 1, Math.round(sessionIdx * (totalProfiles - 1) / Math.max(1, sessionActions.length - 1)));
                selectedIndex = targetProfile;
            }
        }
    }

    function activateCurrentSelection(closeAfterAction) {
        if (closeAfterAction === undefined)
            closeAfterAction = true;

        if (selectedIndex >= 0 && selectedIndex < totalProfiles) {
            if (selectedProfile && selectedProfile !== StatusBarService.powerProfile)
                PowerProfileService.apply(selectedProfile);
            if (closeAfterAction)
                root.closeRequested();
        } else if (selectedIndex >= totalProfiles && selectedIndex < totalItems) {
            const actionIndex = selectedIndex - totalProfiles;
            const actionItem = sessionActions[actionIndex];
            if (actionItem)
                triggerSessionAction(actionItem.key, closeAfterAction);
        }
    }

    function triggerSessionAction(key, closeAfterAction) {
        if (closeAfterAction === undefined)
            closeAfterAction = true;

        if (key === "lock") {
            confirmResetTimer.stop();
            confirmingAction = "";
            root.closeImmediateRequested();
            PowerProfileService.executeSessionAction("lock");
            return;
        }

        if (confirmingAction === key) {
            confirmResetTimer.stop();
            confirmingAction = "";
            PowerProfileService.executeSessionAction(key);
            if (closeAfterAction)
                root.closeRequested();
        } else {
            confirmingAction = key;
            confirmResetTimer.restart();
        }
    }

    function actionLabel(key) {
        if (key === "lock") return "Lock";
        if (key === "logout") return "Log Out";
        if (key === "reboot") return "Restart";
        if (key === "poweroff") return "Shut Down";
        return "";
    }

    function actionSubtitle(key) {
        if (key === "lock") return "Lock session";
        if (key === "logout") return "Log out of Hyprland";
        if (key === "reboot") return "Restart computer";
        if (key === "poweroff") return "Shut down computer";
        return "";
    }

    function actionShortcut(key) {
        for (let i = 0; i < sessionActions.length; i++) {
            if (sessionActions[i].key === key)
                return sessionActions[i].shortcut;
        }
        return "";
    }

    readonly property string dynamicStatusText: {
        if (PowerProfileService.applyingProfile !== "")
            return `Applying ${PowerProfileService.labelFor(PowerProfileService.applyingProfile)}…`;
        if (PowerProfileService.error !== "")
            return "Could not change power profile";
        if (root.confirmingAction !== "")
            return `Confirm ${root.actionLabel(root.confirmingAction)}? Press ${root.actionShortcut(root.confirmingAction)} or Enter to confirm`;
        if (root.hoveredActionKey !== "")
            return root.actionSubtitle(root.hoveredActionKey);
        if (root.selectedIndex >= root.totalProfiles && root.selectedIndex < root.totalItems) {
            const action = root.sessionActions[root.selectedIndex - root.totalProfiles];
            if (action)
                return root.actionSubtitle(action.key);
        }

        const uptimePart = PowerProfileService.awakeTime !== "" ? ` · ${PowerProfileService.awakeTime}` : "";
        if (StatusBarService.isAcConnected) {
            if (StatusBarService.batteryPercent !== "") {
                if (StatusBarService.isCharging)
                    return `AC Connected · ${StatusBarService.batteryPercent}% (Charging)${uptimePart}`;
                if (StatusBarService.isBatteryFull)
                    return `AC Connected · ${StatusBarService.batteryPercent}% (Charged)${uptimePart}`;
                return `AC Connected · ${StatusBarService.batteryPercent}%${uptimePart}`;
            }
            return `AC Connected${uptimePart}`;
        }
        if (StatusBarService.batteryPercent !== "") {
            return `Battery · ${StatusBarService.batteryPercent}%${uptimePart}`;
        }
        if (PowerProfileService.awakeTime !== "") {
            return `Uptime · ${PowerProfileService.awakeTime}`;
        }
        return "Performance and session controls";
    }

    FocusScope {
        id: panelFocusScope
        anchors.fill: parent
        focus: root.isCurrentTab
        Keys.priority: Keys.BeforeItem
        Keys.onPressed: event => {
            if (root.handleKey(event))
                event.accepted = true;
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            // 1. Sleek Apple Telemetry Header Row
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: "Power"
                        color: Colors.text
                        font.pixelSize: 16
                        font.weight: Font.DemiBold
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.dynamicStatusText
                        color: PowerProfileService.error !== ""
                            ? Colors.critical
                            : root.confirmingAction !== ""
                                ? Colors.warning
                                : Colors.textDim
                        font.pixelSize: 11
                        elide: Text.ElideRight

                        Behavior on color {
                            ColorAnimation {
                                duration: Motion.durationFast
                                easing.type: Motion.easingStandard
                            }
                        }
                    }
                }

                // Close button
                Rectangle {
                    implicitWidth: 28
                    implicitHeight: 28
                    radius: 8
                    color: closeMouse.containsMouse ? Colors.hover : Colors.surfaceSoft
                    border.width: 0
                    scale: closeMouse.pressed ? Motion.scalePress : closeMouse.containsMouse ? Motion.scaleHover : Motion.scaleNormal

                    Behavior on scale {
                        NumberAnimation {
                            duration: Motion.durationFast
                            easing.type: Motion.easingStandard
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
                        text: "close"
                        color: closeMouse.containsMouse ? Colors.text : Colors.textDim
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 16
                    }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.closeRequested()
                    }
                }
            }

            // 2. Apple 3-Way Segmented Power Profile Selector
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 36
                radius: 10
                color: Colors.surfaceMuted
                border.width: 0
                visible: PowerProfileService.profiles.length > 0

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 3
                    spacing: 4

                    Repeater {
                        model: PowerProfileService.profiles

                        delegate: Item {
                            id: profileSegment
                            required property string modelData
                            required property int index

                            readonly property bool isSelected: root.selectedIndex === index
                            readonly property bool isActive: modelData === StatusBarService.powerProfile
                            readonly property color profileAccent: modelData === "power-saver"
                                ? Colors.success
                                : modelData === "performance"
                                    ? Colors.critical
                                    : Colors.accent

                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            scale: tileMouse.pressed
                                ? Motion.scalePress
                                : (tileMouse.containsMouse || profileSegment.isSelected)
                                    ? Motion.scaleTileHover
                                    : Motion.scaleNormal
                            transformOrigin: Item.Center

                            Behavior on scale {
                                NumberAnimation {
                                    duration: tileMouse.pressed ? Motion.durationPressDown : Motion.durationPressRelease
                                    easing.type: tileMouse.pressed ? Motion.easingPressDown : Motion.easingPressRelease
                                }
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: 8
                                color: profileSegment.isActive
                                    ? Colors.surfaceSoft
                                    : profileSegment.isSelected
                                        ? Colors.accentSoft
                                        : (tileMouse.containsMouse ? Colors.hover : Colors.clear)
                                border.width: profileSegment.isActive ? 1 : (profileSegment.isSelected ? 1.5 : 0)
                                border.color: profileSegment.isSelected ? Colors.accent : (profileSegment.isActive ? Colors.border : Colors.clear)

                                Behavior on color {
                                    ColorAnimation {
                                        duration: Motion.durationFast
                                        easing.type: Motion.easingStandard
                                    }
                                }

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 5

                                    Text {
                                        text: PowerProfileService.iconFor(modelData)
                                        color: profileSegment.isActive ? profileAccent : (profileSegment.isSelected ? Colors.accent : Colors.textDim)
                                        font.family: "Material Symbols Rounded"
                                        font.pixelSize: 15

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: Motion.durationFast
                                                easing.type: Motion.easingStandard
                                            }
                                        }
                                    }

                                    Text {
                                        text: PowerProfileService.labelFor(modelData)
                                        color: profileSegment.isActive ? Colors.text : (profileSegment.isSelected ? Colors.accent : Colors.textDim)
                                        font.pixelSize: 11
                                        font.weight: profileSegment.isActive ? Font.DemiBold : Font.Medium
                                        elide: Text.ElideRight

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: Motion.durationFast
                                                easing.type: Motion.easingStandard
                                            }
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: tileMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: root.selectedIndex = index
                                onClicked: {
                                    root.selectedIndex = index;
                                    root.activateCurrentSelection(false);
                                }
                            }
                        }
                    }
                }
            }

            // 3. Apple 4-Button Session Quick Actions Cluster
            RowLayout {
                Layout.fillWidth: true
                implicitHeight: 38
                spacing: 6

                Repeater {
                    model: root.sessionActions

                    delegate: Item {
                        id: actionItem
                        required property var modelData
                        required property int index

                        readonly property int itemAbsoluteIndex: root.totalProfiles + index
                        readonly property bool isSelected: root.selectedIndex === itemAbsoluteIndex
                        readonly property bool isConfirming: root.confirmingAction === modelData.key
                        readonly property bool isDestructive: modelData.destructive

                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        scale: actionMouse.pressed
                            ? Motion.scalePress
                            : (actionMouse.containsMouse || isSelected)
                                ? Motion.scaleTileHover
                                : Motion.scaleNormal
                        transformOrigin: Item.Center

                        Behavior on scale {
                            NumberAnimation {
                                duration: actionMouse.pressed ? Motion.durationPressDown : Motion.durationPressRelease
                                easing.type: actionMouse.pressed ? Motion.easingPressDown : Motion.easingPressRelease
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 10
                            color: actionItem.isConfirming
                                ? Colors.critical
                                : actionItem.isSelected
                                    ? (actionItem.isDestructive ? Colors.criticalSoft : Colors.accentSoft)
                                    : (actionMouse.containsMouse && actionItem.isDestructive)
                                        ? Colors.criticalSoft
                                        : actionMouse.containsMouse
                                            ? Colors.surfaceMuted
                                            : Colors.surfaceSoft
                            border.width: actionItem.isSelected ? 1.5 : (actionItem.isConfirming ? 1 : 0)
                            border.color: actionItem.isConfirming
                                ? Colors.critical
                                : (actionItem.isSelected ? (actionItem.isDestructive ? Colors.critical : Colors.accent) : Colors.border)

                            Behavior on color {
                                ColorAnimation {
                                    duration: Motion.durationFast
                                    easing.type: Motion.easingStandard
                                }
                            }

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    text: actionItem.isConfirming ? "priority_high" : modelData.icon
                                    color: actionItem.isConfirming
                                        ? Colors.selectedText
                                        : actionItem.isSelected
                                            ? (actionItem.isDestructive ? Colors.critical : Colors.accent)
                                            : (actionMouse.containsMouse && actionItem.isDestructive
                                                ? Colors.critical
                                                : (actionMouse.containsMouse ? Colors.text : Colors.textDim))
                                    font.family: "Material Symbols Rounded"
                                    font.pixelSize: 18

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: Motion.durationFast
                                            easing.type: Motion.easingStandard
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: actionMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: {
                                    root.hoveredActionKey = modelData.key;
                                    root.selectedIndex = itemAbsoluteIndex;
                                }
                                onExited: {
                                    if (root.hoveredActionKey === modelData.key)
                                        root.hoveredActionKey = "";
                                }
                                onClicked: {
                                    root.selectedIndex = itemAbsoluteIndex;
                                    root.triggerSessionAction(modelData.key, false);
                                }
                            }
                        }
                    }
                }
            }

            // Error notice banner (if any)
            Text {
                Layout.fillWidth: true
                visible: PowerProfileService.error !== ""
                text: PowerProfileService.error
                color: Colors.critical
                font.pixelSize: 10
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }
        }
    }
}
