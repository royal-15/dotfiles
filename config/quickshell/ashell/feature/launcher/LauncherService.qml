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
        const filtered = [];

        for (let i = 0; i < rawList.length; i++) {
            const entry = rawList[i];
            if (!entry || entry.noDisplay || !entry.name || entry.name.trim() === "")
                continue;
            entry._normName = (entry.name || "").toLowerCase();
            entry._normGeneric = (entry.genericName || "").toLowerCase();
            entry._normComment = (entry.comment || "").toLowerCase();
            entry._normId = (entry.id || "").toLowerCase();
            entry._normKeywords = (entry.keywords && Array.isArray(entry.keywords))
                ? entry.keywords.map(k => (k || "").toLowerCase())
                : [];
            filtered.push(entry);
        }

        filtered.sort((a, b) => {
            return (a._normName || "").localeCompare(b._normName || "");
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
        }
    }

    function getRecentApplications(limit = 8) {
        if (!recentAppIds || recentAppIds.length === 0) {
            return allApplications.slice(0, limit);
        }

        const result = [];
        const seenIds = new Set();

        for (let i = 0; i < recentAppIds.length; i++) {
            const id = recentAppIds[i];
            const app = allApplications.find(a => a.id === id);
            if (app && !seenIds.has(app.id)) {
                result.push(app);
                seenIds.add(app.id);
                if (result.length >= limit)
                    break;
            }
        }

        if (result.length < limit) {
            for (let i = 0; i < allApplications.length; i++) {
                const app = allApplications[i];
                if (!seenIds.has(app.id)) {
                    result.push(app);
                    seenIds.add(app.id);
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
            const name = app._normName || "";
            const generic = app._normGeneric || "";
            const comment = app._normComment || "";
            const id = app._normId || "";
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
            } else if (app._normKeywords && app._normKeywords.length > 0) {
                for (let k = 0; k < app._normKeywords.length; k++) {
                    if (app._normKeywords[k].includes(q)) {
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

    Component.onCompleted: {
        refreshApplications();
        loadRecentProcess.running = true;
    }
}
