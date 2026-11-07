pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs

Scope {
    id: root

    property var allApplications: []
    property var recentAppIds: []
    property bool isLoaded: false

    Process {
        id: saveRecentProcess
    }

    Process {
        id: loadRecentProcess
        command: ["sh", "-c", "cat ~/.cache/ashell_launcher_recent.json 2>/dev/null || echo '[]'"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    const parsed = JSON.parse(data.trim());
                    if (Array.isArray(parsed)) {
                        root.recentAppIds = parsed;
                    }
                } catch (e) {
                    root.recentAppIds = [];
                }
            }
        }
    }

    function refreshApplications() {
        const appsModel = DesktopEntries.applications;
        const rawList = (appsModel && appsModel.values) ? appsModel.values : [];
        if (!rawList || rawList.length === 0)
            return;

        const filtered = [];

        for (let i = 0; i < rawList.length; i++) {
            const entry = rawList[i];
            if (!entry || entry.noDisplay)
                continue;

            const name = (entry.name || "").trim();
            if (name === "")
                continue;

            const generic = (entry.genericName || "").trim();
            const comment = (entry.comment || "").trim();
            const id = (entry.id || "").trim();
            const icon = entry.icon || "";

            let normKeywords = [];
            if (entry.keywords) {
                if (Array.isArray(entry.keywords)) {
                    normKeywords = entry.keywords.map(k => (k || "").toLowerCase().trim()).filter(k => k.length > 0);
                } else if (typeof entry.keywords === "string") {
                    normKeywords = entry.keywords.split(";").map(k => k.toLowerCase().trim()).filter(k => k.length > 0);
                }
            }

            const appItem = {
                rawEntry: entry,
                id: id,
                name: name,
                genericName: generic,
                comment: comment,
                icon: icon,
                normName: name.toLowerCase(),
                normGeneric: generic.toLowerCase(),
                normComment: comment.toLowerCase(),
                normId: id.toLowerCase(),
                normKeywords: normKeywords,
                execute: () => {
                    if (typeof entry.execute === "function") {
                        entry.execute();
                    }
                }
            };
            filtered.push(appItem);
        }

        filtered.sort((a, b) => {
            return (a.normName || "").localeCompare(b.normName || "");
        });

        allApplications = filtered;
        isLoaded = true;
    }

    function recordLaunch(appId) {
        if (!appId)
            return;

        const current = recentAppIds.filter(id => id !== appId);
        current.unshift(appId);
        const trimmed = current.slice(0, 12);
        recentAppIds = trimmed;

        // Persist recent applications asynchronously
        if (saveRecentProcess.running) {
            saveRecentProcess.terminate();
        }
        const jsonStr = JSON.stringify(trimmed);
        saveRecentProcess.command = [
            "sh",
            "-c",
            `mkdir -p ~/.cache && cat <<'EOF' > ~/.cache/ashell_launcher_recent.json\n${jsonStr}\nEOF`
        ];
        saveRecentProcess.running = true;
    }

    function launch(entry) {
        if (!entry)
            return;

        recordLaunch(entry.id);
        if (typeof entry.execute === "function") {
            entry.execute();
        } else if (entry.rawEntry && typeof entry.rawEntry.execute === "function") {
            entry.rawEntry.execute();
        }
    }

    function getRecentApplications(limit = 8) {
        if (!allApplications || allApplications.length === 0) {
            return [];
        }

        if (!recentAppIds || recentAppIds.length === 0) {
            return allApplications.slice(0, limit);
        }

        const result = [];
        const seenIds = {};

        for (let i = 0; i < recentAppIds.length; i++) {
            const id = recentAppIds[i];
            const app = allApplications.find(a => a.id === id);
            if (app && !seenIds[app.id]) {
                result.push(app);
                seenIds[app.id] = true;
                if (result.length >= limit)
                    break;
            }
        }

        if (result.length < limit) {
            for (let i = 0; i < allApplications.length; i++) {
                const app = allApplications[i];
                if (!seenIds[app.id]) {
                    result.push(app);
                    seenIds[app.id] = true;
                    if (result.length >= limit)
                        break;
                }
            }
        }

        return result;
    }

    function search(query) {
        if (!query || query.trim() === "") {
            return getRecentApplications(10);
        }

        const q = query.trim().toLowerCase();
        const scored = [];

        for (let i = 0; i < allApplications.length; i++) {
            const app = allApplications[i];
            const name = app.normName || "";
            const generic = app.normGeneric || "";
            const comment = app.normComment || "";
            const id = app.normId || "";
            let score = 0;

            if (name === q) {
                score = 1000;
            } else if (name.startsWith(q)) {
                score = 500 - name.length;
            } else if (name.includes(" " + q)) {
                score = 300;
            } else if (name.includes(q)) {
                score = 200;
            } else if (generic.startsWith(q)) {
                score = 150;
            } else if (generic.includes(q)) {
                score = 120;
            } else if (id.startsWith(q)) {
                score = 100;
            } else if (comment.includes(q)) {
                score = 70;
            } else if (app.normKeywords && app.normKeywords.length > 0) {
                for (let k = 0; k < app.normKeywords.length; k++) {
                    if (app.normKeywords[k].includes(q)) {
                        score = 80;
                        break;
                    }
                }
            }

            if (score > 0) {
                // Boost recently used apps slightly
                if (recentAppIds.includes(app.id)) {
                    score += 25;
                }
                scored.push({ app: app, score: score });
            }
        }

        scored.sort((a, b) => {
            if (b.score !== a.score)
                return b.score - a.score;
            return (a.app.name || "").localeCompare(b.app.name || "");
        });

        return scored.map(item => item.app);
    }

    Connections {
        target: DesktopEntries
        function onApplicationsChanged() {
            root.refreshApplications();
        }
    }

    Connections {
        target: DesktopEntries.applications
        function onValuesChanged() {
            root.refreshApplications();
        }
    }

    Timer {
        id: initRetryTimer
        interval: 300
        repeat: true
        running: root.allApplications.length === 0
        triggeredOnStart: true
        onTriggered: {
            root.refreshApplications();
            if (root.allApplications.length > 0) {
                initRetryTimer.running = false;
            }
        }
    }

    Component.onCompleted: {
        refreshApplications();
        loadRecentProcess.running = true;
    }
}
