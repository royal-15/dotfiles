pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

Scope {
    id: root

    property var registrations: []
    property bool pendingOpen: false
    property string targetStage: "hub"

    function registerPanel(screen, panel) {
        if (!screen || !panel)
            return;

        const updated = registrations.filter(entry => entry.screen !== screen && entry.panel !== panel);
        updated.push({ screen: screen, panel: panel });
        registrations = updated;

        if (pendingOpen) {
            const target = panelForFocusedMonitor();
            if (target) {
                pendingOpen = false;
                target.openStage(targetStage);
            }
        }
    }

    function unregisterPanel(panel) {
        registrations = registrations.filter(entry => entry.panel !== panel);
    }

    function panelForFocusedMonitor() {
        const focusedMonitor = Hyprland.focusedMonitor;
        if (focusedMonitor) {
            const entry = registrations.find(candidate => candidate.panel && Hyprland.monitorFor(candidate.screen) === focusedMonitor);
            if (entry && entry.panel)
                return entry.panel;
        }

        const screens = Quickshell.screens;
        if (screens.length > 0) {
            const entry = registrations.find(candidate => candidate.panel && candidate.screen === screens[0]);
            if (entry && entry.panel)
                return entry.panel;
        }

        if (registrations.length > 0 && registrations[0].panel)
            return registrations[0].panel;

        return null;
    }

    function open(stage) {
        const target = stage ? stage : "hub";
        targetStage = target;
        const panel = panelForFocusedMonitor();
        if (panel && (!panel.isOpen || panel.closingWithAnimation)) {
            panel.openStage(target);
        } else if (panel && panel.isOpen) {
            panel.setStage(target);
        } else {
            pendingOpen = true;
        }
    }

    function close() {
        const panel = panelForFocusedMonitor();
        if (panel && panel.isOpen && !panel.closingWithAnimation)
            panel.requestClose();
    }

    function toggle(stage) {
        const target = stage ? stage : "hub";
        const panel = panelForFocusedMonitor();
        if (panel) {
            if (panel.isOpen && !panel.closingWithAnimation) {
                panel.requestClose();
            } else {
                targetStage = target;
                panel.openStage(target);
            }
        } else {
            pendingOpen = true;
            targetStage = target;
        }
    }
}
