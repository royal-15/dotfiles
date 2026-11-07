import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs
import qs.components
import qs.feature.bar
import qs.feature.notifications

Item {
    id: root

    property bool isClearingAll: false
    property bool isCurrentTab: false
    signal closeRequested()

    implicitWidth: 360
    implicitHeight: 500

    Timer {
        id: cascadeClearTimer
        repeat: false
        onTriggered: {
            NotificationService.clearAll();
            root.isClearingAll = false;
        }
    }

    function startCascadeClear() {
        if (NotificationService.notificationCount === 0 || isClearingAll)
            return;
        isClearingAll = true;
        const count = notifListView.count;
        for (let i = 0; i < count; i++) {
            const item = notifListView.itemAtIndex(i);
            if (item && typeof item.dismissWithDelay === "function") {
                item.dismissWithDelay(i * 35);
            }
        }
        cascadeClearTimer.interval = (count * 35) + Motion.durationFast + 50;
        cascadeClearTimer.restart();
    }

    function dismissTopNotification() {
        if (NotificationService.notificationCount === 0 || isClearingAll)
            return;
        const item = notifListView.itemAtIndex(0);
        if (item && typeof item.dismissCard === "function") {
            item.dismissCard(1);
        } else if (NotificationService.serverTrackedNotifications && NotificationService.serverTrackedNotifications.values) {
            const list = NotificationService.serverTrackedNotifications.values;
            if (list.length > 0 && list[0] && typeof list[0].dismiss === "function") {
                list[0].dismiss();
            }
        }
    }

    function markAllChecked() {
        NotificationService.markAllAsChecked();
    }

    function focusKeyboardTarget() {
        if (!isCurrentTab)
            return;
        panelFocusScope.forceActiveFocus();
    }

    function handleKey(event) {
        if (event.key === Qt.Key_Escape) {
            root.closeRequested();
            return true;
        }
        const hasModifier = (event.modifiers & (Qt.ControlModifier | Qt.AltModifier)) !== 0;
        if (!hasModifier) {
            if (event.key === Qt.Key_C) {
                root.startCascadeClear();
                return true;
            }
            if (event.key === Qt.Key_D) {
                NotificationService.toggleDnd();
                return true;
            }
            if (event.key === Qt.Key_Backspace || event.key === Qt.Key_Delete) {
                if (event.modifiers & Qt.ShiftModifier) {
                    root.startCascadeClear();
                } else {
                    root.dismissTopNotification();
                }
                return true;
            }
        }
        return false;
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
            anchors.margins: 10
            spacing: 8

            // Header
            NotificationCenterHeader {
                Layout.fillWidth: true
                count: NotificationService.notificationCount
                onClearAllRequested: root.startCascadeClear()
            }

            // Notification List or Empty State
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ListView {
                    id: notifListView
                    anchors.fill: parent
                    spacing: 8
                    clip: true
                    visible: NotificationService.notificationCount > 0 || root.isClearingAll
                    model: NotificationService.serverTrackedNotifications

                    add: Transition {
                        ParallelAnimation {
                            NumberAnimation {
                                property: "opacity"
                                from: 0
                                to: 1
                                duration: Motion.durationNormal
                                easing.type: Motion.easingStandard
                            }
                            NumberAnimation {
                                property: "x"
                                from: 40
                                to: 0
                                duration: Motion.durationNormal
                                easing.type: Motion.easingStandard
                            }
                        }
                    }

                    displaced: Transition {
                        NumberAnimation {
                            property: "y"
                            duration: Motion.durationNormal
                            easing.type: Motion.easingStandard
                        }
                    }

                    delegate: NotificationCard {
                        required property var modelData
                        width: notifListView.width
                        isToast: false
                        notification: modelData
                        onDismissed: {
                            if (modelData && typeof modelData.dismiss === "function")
                                modelData.dismiss();
                        }
                    }
                }

                // Apple-Inspired Centered Quiet Empty State View
                ColumnLayout {
                    id: emptyStateLayout
                    anchors.centerIn: parent
                    spacing: 8
                    visible: NotificationService.notificationCount === 0 && !root.isClearingAll
                    opacity: visible ? 1.0 : 0.0
                    scale: visible ? 1.0 : 0.94

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Motion.durationNormal
                            easing.type: Motion.easingStandard
                        }
                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: Motion.durationNormal
                            easing.type: Motion.easingBounce
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "notifications_none"
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 32
                        color: Colors.textFaint
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "No Notifications"
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        color: Colors.textDim
                    }
                }
            }
        }
    }
}
