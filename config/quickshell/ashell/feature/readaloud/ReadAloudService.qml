pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs

QtObject {
    id: root

    property bool _isPlaying: false
    readonly property bool isPlaying: _isPlaying
    readonly property bool isBusy: _isPlaying || proc.running
    property real audioLevel: 0.0
    property string voiceModel: ""
    property string statusText: isPlaying ? "Reading..." : "Idle"
    property string lastError: ""

    signal playbackStarted()
    signal playbackFinished()
    signal errorOccurred(string error)

    property Process stopProcess: Process {
        id: stopProc
        command: [Paths.readSelectionsBin, "--stop"]
        running: false
    }

    property Process ttsProcess: Process {
        id: proc
        command: root.voiceModel !== "" ? [Paths.readSelectionsBin, root.voiceModel] : [Paths.readSelectionsBin]
        running: false

        stdout: SplitParser {
            onRead: data => {
                const line = data.trim();
                if (line === "")
                    return;

                if (line.startsWith("LEVEL:")) {
                    const levelVal = parseFloat(line.substring(6));
                    if (!isNaN(levelVal))
                        root.audioLevel = Math.max(0.0, Math.min(1.0, levelVal));
                } else if (line === "STATUS:started") {
                    root._isPlaying = true;
                    root.playbackStarted();
                } else if (line === "STATUS:finished") {
                    root.audioLevel = 0.0;
                    root._isPlaying = false;
                    root.playbackFinished();
                } else if (line.startsWith("ERROR:")) {
                    const err = line.substring(6);
                    root.lastError = err;
                    root.audioLevel = 0.0;
                    root._isPlaying = false;
                    root.errorOccurred(err);
                }
            }
        }

        stderr: SplitParser {
            onRead: data => {
                const trimmed = data.trim();
                if (trimmed !== "")
                    console.warn("[ReadAloudService:stderr] " + trimmed);
            }
        }

        onExited: (exitCode, exitStatus) => {
            root._isPlaying = false;
            root.audioLevel = 0.0;
            if (exitCode !== 0 && root.lastError === "") {
                root.lastError = `exit_code_${exitCode}`;
                root.errorOccurred(root.lastError);
            } else if (exitCode === 0) {
                root.playbackFinished();
            }
        }

        onRunningChanged: {
            if (!running) {
                root._isPlaying = false;
                root.audioLevel = 0.0;
            }
        }
    }

    function start(modelOverride) {
        lastError = "";
        if (typeof modelOverride === "string" && modelOverride !== "")
            voiceModel = modelOverride;

        // Mutual exclusion: stop any active session first
        if (isBusy) {
            stop();
        }

        audioLevel = 0.0;
        proc.command = root.voiceModel !== "" ? [Paths.readSelectionsBin, root.voiceModel] : [Paths.readSelectionsBin];
        proc.running = true;
    }

    function stop() {
        if (proc.running) {
            proc.running = false;
        }
        stopProc.running = true;
        _isPlaying = false;
        audioLevel = 0.0;
        playbackFinished();
    }

    function toggle(modelOverride) {
        if (isBusy)
            stop();
        else
            start(modelOverride);
    }

    function status() {
        return _isPlaying ? "playing" : "idle";
    }
}
