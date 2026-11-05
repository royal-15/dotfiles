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
            spacing: 0

        // Header
        NotificationCenterHeader {
            Layout.fillWidth: true
            count: NotificationService.notificationCount
            onClearAllRequested: root.startCascadeClear()
        }

        // Divider line
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Colors.border
        }

        // Notification List or Empty State
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: notifListView
                anchors.fill: parent
                anchors.margins: 12
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

            // Empty State View
            ColumnLayout {
                id: emptyStateLayout
                anchors.centerIn: parent
                spacing: 10
                visible: NotificationService.notificationCount === 0 && !root.isClearingAll
                opacity: visible ? 1.0 : 0.0
                scale: visible ? 1.0 : 0.92

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
                    text: "notifications_paused"
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 36
                    color: Colors.textDim
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "No Notifications"
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    color: Colors.textDim
                }
            }
        }
    }
}
}
