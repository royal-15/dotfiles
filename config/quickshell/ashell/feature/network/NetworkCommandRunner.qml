pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    property var queue: []
    property var currentRequest: null
    property string stdoutText: ""
    property string stderrText: ""
    property bool timedOut: false

    function execute(owner, radio, command) {
        queue = queue.concat([{ owner: owner, radio: radio, command: command }]);
        startNext();
    }

    function cancelOwner(owner) {
        queue = queue.filter((request) => request.owner !== owner);
        if (currentRequest && currentRequest.owner === owner) {
            currentRequest = { owner: null, radio: currentRequest.radio, command: currentRequest.command };
            return [currentRequest.radio];
        }
        return [];
    }

    function startNext() {
        if (process.running || currentRequest || queue.length === 0)
            return;
        const nextQueue = queue.slice();
        currentRequest = nextQueue.shift();
        queue = nextQueue;
        stdoutText = "";
        stderrText = "";
        timedOut = false;
        process.command = currentRequest.command;
        process.running = true;
        commandTimeout.restart();
    }

    function finish(exitCode) {
        commandTimeout.stop();
        killTimeout.stop();
        const request = currentRequest;
        currentRequest = null;
        if (request && request.owner)
            request.owner.handleCommandExit(request.radio, exitCode, stdoutText, timedOut ? "Command timed out." : stderrText.trim());
        startNext();
    }

    Timer {
        id: commandTimeout
        interval: 30000
        repeat: false
        onTriggered: {
            if (process.running) {
                root.timedOut = true;
                killTimeout.restart();
                process.running = false;
            }
        }
    }

    Timer {
        id: killTimeout
        interval: 1500
        repeat: false
        onTriggered: if (process.running) process.signal(9)
    }

    Process {
        id: process
        stdout: SplitParser { onRead: data => root.stdoutText += data.replace(/[\r\n]+$/, "") + "\n" }
        stderr: SplitParser { onRead: data => root.stderrText += data.replace(/[\r\n]+$/, "") + "\n" }
        onExited: (exitCode, exitStatus) => root.finish(exitCode)
    }
}
