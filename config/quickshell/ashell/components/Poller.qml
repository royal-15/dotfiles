import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    property string command: ""
    property int interval: 3000
    property string value: ""

    function trigger() {
        if (!proc.running)
            proc.running = true;
    }

    Process {
        id: proc

        command: ["sh", "-c", root.command]
        running: true

        stdout: StdioCollector {
            id: stdoutCollector
            onStreamFinished: {
                const trimmed = stdoutCollector.text.trim();
                if (root.value !== trimmed)
                    root.value = trimmed;
            }
        }

    }

    Timer {
        interval: root.interval
        running: true
        repeat: true
        onTriggered: {
            if (!proc.running)
                proc.running = true;
        }
    }

}
