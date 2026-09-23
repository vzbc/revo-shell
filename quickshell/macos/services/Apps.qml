pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var apps: []
    property var appsById: ({})
    property bool ready: false

    function refresh() {
        const list = [];
        const byId = {};
        for (const e of DesktopEntries.applications.values) {
            if (e.noDisplay) continue;
            const name = e.name || e.id || "";
            if (!name) continue;
            const entry = {
                name: name,
                id: e.id || "",
                icon: Quickshell.iconPath(e.icon || "", "image-missing"),
                exec: e.execString || "",
                category: e.genericName || ""
            };
            list.push(entry);
            if (entry.id) byId[entry.id] = entry;
        }
        list.sort((a, b) => a.name.localeCompare(b.name));
        root.apps = list;
        root.appsById = byId;
        root.ready = true;
    }

    function search(query) {
        query = (query || "").trim().toLowerCase();
        if (!query) return root.apps;
        const out = [];
        for (const a of root.apps) {
            if (a.name.toLowerCase().includes(query) ||
                (a.id || "").toLowerCase().includes(query) ||
                (a.category || "").toLowerCase().includes(query)) {
                out.push(a);
            }
        }
        return out;
    }

    function launch(execString) {
        const cleaned = (execString || "").replace(/[ \t]+%\w/g, "").trim();
        if (!cleaned) return;
        _launcher.command = ["bash", "-c", "setsid -f " + cleaned + " >/dev/null 2>&1"];
        _launcher.running = true;
    }

    function launchById(id) {
        const entry = root.appsById[id];
        if (entry) root.launch(entry.exec);
    }

    Process {
        id: _launcher
        running: false
        stdout: StdioCollector {}
        stderr: StdioCollector {}
    }

    Connections {
        target: DesktopEntries
        function onApplicationsChanged() {
            root.refresh();
        }
    }

    Component.onCompleted: {
        // DesktopEntries loads asynchronously; refresh once it becomes available.
        if (DesktopEntries.applications.values.length > 0) {
            root.refresh();
        }
    }
}
