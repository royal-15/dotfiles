pragma Singleton

import QtQuick
import Quickshell

Scope {
    id: root

    property var registrations: []
    property bool isSwitching: false
    readonly property bool anyPanelActive: isSwitching || registrations.some(entry => entry.panel && ((entry.panel.isOpen !== undefined) ? entry.panel.isOpen : entry.panel.visible))

    function registerPanel(screen, panel) {
        if (!screen || !panel)
            return;
        const updated = registrations.filter(entry => entry.panel !== panel);
        updated.push({ screen: screen, panel: panel });
        registrations = updated;
    }

    function unregisterPanel(panel) {
        registrations = registrations.filter(entry => entry.panel !== panel);
    }

    function openPanel(panel, argument) {
        if (!panel)
            return;
        const entry = registrations.find(candidate => candidate.panel === panel);
        if (!entry) {
            panel.openNow(argument);
            return;
        }

        isSwitching = true;
        try {
            // Immediate switch: cleanly dismiss any active sibling panel before opening target
            const siblings = registrations.filter(candidate => candidate.screen === entry.screen && candidate.panel !== panel && ((candidate.panel.isOpen !== undefined) ? candidate.panel.isOpen : candidate.panel.visible));
            siblings.forEach(candidate => {
                if (candidate.panel.closeImmediate !== undefined)
                    candidate.panel.closeImmediate();
                else if (!candidate.panel.closingWithAnimation)
                    candidate.panel.requestClose();
            });

            panel.openNow(argument);
        } finally {
            isSwitching = false;
        }
    }
}
