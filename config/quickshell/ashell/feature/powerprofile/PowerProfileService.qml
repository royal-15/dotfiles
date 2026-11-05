pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.components

Scope {
    id: root

    property var profiles: []
    property string applyingProfile: ""
    property string error: ""
    property string listOutput: ""
    property string listError: ""
    property string applyError: ""

    function formatAwakeTime(raw) {
        if (!raw)
            return "";
        let str = raw.replace(/^up\s+/, "");
        str = str.replace(/(\d+)\s+days?,?/g, "$1d")
                 .replace(/(\d+)\s+hours?,?/g, "$1h")
                 .replace(/(\d+)\s+minutes?,?/g, "$1m")
                 .replace(/,\s*/g, " ")
                 .trim();
        return str.length > 0 ? str : raw;
    }

    readonly property string uptimeRaw: uptimePoller.value
    readonly property string awakeTime: formatAwakeTime(uptimeRaw)

    function refreshUptime() {
        uptimePoller.trigger();
    }

    function refresh() {
        uptimePoller.trigger();
        if (listProcess.running)
            return;
        listOutput = "";
        listError = "";
        listProcess.running = true;
    }

    function apply(profile) {
        if (!profile || profiles.indexOf(profile) < 0 || applyProcess.running)
            return false;
        applyingProfile = profile;
        applyError = "";
        error = "";
        applyStdout = "";
        applyStderr = "";
        applyProcess.command = ["powerprofilesctl", "set", profile];
        applyProcess.running = true;
        return true;
    }

    function iconFor(profile) {
        if (profile === "power-saver")
            return "energy_savings_leaf";
        if (profile === "balanced")
            return "speed";
        if (profile === "performance")
            return "bolt";
        return "bolt";
    }

    function labelFor(profile) {
        if (profile === "power-saver")
            return "Power saver";
        if (profile === "balanced")
            return "Balanced";
        if (profile === "performance")
            return "Performance";
        return profile.replace(/-/g, " ").replace(/\b\w/g, letter => letter.toUpperCase());
    }

    Process { id: sessionProcess }

    function executeSessionAction(action) {
        if (action === "lock") {
            sessionProcess.command = ["hyprlock"];
            sessionProcess.running = true;
        } else if (action === "logout") {
            sessionProcess.command = ["hyprctl", "dispatch", "exit"];
            sessionProcess.running = true;
        } else if (action === "reboot") {
            sessionProcess.command = ["systemctl", "reboot"];
            sessionProcess.running = true;
        } else if (action === "poweroff") {
            sessionProcess.command = ["systemctl", "poweroff"];
            sessionProcess.running = true;
        }
    }

    function finishList(exitCode) {
        const foundProfiles = [];
        if (exitCode === 0) {
            const lines = listOutput.split(/\r?\n/);
            for (const line of lines) {
                const match = line.match(/^\s*\*?\s*([a-z][a-z0-9-]*):\s*$/);
                if (match && foundProfiles.indexOf(match[1]) < 0)
                    foundProfiles.push(match[1]);
            }
        }

        const preferredOrder = ["power-saver", "balanced", "performance"];
        foundProfiles.sort((a, b) => {
            const aIndex = preferredOrder.indexOf(a);
            const bIndex = preferredOrder.indexOf(b);
            if (aIndex < 0 && bIndex < 0)
                return a.localeCompare(b);
            if (aIndex < 0)
                return 1;
            if (bIndex < 0)
                return -1;
            return aIndex - bIndex;
        });
        profiles = foundProfiles;
        if (exitCode !== 0 || foundProfiles.length === 0) {
            error = listError || "Could not read available power profiles.";
            return;
        }

        error = "";
    }

    function finishApply(exitCode) {
        const target = applyingProfile;
        applyingProfile = "";
        if (exitCode === 0) {
            applyError = "";
            error = "";
            refresh();
        } else {
            applyError = applyStderr.trim() || applyStdout.trim() || `Could not apply ${labelFor(target)}.`;
            error = applyError;
        }
    }

    property string applyStdout: ""
    property string applyStderr: ""

    Process {
        id: listProcess
        command: ["powerprofilesctl", "list"]
        stdout: SplitParser { onRead: data => root.listOutput += data.replace(/[\r\n]+$/, "") + "\n" }
        stderr: SplitParser { onRead: data => root.listError += data.replace(/[\r\n]+$/, "") + "\n" }
        onExited: (exitCode, exitStatus) => root.finishList(exitCode)
    }

    Process {
        id: applyProcess
        command: ["powerprofilesctl", "set", "balanced"]
        stdout: SplitParser { onRead: data => root.applyStdout += data.replace(/[\r\n]+$/, "") + "\n" }
        stderr: SplitParser { onRead: data => root.applyStderr += data.replace(/[\r\n]+$/, "") + "\n" }
        onExited: (exitCode, exitStatus) => root.finishApply(exitCode)
    }

    Poller {
        id: uptimePoller
        command: "uptime -p 2>/dev/null | sed -e 's/^up //'"
        interval: 30000
    }

    Component.onCompleted: refresh()
}
