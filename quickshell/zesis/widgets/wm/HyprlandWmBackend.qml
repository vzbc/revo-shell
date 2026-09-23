import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

QtObject {
    id: root

    property bool _hasHyprshutdown: false

    property QtObject _hyprshutdownCheck: Process {
        command: ["sh", "-c", "which hyprshutdown >/dev/null 2>&1"]
        running: true
        onExited: code => root._hasHyprshutdown = (code === 0)
    }

    readonly property var workspaces: Hyprland.workspaces.values
    readonly property var toplevels: Hyprland.toplevels.values
    readonly property var focusedMonitor: Hyprland.focusedMonitor

    function activeWorkspaceFor(screen) {
        return Hyprland.monitorFor(screen)?.activeWorkspace ?? null;
    }

    function focusWorkspace(id) {
        Hyprland.dispatch("hl.dsp.focus({ workspace = " + id + " })");
    }

    function focusWindow(addr) {
        Hyprland.dispatch("hl.dsp.focus({ window = \"address:" + addr + "\" })");
    }

    function moveWindow(addr, wsId) {
        Hyprland.dispatch("hl.dsp.window.move({ workspace = " + wsId + ", window = \"address:" + addr + "\" })");
    }

    function moveWindowSilent(addr, wsId) {
        Hyprland.dispatch("hl.dsp.window.move({ workspace = " + wsId + ", window = \"address:" + addr + "\", follow = false })");
    }

    function moveWindowToName(addr, name) {
        Hyprland.dispatch("hl.dsp.window.move({ workspace = \"name:" + name + "\", window = \"address:" + addr + "\", follow = false })");
    }

    function focusWindowByPid(pid) {
        var toplevels = Hyprland.toplevels.values;
        var best = null;
        var bestScore = -1;
        for (var i = 0; i < toplevels.length; i++) {
            var obj = toplevels[i].lastIpcObject;
            if (obj && obj["pid"] == pid) {
                var score = obj["focusHistoryID"] ?? 0;
                if (score > bestScore) {
                    bestScore = score;
                    best = obj;
                }
            }
        }
        if (best)
            Hyprland.dispatch("hl.dsp.focus({ window = \"address:" + best["address"] + "\" })");
    }

    function focusWindowByClass(cls) {
        var toplevels = Hyprland.toplevels.values;
        for (var i = 0; i < toplevels.length; i++) {
            var obj = toplevels[i].lastIpcObject;
            if (obj && (obj["class"] ?? "").toLowerCase() === cls.toLowerCase()) {
                Hyprland.dispatch("hl.dsp.focus({ window = \"address:" + obj["address"] + "\" })");
                return;
            }
        }
    }

    function preselect(dir) {
        Hyprland.dispatch("hl.dsp.layout(\"preselect " + dir + "\")");
    }

    function refreshToplevels() {
        Hyprland.refreshToplevels();
    }

    function refreshWorkspaces() {
        Hyprland.refreshWorkspaces();
    }

    function refreshMonitors() {
        Hyprland.refreshMonitors();
    }

    function logout() {
        if (root._hasHyprshutdown)
            Quickshell.execDetached(["hyprshutdown"]);
        else
            Hyprland.dispatch("hl.dsp.exit()");
    }

    function closeAppsThen(cmd) {
        if (root._hasHyprshutdown)
            Quickshell.execDetached(["hyprshutdown", "--post-cmd", cmd]);
        else
            Quickshell.execDetached(["bash", "-c", cmd]);
    }
}
