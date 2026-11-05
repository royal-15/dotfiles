pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import qs
import qs.feature.bar
import qs.feature.network
import qs.feature.powerprofile

Scope {
    id: root

    property bool dndEnabled: false
    property int unreadCount: 0
    property bool anyPanelOpen: false
    property bool isToastHovered: false
    property bool isInitialized: false
    property int nextToastId: 0

    readonly property var serverTrackedNotifications: notifServer.trackedNotifications
    readonly property int notificationCount: (notifServer.trackedNotifications && notifServer.trackedNotifications.values)
        ? notifServer.trackedNotifications.values.length
        : 0

    readonly property ListModel activeToastListModel: toastModel

    ListModel {
        id: toastModel
    }

    NotificationServer {
        id: notifServer
        keepOnReload: true
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true

        onNotification: notif => {
            if (!notif)
                return;

            notif.tracked = true;

            // If notification is carried over from a previous generation across shell reload,
            // keep it tracked in Notification Center history, but suppress toast popups.
            if (notif.lastGeneration)
                return;

            root.unreadCount += 1;

            const isCritical = notif.urgency === NotificationUrgency.Critical || notif.urgency === 2;

            // In DND mode or if a panel is open, silence non-critical heads-up toasts
            if ((root.dndEnabled || root.anyPanelOpen) && !isCritical)
                return;

            // Maintain max 3 visible toasts
            if (toastModel.count >= 3) {
                toastModel.remove(toastModel.count - 1);
            }

            const tid = ++root.nextToastId;
            toastModel.insert(0, {
                toastId: tid,
                notifObj: notif
            });
        }
    }

    Timer {
        id: startupGuardTimer
        interval: 3000
        running: true
        repeat: false
        onTriggered: {
            root.isInitialized = true;
            // Initialize baseline states for telemetry monitors
            root.prevBatteryPct = parseInt(StatusBarService.batteryPercent, 10);
            root.prevCharging = StatusBarService.isAcConnected;
            root.prevWifiActive = StatusBarService.activeConnection;
            root.prevPowerProfile = StatusBarService.powerProfile;
        }
    }

    function removeToastByIndex(index) {
        if (index >= 0 && index < toastModel.count) {
            toastModel.remove(index);
        }
    }

    function removeToast(target) {
        if (target === undefined || target === null)
            return;
        for (let i = 0; i < toastModel.count; i++) {
            const item = toastModel.get(i);
            if (!item)
                continue;
            if ((typeof target === "number" && item.toastId === target) ||
                (typeof target === "object" && (item.notifObj === target || item.toastId === target.toastId))) {
                toastModel.remove(i);
                break;
            }
        }
    }

    function clearToastsSilently() {
        toastModel.clear();
    }

    function dismissNotification(id) {
        // Remove from toast stack if present
        for (let i = 0; i < toastModel.count; i++) {
            const item = toastModel.get(i);
            if (item && item.notifObj && item.notifObj.id === id) {
                toastModel.remove(i);
                break;
            }
        }

        // Dismiss in server
        if (notifServer.trackedNotifications && notifServer.trackedNotifications.values) {
            const list = notifServer.trackedNotifications.values;
            for (let i = 0; i < list.length; i++) {
                if (list[i] && list[i].id === id) {
                    list[i].dismiss();
                    break;
                }
            }
        }

        if (root.unreadCount > 0)
            root.unreadCount -= 1;
    }

    function markAllAsChecked() {
        root.unreadCount = 0;
    }

    function clearAll() {
        toastModel.clear();
        if (notifServer.trackedNotifications && notifServer.trackedNotifications.values) {
            const list = [...notifServer.trackedNotifications.values];
            for (let i = 0; i < list.length; i++) {
                if (list[i] && typeof list[i].dismiss === "function") {
                    list[i].dismiss();
                }
            }
        }
        root.unreadCount = 0;
    }

    function toggleDnd() {
        root.dndEnabled = !root.dndEnabled;
        if (root.dndEnabled) {
            // Dismiss active non-critical toasts
            for (let i = toastModel.count - 1; i >= 0; i--) {
                const item = toastModel.get(i);
                if (item && item.notifObj && item.notifObj.urgency !== NotificationUrgency.Critical && item.notifObj.urgency !== 2) {
                    toastModel.remove(i);
                }
            }
        }
    }

    // Context-Aware Feedback Dispatcher
    Process {
        id: feedbackProcess
    }

    function dispatchFeedback(appName, summary, body, urgency = "normal") {
        feedbackProcess.command = ["notify-send", "-a", appName, "-u", urgency, summary, body];
        feedbackProcess.running = true;
    }

    // Telemetry Monitors with Context-Aware Suppression
    property int prevBatteryPct: -1
    property bool prevCharging: false
    property string prevWifiActive: ""
    property string prevPowerProfile: ""

    // 1. Battery Telemetry Monitor
    Connections {
        target: StatusBarService

        function onBatteryPercentChanged() {
            if (!root.isInitialized)
                return;
            const pct = parseInt(StatusBarService.batteryPercent, 10);
            if (isNaN(pct) || pct <= 0)
                return;

            const isDischarging = !StatusBarService.isAcConnected;

            if (isDischarging) {
                // Low Battery: 15%
                if (pct <= 15 && pct > 5 && (root.prevBatteryPct > 15 || root.prevBatteryPct === -1)) {
                    root.dispatchFeedback("Battery", "Battery Low", `${pct}% remaining — consider plugging in.`, "normal");
                }
                // Critical Battery: 5%
                else if (pct <= 5 && (root.prevBatteryPct > 5 || root.prevBatteryPct === -1)) {
                    root.dispatchFeedback("Battery", "Battery Critical", `${pct}% remaining — plug in immediately to prevent shutdown.`, "critical");
                }
            }
            root.prevBatteryPct = pct;
        }

        function onIsAcConnectedChanged() {
            if (!root.isInitialized)
                return;

            const isAc = StatusBarService.isAcConnected;
            const pct = StatusBarService.batteryPercent;

            // Context-Aware check: suppress if PowerProfilePanel is open
            const powerPanel = PowerProfileRouter.panelForFocusedMonitor();
            const panelOpen = powerPanel && powerPanel.visible;

            if (!panelOpen) {
                if (isAc && !root.prevCharging) {
                    root.dispatchFeedback("Battery", "AC Connected", pct !== "" ? (StatusBarService.isCharging ? `Battery charging at ${pct}%.` : `Connected to power (${pct}%).`) : "AC power connected.", "low");
                } else if (!isAc && root.prevCharging) {
                    root.dispatchFeedback("Battery", "AC Disconnected", pct !== "" ? `Running on battery (${pct}%).` : "On battery power.", "low");
                }
            }
            root.prevCharging = isAc;
        }

        // 2. Network Telemetry Monitor
        function onActiveConnectionChanged() {
            if (!root.isInitialized)
                return;

            const current = StatusBarService.activeConnection;

            // Context-Aware check: suppress if NetworkCenter is open
            const netPanel = NetworkCenterRouter.panelForFocusedMonitor();
            const panelOpen = netPanel && netPanel.visible;

            if (!panelOpen && root.prevWifiActive !== current) {
                if (root.prevWifiActive !== "" && current === "") {
                    root.dispatchFeedback("Network", "Wi-Fi Disconnected", "Connection lost.", "normal");
                } else if (current !== "") {
                    root.dispatchFeedback("Network", "Wi-Fi Connected", `Connected to ${current}.`, "low");
                }
            }
            root.prevWifiActive = current;
        }

        // 3. Power Profile External Change Monitor
        function onPowerProfileChanged() {
            if (!root.isInitialized)
                return;

            const current = StatusBarService.powerProfile;
            const powerPanel = PowerProfileRouter.panelForFocusedMonitor();
            const panelOpen = powerPanel && powerPanel.visible;

            if (!panelOpen && root.prevPowerProfile !== "" && root.prevPowerProfile !== current) {
                const label = current.charAt(0).toUpperCase() + current.slice(1);
                root.dispatchFeedback("System", "Power Profile", `Switched to ${label} mode.`, "low");
            }
            root.prevPowerProfile = current;
        }
    }
}
