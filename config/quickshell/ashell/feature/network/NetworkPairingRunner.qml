pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    property var owner: null
    property string address: ""
    property bool launchCommand: false
    property int timeoutMs: 45000

    function start(requestOwner, deviceAddress) {
        if (process.running || owner)
            return false;
        owner = requestOwner;
        address = deviceAddress;
        launchCommand = true;
        pairingTimeout.restart();
        process.running = true;
        return true;
    }

    function isRunning(requestOwner) {
        return owner === requestOwner && process.running;
    }

    function write(requestOwner, input) {
        if (owner === requestOwner && process.running)
            process.write(input);
    }

    function cancel(requestOwner, deviceAddress) {
        if (owner !== requestOwner)
            return;
        pairingTimeout.stop();
        if (process.running) {
            process.write("cancel-pairing " + deviceAddress + "\n");
            process.write("quit\n");
            killTimeout.restart();
        }
    }

    function cancelOwner(requestOwner) {
        if (owner !== requestOwner)
            return false;
        pairingTimeout.stop();
        if (process.running) {
            process.write("cancel-pairing " + address + "\n");
            process.write("quit\n");
            killTimeout.restart();
        } else {
            killTimeout.stop();
        }
        owner = null;
        address = "";
        return true;
    }

    function finish(exitCode) {
        pairingTimeout.stop();
        killTimeout.stop();
        const completedOwner = owner;
        owner = null;
        address = "";
        if (completedOwner)
            completedOwner.handlePairingExit(exitCode);
    }

    Timer {
        id: pairingTimeout
        interval: root.timeoutMs
        repeat: false
        onTriggered: if (root.owner) root.owner.handlePairingTimeout()
    }

    Timer {
        id: killTimeout
        interval: 1500
        repeat: false
        onTriggered: if (process.running) process.signal(9)
    }

    Process {
        id: process
        command: ["bluetoothctl", "--agent", "KeyboardDisplay"]
        stdinEnabled: true
        stdout: SplitParser { onRead: data => { if (root.owner) root.owner.handlePairingOutput(data) } }
        stderr: SplitParser { onRead: data => { if (root.owner) root.owner.handlePairingOutput(data) } }
        onRunningChanged: {
            if (running && root.launchCommand) {
                root.launchCommand = false;
                process.write("default-agent\n");
                process.write("pair " + root.address + "\n");
            }
        }
        onExited: (exitCode, exitStatus) => root.finish(exitCode)
    }
}
