pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs

Scope {
    id: root

    property var items: []
    property string searchQuery: ""
    property bool isLoading: false
    property bool isSaving: false
    property string pendingSaveData: ""
    property string loadBuffer: ""

    readonly property int totalCount: items.length

    readonly property var filteredItems: {
        const query = (searchQuery || "").trim().toLowerCase();
        if (query === "")
            return items;

        return items.filter(entry => {
            if (!entry)
                return false;
            const labelMatch = entry.label && entry.label.toLowerCase().indexOf(query) !== -1;
            const snippetMatch = entry.snippet && entry.snippet.toLowerCase().indexOf(query) !== -1;
            return labelMatch || snippetMatch;
        });
    }

    readonly property string defaultSeedJson: JSON.stringify([
        {
            "id": "cmd_1",
            "label": "Git: Undo last commit (soft)",
            "snippet": "git reset --soft HEAD~1"
        },
        {
            "id": "cmd_2",
            "label": "Git: Clean untracked files & dirs",
            "snippet": "git clean -fd"
        },
        {
            "id": "cmd_3",
            "label": "Hyprland: Reload compositor config",
            "snippet": "hyprctl reload"
        },
        {
            "id": "cmd_4",
            "label": "System: Top 20 largest files/directories",
            "snippet": "du -ah . | sort -rh | head -n 20"
        },
        {
            "id": "cmd_5",
            "label": "Network: List active listening sockets",
            "snippet": "ss -tulpn"
        },
        {
            "id": "cmd_6",
            "label": "Docker: Multi-stage build & run container",
            "snippet": "docker build -t myapp:latest . && \\\ndocker run --rm -it \\\n  -p 8080:8080 \\\n  myapp:latest"
        },
        {
            "id": "cmd_7",
            "label": "Find & Replace in files recursively",
            "snippet": "find . -type f -name '*.txt' \\\n  -exec sed -i 's/foo/bar/g' {} +"
        },
        {
            "id": "cmd_8",
            "label": "Hyprland: Query active window title & class",
            "snippet": "hyprctl activewindow -j | jq -r '\"\\(.class) - \\(.title)\"'"
        }
    ], null, 2)

    Process {
        id: loadProcess
        command: [
            "sh", "-c",
            'dir=$(dirname "$1"); mkdir -p "$dir"; if [ ! -s "$1" ] && [ -s "$1.bak" ]; then cp -f "$1.bak" "$1" 2>/dev/null || true; fi; if [ ! -s "$1" ]; then printf "%s" "$2" > "$1"; fi; cat "$1"',
            "_", Paths.commandPaletteJson, root.defaultSeedJson
        ]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                root.loadBuffer += data + "\n";
            }
        }
        onStarted: {
            root.isLoading = true;
        }
        onExited: (exitCode, exitStatus) => {
            root.isLoading = false;
            if (exitCode !== 0) {
                console.warn("[CommandPaletteService] Load failed with exit code: " + exitCode);
                root.loadBuffer = "";
                root.recoverFromBackupOrSeed();
                return;
            }

            const raw = root.loadBuffer.trim();
            root.loadBuffer = "";

            if (!raw) {
                root.recoverFromBackupOrSeed();
                return;
            }

            try {
                const parsed = JSON.parse(raw);
                if (Array.isArray(parsed) && parsed.length > 0) {
                    // Normalize items ensuring each has id, label, snippet
                    const sanitized = parsed.map((entry, idx) => ({
                        id: entry.id ? String(entry.id) : ("cmd_" + idx + "_" + Date.now()),
                        label: entry.label ? String(entry.label).trim() : "",
                        snippet: entry.snippet ? String(entry.snippet) : ""
                    })).filter(entry => entry.snippet.length > 0);

                    if (sanitized.length > 0) {
                        root.items = sanitized;
                        return;
                    }
                }
                root.recoverFromBackupOrSeed();
            } catch (e) {
                console.warn("[CommandPaletteService] Failed to parse JSON, falling back to backup or seed: " + e);
                root.recoverFromBackupOrSeed();
            }
        }
    }

    Process {
        id: saveProcess
        onStarted: {
            root.isSaving = true;
        }
        onExited: (exitCode, exitStatus) => {
            root.isSaving = false;
            if (exitCode !== 0) {
                console.warn("[CommandPaletteService] Atomic save failed with exit code: " + exitCode);
            }
            if (root.pendingSaveData !== "") {
                const nextPayload = root.pendingSaveData;
                root.pendingSaveData = "";
                root.executeSave(nextPayload);
            }
        }
    }

    Process {
        id: copyProcess
    }

    function executeSave(payload) {
        saveProcess.command = [
            "sh", "-c",
            'dir=$(dirname "$1"); mkdir -p "$dir" || exit 1; if [ -s "$1" ]; then cp -f "$1" "$1.bak" 2>/dev/null || true; fi; tmp="$1.tmp.$$"; printf "%s" "$2" > "$tmp" && sync "$tmp" 2>/dev/null && mv -f "$tmp" "$1"',
            "_", Paths.commandPaletteJson, payload
        ];
        saveProcess.running = true;
    }

    function triggerSave() {
        const payload = JSON.stringify(root.items, null, 2);
        if (saveProcess.running) {
            root.pendingSaveData = payload;
            return;
        }
        root.pendingSaveData = "";
        executeSave(payload);
    }

    function recoverFromBackupOrSeed() {
        try {
            const seed = JSON.parse(root.defaultSeedJson);
            root.items = seed;
            triggerSave();
        } catch (e) {
            root.items = [];
        }
    }

    function loadData() {
        if (loadProcess.running)
            return;
        root.loadBuffer = "";
        loadProcess.running = true;
    }

    function addEntry(label, snippet) {
        const cleanSnippet = (snippet || "").trim();
        if (!cleanSnippet)
            return "";

        const newId = "cmd_" + Date.now() + "_" + Math.floor(Math.random() * 10000);
        const newItem = {
            id: newId,
            label: (label || "").trim(),
            snippet: cleanSnippet
        };

        const updated = [newItem].concat(root.items);
        root.items = updated;
        triggerSave();
        return newId;
    }

    function updateEntry(id, label, snippet) {
        if (!id)
            return false;
        const targetId = String(id);
        const cleanSnippet = (snippet || "").trim();
        if (!cleanSnippet)
            return false;

        const updated = root.items.map(entry => {
            if (entry && String(entry.id) === targetId) {
                return {
                    id: entry.id,
                    label: (label || "").trim(),
                    snippet: cleanSnippet
                };
            }
            return entry;
        });

        root.items = updated;
        triggerSave();
        return true;
    }

    function deleteEntry(id) {
        if (!id)
            return;
        const targetId = String(id);
        const updated = root.items.filter(entry => entry && String(entry.id) !== targetId);
        root.items = updated;
        triggerSave();
    }

    function copyEntry(entry) {
        if (!entry || !entry.snippet)
            return;
        if (copyProcess.running) {
            copyProcess.running = false;
        }
        copyProcess.command = ["wl-copy", "--", entry.snippet];
        copyProcess.running = true;
    }

    Component.onCompleted: {
        loadData();
    }
}
