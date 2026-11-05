pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

Scope {
    id: root

    property var registrations: []
    property string pendingTab: ""

    Timer {
        interval: 100
        repeat: true
        running: root.pendingTab !== "" && root.registrations.length > 0
        onTriggered: root.dispatchPendingTab()
    }

    Timer {
        interval: 20000
        repeat: true
        running: root.registrations.some((entry) => entry.panel && entry.panel.visible && !entry.panel.closingWithAnimation)
        onTriggered: {
            const entry = root.registrations.find((candidate) => candidate.panel && candidate.panel.visible && !candidate.panel.closingWithAnimation);
            if (!entry)
                return;
            if (entry.panel.activeTab === "wifi" && !entry.panel.wifiBusy)
                entry.panel.refreshWifi();
            else if (entry.panel.activeTab === "bluetooth" && !entry.panel.bluetoothBusy)
                entry.panel.refreshBluetooth();
        }
    }

    function registerPanel(screen, panel) {
        if (!screen || !panel)
            return;

        const updated = registrations.filter((entry) => entry.screen !== screen && entry.panel !== panel);
        updated.push({ screen: screen, panel: panel });
        registrations = updated;

        dispatchPendingTab();
    }

    function dispatchPendingTab() {
        if (!pendingTab)
            return;

        const targetPanel = panelForFocusedMonitor();
        if (!targetPanel)
            return;

        const requestedTab = pendingTab;
        pendingTab = "";
        targetPanel.openForKeyboard(requestedTab);
    }

    function unregisterPanel(panel) {
        registrations = registrations.filter((entry) => entry.panel !== panel);
    }

    function panelForFocusedMonitor() {
        const focusedMonitor = Hyprland.focusedMonitor;
        if (focusedMonitor) {
            const focusedRegistration = registrations.find((entry) => entry.panel && Hyprland.monitorFor(entry.screen) === focusedMonitor);
            return focusedRegistration ? focusedRegistration.panel : null;
        }

        const screens = Quickshell.screens;
        if (screens.length > 0) {
            const firstScreenRegistration = registrations.find((entry) => entry.panel && entry.screen === screens[0]);
            return firstScreenRegistration ? firstScreenRegistration.panel : null;
        }

        return null;
    }

    function open(tab) {
        const panel = panelForFocusedMonitor();
        if (panel) {
            if (panel.visible && !panel.closingWithAnimation && panel.activeTab === tab) {
                panel.requestClose();
                return;
            }
            panel.openForKeyboard(tab);
        } else {
            pendingTab = tab;
            dispatchPendingTab();
        }
    }
}
