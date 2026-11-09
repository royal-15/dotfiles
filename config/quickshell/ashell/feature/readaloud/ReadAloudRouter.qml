pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs
import qs.feature.readaloud

Scope {
    id: root

    property var registrations: []

    function registerOsd(screen, osd) {
        if (!screen || !osd)
            return;

        const updated = registrations.filter(entry => entry.screen !== screen && entry.osd !== osd);
        updated.push({ screen: screen, osd: osd });
        registrations = updated;
    }

    function unregisterOsd(osd) {
        registrations = registrations.filter(entry => entry.osd !== osd);
    }

    function osdForFocusedMonitor() {
        const focusedMonitor = Hyprland.focusedMonitor;
        if (focusedMonitor) {
            const entry = registrations.find(candidate => candidate.osd && Hyprland.monitorFor(candidate.screen) === focusedMonitor);
            if (entry)
                return entry.osd;
        }

        const screens = Quickshell.screens;
        if (screens.length > 0) {
            const entry = registrations.find(candidate => candidate.osd && candidate.screen === screens[0]);
            if (entry)
                return entry.osd;
        }

        return registrations.length > 0 ? registrations[0].osd : null;
    }

    function start(modelOverride) {
        const osd = osdForFocusedMonitor();
        if (osd && !osd.isOpen)
            osd.show();
        ReadAloudService.start(modelOverride);
    }

    function stop() {
        ReadAloudService.stop();
        for (let i = 0; i < registrations.length; i++) {
            if (registrations[i].osd && registrations[i].osd.isOpen)
                registrations[i].osd.dismiss();
        }
    }

    function toggle(modelOverride) {
        if (ReadAloudService.isBusy)
            stop();
        else
            start(modelOverride);
    }

    Connections {
        target: ReadAloudService

        function onPlaybackStarted() {
            const osd = root.osdForFocusedMonitor();
            if (osd && !osd.isOpen)
                osd.show();
        }

        function onPlaybackFinished() {
            for (let i = 0; i < root.registrations.length; i++) {
                if (root.registrations[i].osd && root.registrations[i].osd.isOpen)
                    root.registrations[i].osd.dismiss();
            }
        }

        function onErrorOccurred(error) {
            for (let i = 0; i < root.registrations.length; i++) {
                if (root.registrations[i].osd && root.registrations[i].osd.isOpen)
                    root.registrations[i].osd.dismiss();
            }
        }
    }
}
