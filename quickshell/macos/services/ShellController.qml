pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Singleton {
    id: root

    property bool spotlightOpen: false
    property bool controlCenterOpen: false
    property bool sessionOpen: false
    property bool aboutOpen: false
    property bool forceQuitOpen: false
    property bool locked: false
    property string pendingConfirm: ""

    signal openRequested(string name)

    Component.onCompleted: root.run("hyprctl eval 'hl.config({plugin={hyprbars={enabled=true}}})'")
    Component.onDestruction: root.run("hyprctl eval 'hl.config({plugin={hyprbars={enabled=false}}})'")

    function isOpen(name) {
        if (name === "spotlight") return root.spotlightOpen;
        if (name === "controlcenter") return root.controlCenterOpen;
        if (name === "session") return root.sessionOpen;
        if (name === "forcequit") return root.forceQuitOpen;
        return false;
    }

    function closeAll(except) {
        if (except !== "spotlight") root.spotlightOpen = false;
        if (except !== "controlcenter") root.controlCenterOpen = false;
        if (except !== "session") root.sessionOpen = false;
        if (except !== "forcequit") root.forceQuitOpen = false;
        root.pendingConfirm = "";
    }

    function toggle(name) {
        if (root.locked) return;
        const currentlyOpen = root.isOpen(name);
        root.closeAll(name);
        if (name === "spotlight") root.spotlightOpen = !currentlyOpen;
        else if (name === "controlcenter") root.controlCenterOpen = !currentlyOpen;
        else if (name === "session") root.sessionOpen = !currentlyOpen;
    }

    function openForceQuit() {
        if (root.locked) return;
        root.closeAll();
        root.forceQuitOpen = true;
    }

    // Actions that ask for confirmation first (like macOS)
    function requestAction(name) {
        if (name === "restart" || name === "shutdown" || name === "logout") {
            root.closeAll();
            root.pendingConfirm = name;
            return;
        }
        root.action(name);
    }

    function confirmPending() {
        const name = root.pendingConfirm;
        root.pendingConfirm = "";
        if (name) root.action(name);
    }

    function cancelPending() {
        root.pendingConfirm = "";
    }

    function lock() {
        root.closeAll();
        root.locked = true;
        root.openRequested("lock");
    }

    function unlock() {
        root.locked = false;
        root.openRequested("unlock");
    }

    function openAbout() {
        root.closeAll();
        root.aboutOpen = true;
    }

    function run(cmd) {
        _runner.command = ["bash", "-c", cmd];
        _runner.running = true;
    }

    Process {
        id: _runner
        running: false
        stdout: StdioCollector {}
        stderr: StdioCollector {}
    }

    function action(name) {
        if (name === "lock") { root.lock(); return; }
        if (name === "unlock") { root.unlock(); return; }
        if (name === "logout") {
            // hyprctl dispatch exit is unavailable on this lua build; end the
            // graphical logind session of the current user instead.
            root.run("loginctl terminate-session $(loginctl list-sessions --no-legend 2>/dev/null | awk '$3==\"'$(whoami)'\" && $4!=\"-\" {print $1}' | head -1)");
            return;
        }
        if (name === "sleep") { root.run("systemctl suspend"); return; }
        if (name === "restart") { root.run("systemctl reboot"); return; }
        if (name === "shutdown") { root.run("systemctl poweroff"); return; }
        root.toggle(name);
    }

    function handleCommand(cmd) {
        cmd = (cmd || "").trim();
        if (!cmd) return;
        if (cmd === "closeall") { root.closeAll(); return; }
        if (cmd === "lock") { root.lock(); return; }
        if (cmd === "unlock") { root.unlock(); return; }
        if (cmd === "forcequit") { root.openForceQuit(); return; }
        if (cmd === "minimizeActive") {
            const tl = ToplevelManager.activeToplevel;
            console.log("[minimizeActive] tl:", tl, tl ? tl.title : "none");
            if (tl) tl.minimized = true;
            return;
        }
        root.action(cmd);
    }

    Timer {
        id: _pollTimer
        interval: 250
        running: true
        repeat: true
        onTriggered: {
            if (!_cmdProc.running) _cmdProc.running = true;
        }
    }

    Process {
        id: _cmdProc
        running: false
        // mv instead of rm: rename() works in sticky /tmp even when the file
        // is owned by another user, so a stale command can never loop.
        command: ["bash", "-c",
            "if [ -f /tmp/macos_cmd ]; then cat /tmp/macos_cmd; mv -f /tmp/macos_cmd /tmp/.macos_cmd_done 2>/dev/null || true; fi"]
        stdout: StdioCollector {
            onStreamFinished: {
                _cmdProc.running = false;
                const cmd = text.trim();
                if (cmd && cmd !== root.lastCmd) { root.lastCmd = cmd; root.handleCommand(cmd); }
            }
        }
    }

    property string lastCmd: ""
}
