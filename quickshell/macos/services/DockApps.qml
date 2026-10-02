pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Io
import "../modules/common"

Singleton {
    id: root

    readonly property string iconsDir: Qt.resolvedUrl("../assets/icons/").toString()
    readonly property string iconScript: Qt.resolvedUrl("../scripts/dock_icon.sh").toString().replace(/^file:\/\//, "")
    readonly property string killScript: Qt.resolvedUrl("../scripts/kill_app.sh").toString().replace(/^file:\/\//, "")

    property var pinned: [
        { name: "Finder", icon: "Finder.png", desktop: "org.gnome.Nautilus", exec: "nautilus", appIds: ["org.gnome.Nautilus", "nautilus"] },
        { name: "Launchpad", icon: "Apps.png", desktop: "macos-launcher", exec: "qs ipc -p /home/revo/.config/quickshell/macos call launchpad toggle", appIds: ["macos-launcher", "Launcher"] },
                { name: "Safari", icon: "Safari.png", desktop: "org.gnome.Pafari", exec: "pafari", appIds: ["org.gnome.Pafari", "pafari"] },
        { name: "Telegram", icon: "Telegram.png", desktop: "org.telegram.desktop", exec: "telegram-desktop", appIds: ["org.telegram.desktop", "telegram-desktop"] },
        { name: "Steam", icon: "Steam.png", desktop: "steam", exec: "steam", appIds: ["steam", "com.valvesoftware.Steam"] },
        { name: "Photos", icon: "Photos.png", desktop: "org.kde.gwenview", exec: "gwenview", appIds: ["org.kde.gwenview", "gwenview"] },
        { name: "iMessage", icon: "im-message.png", desktop: "com.github.eneshecan.Whatsie", exec: "whatsie", appIds: ["com.github.eneshecan.Whatsie", "whatsie"] },
        { name: "Calendar", icon: "Calendar.png", desktop: "org.gnome.Calendar", exec: "gnome-calendar", appIds: ["org.gnome.Calendar"] },
        { name: "Prism Launcher", icon: "Prism Launcher.png", desktop: "org.prismlauncher.PrismLauncher", exec: "prismlauncher", appIds: ["org.prismlauncher.PrismLauncher", "prismlauncher"] },
        { name: "Paragon", icon: "Pargon.png", desktop: "paragon-launcher", exec: "bash /home/revo/.local/share/applications/paragon-launch.sh", appIds: ["paragon-launcher", "paragon_launcher"] },
        { name: "Adobe Premiere Pro 2026", icon: "paragon.png", desktop: "adobe-premiere-pro", exec: "env __NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia WINEDEBUG=-all WINE_LARGE_ADDRESS_AWARE=1 prime-run wine \"/home/revo/PortProton/prefixes/DEFAULT/drive_c/Program Files/Adobe/Adobe Premiere Pro 2026/Adobe Premiere Pro.exe\"", appIds: ["adobe-premiere-pro"] },
        { name: "After Effects", icon: "After Effects.png", desktop: "After Effects", exec: "env \"/home/revo/PortProton/data/scripts/start.sh\" \"/home/revo/Adobe After Effects 2022/Support Files/AfterFX.exe\"", appIds: ["afterfx.exe", "wine", "portproton"] },
        { name: "Zen Browser", icon: "zen-browser.png", desktop: "io.github.zen_browser.zen", exec: "zen-browser", appIds: ["io.github.zen_browser.zen", "zen", "zen-alpha"] },
{ name: "Vesktop", icon: "discord.png", desktop: "dev.vencord.Vesktop", exec: "vesktop --enable-features=UseOzonePlatform,WebRTCPipeWireCapturer --ozone-platform=wayland --disable-features=WebRtcAllowUnifiedPlanSeamlessUpgrade,GpuRasterization --disable-gpu-memory-buffer-video-frames --disable-gpu-compositing", appIds: ["dev.vencord.Vesktop", "vesktop"] },
        { name: "Sung", icon: "spotify-client.png", desktop: "sung", exec: "~/.local/bin/sung", appIds: ["sung"] },
        { name: "VS Code", icon: "code.png", desktop: "code-oss", exec: "code", appIds: ["code-oss", "code", "com.visualstudio.code"] },
        { name: "Terminal", icon: "Terminal.png", desktop: "kitty", exec: "kitty", appIds: ["kitty"] },
        { name: "App Store", icon: "App Store.png", desktop: "pearos-appstore", exec: "pearos-appstore", appIds: ["pearos-appstore"] },
        { name: "System Settings", icon: "System Settings.png", desktop: "systemsettings", exec: "systemsettings", appIds: ["systemsettings", "macos-settings", "pearos-settings", "pearos-settings-app"] },
    ]

    property bool trashEmpty: true

    // ── Downloads stack (IPC + diagnostics) ──
    property bool downloadsOpen: false
    property string stackState: ""
    property var stackOpen: null
    // set by Dock.qml: maps a window class to the icon's local centre "x,y"
    property var iconLocalPos: null

    property var runningApps: []
    readonly property var dockItems: root.pinned.concat(root.runningApps)
    property var _running: []
    property var _iconCache: ({})
    property var darkSet: ({})
    property var tintSet: ({})
    property bool _tintBusy: false
    property string _tintFor: ""
    property bool _iconBusy: false
    property bool _iconDone: false
    property var _iconProc: null
    property string _signature: ""
    property var badgeCounts: ({})
    readonly property string badgeScript: Qt.resolvedUrl("../scripts/badge_reader.sh").toString().replace(/^file:\/\//, "")
    readonly property string minScript: "/home/revo/.config/hypr/scripts/minimize_window.py"
    property var _focusIds: []

    // dock click: probe whether the app has genie-minimized windows, then
    // either restore them (the script focuses the restored window) or activate
    Process {
        id: _restoreProbe
        running: false
        stdout: StdioCollector {
            onStreamFinished: root._onHasMin(text)
        }
    }
    Process {
        id: _restoreProc
        running: false
        stdout: StdioCollector {}
    }

    function _onHasMin(text) {
        const ids = root._focusIds || [];
        if ((text || "").trim() === "1") {
            _restoreProc.running = false;
            _restoreProc.command = ["python3", root.minScript, "clickrestore"].concat(ids);
            _restoreProc.running = true;
            return; // restore brings it back and focuses it
        }
        for (const t of ToplevelManager.toplevels.values) {
            if (ids.includes(t.appId)) {
                if (typeof t.activate === "function") t.activate();
                return;
            }
        }
    }

    function incrementBadge(appId) {
        if (appId in root.badgeCounts) {
            root.badgeCounts[appId] = root.badgeCounts[appId] + 1;
        } else {
            root.badgeCounts[appId] = 1;
        }
        root.badgeCounts = root.badgeCounts;
    }

    function setBadge(appId, count) {
        if (count > 0) {
            root.badgeCounts[appId] = count;
        } else {
            delete root.badgeCounts[appId];
        }
        root.badgeCounts = root.badgeCounts;
    }

    function clearBadge(appId) {
        if (appId in root.badgeCounts) {
            delete root.badgeCounts[appId];
            root.badgeCounts = root.badgeCounts;
        }
    }

    function clearAllBadges() {
        root.badgeCounts = {};
    }

    function badgeFor(appId) {
        return root.badgeCounts[appId] || 0;
    }

    function pinApp(app) {
        // Check if already pinned
        for (const p of root.pinned) {
            if (p.appIds[0] === app.appIds[0]) return;
        }
        root.pinned.push({
            name: app.name,
            icon: app.icon || app.name + ".png",
            desktop: app.desktop || "",
            exec: app.exec || "",
            appIds: app.appIds || [app.name]
        });
        root.pinned = root.pinned;
        // Remove from running apps if present
        root.runningApps = root.runningApps.filter(r => r.appIds[0] !== app.appIds[0]);
    }

    function unpinApp(app) {
        root.pinned = root.pinned.filter(p => p.appIds[0] !== app.appIds[0]);
    }

    function isPinned(appId) {
        for (const p of root.pinned) {
            if (p.appIds.includes(appId)) return true;
        }
        return false;
    }

    function movePinned(fromIndex, toIndex) {
        if (fromIndex === toIndex) return;
        if (fromIndex < 0 || fromIndex >= root.pinned.length) return;
        if (toIndex < 0 || toIndex >= root.pinned.length) return;
        const item = root.pinned[fromIndex];
        const arr = root.pinned.slice();
        arr.splice(fromIndex, 1);
        arr.splice(toIndex, 0, item);
        root.pinned = arr;
    }

    function _scanBadges() {
        if (_badgeProc.running) return;
        _badgeProc.running = true;
    }

    function _onBadgeScanFinished(text) {
        const newBadges = {};
        const lines = text.trim().split("\n");
        for (const line of lines) {
            const parts = line.split("|");
            if (parts.length < 2) continue;
            const windowClass = parts[0].trim().toLowerCase();
            const count = parseInt(parts[1]);
            if (!windowClass || isNaN(count) || count <= 0) continue;

            // Match against pinned apps
            for (const p of root.pinned) {
                const pName = p.name.toLowerCase();
                const exec = (p.exec || "").toLowerCase();
                const desktop = (p.desktop || "").toLowerCase();
                if (windowClass.includes(pName) || pName.includes(windowClass) ||
                    windowClass.includes(exec) || exec.includes(windowClass) ||
                    windowClass.includes(desktop) || desktop.includes(windowClass)) {
                    newBadges[p.appIds[0]] = count;
                    break;
                }
            }

            // Match against running apps
            for (const r of root.runningApps) {
                const rName = r.name.toLowerCase();
                const rExec = (r.exec || "").toLowerCase();
                if (windowClass.includes(rName) || rName.includes(windowClass) ||
                    windowClass.includes(rExec) || rExec.includes(windowClass)) {
                    newBadges[r.appIds[0]] = count;
                    break;
                }
            }
        }
        root.badgeCounts = newBadges;
    }

    function pinnedIcon(appId) {
        for (const p of root.pinned) {
            if (p.appIds.includes(appId)) return p.icon;
        }
        return "";
    }

    function iconSource(icon) {
        if (!icon) return "";
        const isUrl = icon.startsWith("file://") || icon.startsWith("http") || icon.startsWith("image://");
        const base = icon.split("/").pop();
        if (Appearance.iconTintActive && root.tintSet[base] && root._tintFor === root.tintSlug)
            return root.tintDirUrl + base;
        if (Appearance.effectiveIconStyle === "Dark") {
            if (root.darkSet[base])
                return root.iconsDir + "dark/" + base;
        }
        if (isUrl) return icon;
        return root.iconsDir + icon;
    }

    // downloads folder: tinted when a tint colour is active, otherwise the SVG
    function folderSource() {
        const base = "folder-downloads.png";
        if (root.tintDirUrl.length > 0 && root.tintSet[base] && root._tintFor === root.tintSlug)
            return root.tintDirUrl + base;
        return root.iconsDir + "folder-downloads.svg";
    }

    function iconFor(appId) {
        return root._iconCache[appId] || root.pinnedIcon(appId) || "Placeholder.png";
    }

    // The shell's own windows all report appId "org.quickshell".
    // Map them onto the dock entry they belong to so they never show up
    // as a separate "quickshell" icon.
    function _normalizeId(t) {
        const id = t.appId;
        if (!id) return "";
        if (id === "org.quickshell" || id === "quickshell") {
            const title = (t.title || "").toLowerCase().replace(/\s+/g, "");
            if (title.indexOf("systemsettings") !== -1) return "macos-settings";
            return "";
        }
        return id;
    }

    function allRunningIds() {
        const ids = [];
        for (const t of ToplevelManager.toplevels.values) {
            const id = root._normalizeId(t);
            if (id && !ids.includes(id)) ids.push(id);
        }
        return ids;
    }

    function isRunning(appIds) {
        // The launchpad is a shell surface, not an xdg toplevel: mirror its
        // open state so the dock shows it as a running app and stops bouncing.
        if (appIds.includes("macos-launcher")) return ShellController.launcherOpen;
        for (const id of appIds) {
            if (root._running.includes(id)) return true;
        }
        return false;
    }

    function focusApp(appIds) {
        for (const id of appIds) {
            root.clearBadge(id);
        }
        if (appIds.includes("macos-launcher")) {
            ShellController.toggle("launcher");
            return;
        }
        root._focusIds = appIds.slice();
        _restoreProbe.running = false;
        _restoreProbe.command = ["python3", root.minScript, "hasmin"].concat(appIds);
        _restoreProbe.running = true;
    }

    function quitApp(appIds) {
        for (const t of ToplevelManager.toplevels.values) {
            if (appIds.includes(t.appId)) {
                if (typeof t.close === "function") t.close();
            }
        }
    }

    function forceKillApp(appIds) {
        _killProc.command = ["bash", root.killScript].concat(appIds);
        _killProc.running = true;
    }

    function _friendlyName(id) {
        const seg = id.split(".").pop();
        return seg.charAt(0).toUpperCase() + seg.slice(1).replace(/[-_]/g, " ");
    }

    function _resolveIcons() {
        if (root._iconBusy) return;
        for (const item of root.runningApps) {
            const id = item.appIds[0];
            if (!(id in root._iconCache) || root._iconCache[id] === null) {
                root._iconCache[id] = null;
                root._requestIcon(id);
                return;
            }
        }
    }

    function _requestIcon(id) {
        if (root._iconBusy) return;
        root._iconBusy = true;
        const cmd = root.iconScript + " '" + id.replace(/'/g, "'\\''") + "'";
        root._iconProc = Qt.createQmlObject(`
            import Quickshell.Io
            Process {
                command: ${JSON.stringify(["bash", "-c", cmd])}
                running: true
                stdout: StdioCollector {
                    onStreamFinished: root._iconResolved(${JSON.stringify(id)}, text)
                }
            }`, root, "iconProc");
        _iconFailSafe.restart();
    }

    function _iconResolved(id, text) {
        if (root._iconDone) return;
        root._iconDone = true;
        if (root._iconProc) {
            root._iconProc.destroy();
            root._iconProc = null;
        }
        root._iconBusy = false;
        const path = text.trim();
        if (path) {
            for (const item of root.runningApps) {
                const it = item.appIds[0];
                if (root._iconCache[it] === null && path) {
                    root._iconCache[it] = "file://" + path;
                    root.runningApps = root._buildExtras();
                    break;
                }
            }
        } else {
            root._iconCache[id] = "";
        }
        root._iconDone = false;
        _iconFailSafe.stop();
        root._resolveIcons();
    }

    Timer {
        id: _iconFailSafe
        interval: 8000
        repeat: false
        onTriggered: {
            if (root._iconBusy) {
                root._iconBusy = false;
                root._resolveIcons();
            }
        }
    }

    function _buildExtras() {
        const extras = [];
        for (const id of root._running) {
            if (root.pinnedIcon(id)) continue;
            extras.push({
                name: root._friendlyName(id),
                icon: root.pinnedIcon(id) || root._iconCache[id] || "Placeholder.png",
                exec: id,
                appIds: [id],
                running: true
            });
        }
        return extras;
    }

    function refresh() {
        const ids = [];
        for (const t of ToplevelManager.toplevels.values) {
            const id = root._normalizeId(t);
            if (id && !ids.includes(id)) ids.push(id);
        }
        root._running = ids;

        const extras = root._buildExtras();

        const sig = extras.map(e => e.appIds[0]).join("|");
        if (sig !== root._signature) {
            root._signature = sig;
            root.runningApps = extras;
            root._resolveIcons();
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Timer {
        id: _badgeTimer
        interval: 2000
        running: true
        repeat: true
        onTriggered: root._scanBadges()
    }

    Process {
        id: _badgeProc
        running: false
        command: ["bash", root.badgeScript]
        stdout: StdioCollector {
            onStreamFinished: root._onBadgeScanFinished(text)
        }
    }

    Process {
        id: _killProc
        running: false
        stdout: StdioCollector {}
    }

    // index of assets/icons/dark so the "Dark" icon style can swap in
    // the themed variant of every icon that has one.
    Process {
        id: _darkScan
        running: true
        command: ["bash", "-c", "ls -1 " + root.iconsDir.replace(/^file:\/\//, "") + "dark 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = {};
                text.split("\n").forEach(function (l) {
                    const n = l.trim();
                    if (n) m[n] = true;
                });
                root.darkSet = m;
                console.log("ICON_DARK_SET " + Object.keys(m).length);
            }
        }
    }

    function checkTrash() {
        _trashCheckProc.running = true;
    }

    // Bake tinted artwork into assets/icons/tinted/<colour>/ with Python
    // (~2s, only the first time a colour is used) so tinted icons keep their
    // detail instead of being flattened by a runtime effect.
    readonly property string tintScript: Qt.resolvedUrl("../scripts/tint_icons.py").toString().replace(/^file:\/\//, "")
    readonly property string tintRoot: Qt.resolvedUrl("../assets/icons/tinted/").toString().replace(/^file:\/\//, "")
    readonly property url tintRootUrl: Qt.resolvedUrl("../assets/icons/tinted/")
    property string _tintBusyHex: ""

    // colour in use: the icon colour while Tinted, otherwise the folder colour
    readonly property string tintHex: {
        if (Appearance.iconTintActive)
            return String(Appearance.iconTint)
        const f = String(Appearance.folderColor || "")
        return f.length > 0 ? f : ""
    }
    readonly property string tintSlug: tintHex.replace("#", "").toLowerCase()
    readonly property string tintDirUrl: tintHex.length > 0 ? tintRootUrl.toString() + tintSlug + "/" : ""
    readonly property string tintDir: tintHex.length > 0 ? tintRoot + tintSlug + "/" : ""

    function _scheduleTint() {
        _tintTimer.restart();
    }

    function _runTint() {
        if (root.tintHex.length === 0) {
            root.tintSet = {};
            root._tintFor = "";
            return;
        }
        if (root._tintBusy) return;
        const hex = root.tintHex;
        if (root.tintSlug.length > 0 && root.tintSlug === root._tintFor && Object.keys(root.tintSet).length > 0)
            return;
        const plain = root.iconsDir.replace(/^file:\/\//, "");
        const dirs = plain + ":" + plain + "dark:" + plain + "light";
        // one folder per colour: bake only when that colour was never baked,
        // so switching to an already prepared colour is instant.
        root._tintBusy = true;
        root._tintBusyHex = hex;
        _tintProc.command = ["bash", "-c",
            "D='" + root.tintDir + "'; " +
            "if [ ! -f \"$D/.tint\" ]; then " +
            "nice -n 5 python3 '" + root.tintScript + "' '" + hex + "' '" + dirs + "' \"$D\"; " +
            "fi; ls -1 \"$D\" 2>/dev/null"];
        _tintProc.running = true;
    }

    Timer {
        id: _tintTimer
        interval: 350
        onTriggered: root._runTint()
    }

    Process {
        id: _tintProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const m = {};
                text.split("\n").forEach(function (l) {
                    const n = l.trim();
                    if (n) m[n] = true;
                });
                root.tintSet = m;
                root._tintFor = root._tintBusyHex.replace("#", "").toLowerCase();
                root._tintBusy = false;
                console.log("ICON_TINT_SET " + Object.keys(m).length + " " + root._tintFor);
                if (root.tintSlug !== root._tintFor)
                    root._scheduleTint();
            }
        }
    }

    Connections {
        target: Appearance
        function onIconTintChanged() { root._scheduleTint(); }
        function onFolderColorChanged() { root._scheduleTint(); }
        function onEffectiveIconStyleChanged() { root._scheduleTint(); }
    }

    Process {
        id: _trashCheckProc
        running: false
        command: ["bash", "-c", "ls -1 ~/.local/share/Trash/files/ 2>/dev/null | head -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.trashEmpty = text.trim().length === 0;
            }
        }
    }

    Timer {
        id: _trashTimer
        interval: 3000
        running: true
        repeat: true
        onTriggered: root.checkTrash()
    }

    Connections {
        target: Notifications
        function onNotify(n) {
            var appName = (n.appName || "").toLowerCase();
            if (appName.length === 0) return;

            // Check pinned apps
            for (const p of root.pinned) {
                var pName = p.name.toLowerCase();
                var exec = (p.exec || "").toLowerCase();
                var desktop = (p.desktop || "").toLowerCase();
                if (appName.includes(pName) || pName.includes(appName) ||
                    appName.includes(exec) || exec.includes(appName) ||
                    appName.includes(desktop) || desktop.includes(appName)) {
                    root.incrementBadge(p.appIds[0]);
                    return;
                }
            }

            // Check running (non-pinned) apps
            for (const r of root.runningApps) {
                var rName = r.name.toLowerCase();
                var rExec = (r.exec || "").toLowerCase();
                if (appName.includes(rName) || rName.includes(appName) ||
                    appName.includes(rExec) || rExec.includes(appName)) {
                    root.incrementBadge(r.appIds[0]);
                    return;
                }
            }
        }
    }

    Component.onCompleted: {
        root.refresh();
        root._scanBadges();
        root._scheduleTint();
    }
}
