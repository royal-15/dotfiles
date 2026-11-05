pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    property var items: []
    property string searchQuery: ""
    property bool isLoading: false
    property string listBuffer: ""

    readonly property int totalCount: items.length

    readonly property var filteredItems: {
        const query = (searchQuery || "").trim().toLowerCase();
        if (query === "")
            return items;

        return items.filter(entry => {
            if (!entry)
                return false;
            return entry.previewLower.indexOf(query) !== -1 || entry.id.indexOf(query) !== -1;
        });
    }

    Process {
        id: listProcess
        command: ["cliphist", "list"]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                root.listBuffer += data + "\n";
            }
        }
        onStarted: {
            root.isLoading = true;
        }
        onExited: (exitCode, exitStatus) => {
            root.isLoading = false;
            if (exitCode !== 0) {
                root.listBuffer = "";
                return;
            }

            const raw = root.listBuffer;
            root.listBuffer = "";

            const lines = raw.split("\n");
            const parsed = [];

            for (let i = 0; i < lines.length; i++) {
                const line = lines[i];
                if (!line || line.trim() === "")
                    continue;

                const tabIdx = line.indexOf("\t");
                if (tabIdx === -1)
                    continue;

                const idStr = line.substring(0, tabIdx).trim();
                const preview = line.substring(tabIdx + 1);
                const isBinary = preview.startsWith("[[ binary data");

                parsed.push({
                    id: idStr,
                    rawLine: line,
                    preview: preview,
                    previewLower: preview.toLowerCase(),
                    isBinary: isBinary,
                    index: parsed.length + 1
                });
            }

            root.items = parsed;
        }
    }

    Process {
        id: copyProcess
    }

    Process {
        id: deleteProcess
    }

    Process {
        id: wipeProcess
        onExited: (exitCode, exitStatus) => {
            root.items = [];
            root.searchQuery = "";
        }
    }

    function refresh() {
        if (listProcess.running)
            return;
        root.listBuffer = "";
        listProcess.running = true;
    }

    function copyItem(entry) {
        if (!entry || !entry.id)
            return;

        // Decode item from cliphist and copy to wl-clipboard
        copyProcess.command = ["sh", "-c", `cliphist decode "${entry.id}" | wl-copy`];
        copyProcess.running = true;
    }

    function deleteItem(entry) {
        if (!entry || !entry.rawLine)
            return;

        // Optimistically remove from active in-memory list for instant feedback
        const targetId = entry.id;
        root.items = root.items.filter(item => item.id !== targetId);

        // Remove from cliphist database asynchronously
        deleteProcess.command = ["sh", "-c", 'printf "%s\n" "$1" | cliphist delete', "_", entry.rawLine];
        deleteProcess.running = true;
    }

    function wipe() {
        if (wipeProcess.running)
            return;

        // Optimistically clear in-memory list
        root.items = [];
        root.searchQuery = "";

        // Reset cliphist database
        wipeProcess.command = ["sh", "-c", "cliphist wipe && rm -f \"$HOME/.cache/cliphist/db\""];
        wipeProcess.running = true;
    }

    Component.onCompleted: {
        refresh();
    }
}
