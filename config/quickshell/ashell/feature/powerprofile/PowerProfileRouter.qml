pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

Scope {
    id: root

    property var registrations: []
    property bool pendingOpen: false

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
                target.openForKeyboard();
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
            return entry ? entry.panel : null;
        }

        const screens = Quickshell.screens;
        if (screens.length > 0) {
            const entry = registrations.find(candidate => candidate.panel && candidate.screen === screens[0]);
            return entry ? entry.panel : null;
        }
        return null;
    }

    function open() {
        const panel = panelForFocusedMonitor();
        if (panel && panel.visible && !panel.closingWithAnimation)
            panel.requestClose();
        else if (panel)
            panel.openForKeyboard();
        else
            pendingOpen = true;
    }
}
