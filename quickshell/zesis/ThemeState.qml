pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string _home: Quickshell.env("HOME")
    readonly property string _cacheDir: _home + "/.cache/zesis"
    readonly property string _stateFile: _cacheDir + "/state.json"
    readonly property string thumbsDir: _cacheDir + "/thumbs"
    readonly property string _matugenConfigPath: Quickshell.shellDir + "/matugen/config.toml"
    // Sentinel prefix - anything on stderr after this came from the user's own optional
    // matugen template run, not ours, so it can be reported separately without being
    // mistaken for a fatal apply failure.
    readonly property string _templateErrorMarker: "__ZESIS_USER_TEMPLATE_ERROR__"

    property string palette: "dark"
    property string lastWallpaper: ""
    property string schemeType: "scheme-tonal-spot"
    property string wallpaperBackend: "awww"
    property string customWallpaperCommand: ""
    // "" means the default, ~/Pictures/Wallpapers.
    property string wallpapersDirOverride: ""
    readonly property string wallpapersDir: root.wallpapersDirOverride !== "" ? root.wallpapersDirOverride : (root._home + "/Pictures/Wallpapers")
    property bool autoStartWallpaperDaemon: true
    property bool applying: false
    property string lastError: ""
    // Non-fatal: set when our own theming succeeded but the user's own matugen
    // templates (outside our shipped config) failed to run.
    property string lastTemplateWarning: ""
    // Per-monitor overrides: { "DP-1": "/path/to/wall.png", ... }. A monitor with no entry
    // here just shows lastWallpaper.
    property var perMonitorWallpaper: ({})
    // Which monitor's wallpaper drives matugen. "" = the global/all-monitors wallpaper
    property string colorSourceMonitor: ""

    readonly property var wallpaperBackends: [
        {
            id: "awww",
            label: "awww",
            command: "awww img \"$1\" --transition-type fade --transition-duration 1",
            monitorCommand: "awww img \"$1\" --transition-type fade --transition-duration 1 --outputs \"$2\"",
            // Process name of the background daemon this backend talks to, so it can be
            // auto-started if it isn't running yet. "" shrimply means no daemon to manage.
            daemonProcess: "awww-daemon"
        },
        {
            id: "swww",
            label: "swww",
            command: "swww img \"$1\" --transition-type fade --transition-duration 1",
            monitorCommand: "swww img \"$1\" --transition-type fade --transition-duration 1 --outputs \"$2\"",
            daemonProcess: "swww-daemon"
        },
        {
            id: "hyprpaper",
            label: "hyprpaper",
            command: "hyprctl hyprpaper preload \"$1\" && hyprctl hyprpaper wallpaper \",$1\"",
            monitorCommand: "hyprctl hyprpaper preload \"$1\" && hyprctl hyprpaper wallpaper \"$2,$1\"",
            daemonProcess: "hyprpaper"
        },
        {
            id: "feh",
            label: "feh (X11)",
            // feh has no concept of named Wayland outputs, idk what to do here
            command: "feh --bg-fill \"$1\"",
            monitorCommand: "feh --bg-fill \"$1\"",
            daemonProcess: ""
        },
        {
            id: "custom",
            label: "Custom command...",
            command: "",
            monitorCommand: "",
            daemonProcess: ""
        }
    ]

    // Zesis ships its own matugen template. This way we guarantee the theme gets applied
    // when switching wallpapers. After that we attempt to apply the user's own templates.
    // We also surface whatever potential error the user has in their own configuration.
    function _matugenCmd(img, type, mode, cfg) {
        var ours = "matugen -c \"" + cfg + "\" image \"" + img + "\" --source-color-index 0 --type \"" + type + "\" --mode \"" + mode + "\"";
        var theirs = "matugen image \"" + img + "\" --source-color-index 0 --type \"" + type + "\" --mode \"" + mode + "\"";
        var theirsGuarded = "tpl_err=$(" + theirs + " 2>&1 1>/dev/null); tpl_ec=$?; " + "[ \"$tpl_ec\" -ne 0 ] && printf '%s' \"" + root._templateErrorMarker + "$tpl_err\" 1>&2; true";
        return ours + " && (" + theirsGuarded + ")";
    }

    // Matugen likes fancy colors, we hae to strip those, otherwise it's garbage
    // output.
    function _stripAnsi(text) {
        return text.replace(/\x1b\[[0-9;]*m/g, "");
    }

    // monitor is "" for the global/all-monitors wallpaper.
    function _wallpaperSetCmd(monitor) {
        if (root.wallpaperBackend === "custom")
            return root.customWallpaperCommand.trim();
        for (var i = 0; i < root.wallpaperBackends.length; i++) {
            if (root.wallpaperBackends[i].id === root.wallpaperBackend)
                return monitor ? root.wallpaperBackends[i].monitorCommand : root.wallpaperBackends[i].command;
        }
        return monitor ? root.wallpaperBackends[0].monitorCommand : root.wallpaperBackends[0].command;
    }

    Process {
        command: ["mkdir", "-p", root.thumbsDir]
        running: true
    }

    JsonAdapter {
        id: stateData
        property string palette: "dark"
        property string lastWallpaper: ""
        property string schemeType: "scheme-tonal-spot"
        property string wallpaperBackend: "awww"
        property string customWallpaperCommand: ""
        property string wallpapersDirOverride: ""
        property bool autoStartWallpaperDaemon: true
        property var perMonitorWallpaper: ({})
        property string colorSourceMonitor: ""
    }

    FileView {
        path: root._stateFile
        adapter: stateData // qmllint disable missing-type
        onLoaded: {
            root.palette = stateData.palette;
            root.lastWallpaper = stateData.lastWallpaper;
            root.schemeType = stateData.schemeType;
            root.wallpaperBackend = stateData.wallpaperBackend;
            root.customWallpaperCommand = stateData.customWallpaperCommand;
            root.wallpapersDirOverride = stateData.wallpapersDirOverride;
            root.autoStartWallpaperDaemon = stateData.autoStartWallpaperDaemon;
            root.perMonitorWallpaper = stateData.perMonitorWallpaper;
            root.colorSourceMonitor = stateData.colorSourceMonitor;
            root.ensureWallpaperDaemon();
        }
    }

    function ensureWallpaperDaemon() {
        if (!root.autoStartWallpaperDaemon)
            return;
        var proc = "";
        for (var i = 0; i < root.wallpaperBackends.length; i++) {
            if (root.wallpaperBackends[i].id === root.wallpaperBackend) {
                proc = root.wallpaperBackends[i].daemonProcess;
                break;
            }
        }
        if (!proc)
            return;
        daemonCheckProcess._daemonProcess = proc;
        daemonCheckProcess.command = ["pgrep", "-f", proc];
        daemonCheckProcess.running = true;
    }

    Process {
        id: daemonCheckProcess
        property string _daemonProcess: ""
        onExited: code => {
            if (code !== 0 && daemonCheckProcess._daemonProcess)
                Quickshell.execDetached([daemonCheckProcess._daemonProcess]);
        }
    }

    function _effectiveWallpaper(monitor) {
        if (!monitor)
            return root.lastWallpaper;
        return root.perMonitorWallpaper[monitor] || root.lastWallpaper;
    }

    // Sets the wallpaper for every monitor. This overwrites every output at the daemon
    // level, so it also wipes any per-monitor overrides (onExited below) and always
    // recomputes the system color scheme from it.
    function apply(wallpaperPath) {
        root._apply(wallpaperPath, "", true);
    }

    function applyToMonitor(wallpaperPath, monitor) {
        if (!monitor)
            return;
        root._apply(wallpaperPath, monitor, root.colorSourceMonitor === monitor);
    }

    function resetMonitor(monitor) {
        if (!monitor || !(monitor in root.perMonitorWallpaper))
            return;
        var next = Object.assign({}, root.perMonitorWallpaper);
        delete next[monitor];
        root.perMonitorWallpaper = next;
        root._persistState();
        // Re-run the backend command to visually sync the output, but don't let it
        // re-record an override, cause that's what we just cleared. Recolor if this monitor
        // was the color source, since its effective wallpaper just changed back to global0.
        if (root.lastWallpaper !== "")
            root._apply(root.lastWallpaper, monitor, root.colorSourceMonitor === monitor, false);
    }

    // Picks which monitor's wallpaper drives the system color scheme, and immediately
    // recomputes colors from whatever that monitor is currently showing.
    function setColorSourceMonitor(monitor) {
        if (root.colorSourceMonitor === monitor)
            return;
        root.colorSourceMonitor = monitor;
        root._persistState();
        var path = root._effectiveWallpaper(monitor);
        if (path !== "")
            root._recolor(path);
    }

    // Calls queued while one is already running (e.g. a theme applying a
    // different wallpaper to each monitor in turn) instead of being dropped -
    // the backend/matugen commands are one Process at a time, run
    // sequentially.
    property var _queue: []

    function _recolor(path) {
        if (root.applying) {
            root._queue.push({
                kind: "recolor",
                path: path
            });
            return;
        }
        root._runRecolor(path);
    }

    function _runRecolor(path) {
        root.applying = true;
        root.lastError = "";
        root.lastTemplateWarning = "";
        applyProcess._wallpaperPath = path;
        applyProcess._monitor = "";
        applyProcess._persistOverride = false;
        applyProcess.command = ["bash", "-c", root._matugenCmd("$1", "$2", "$3", "$4"), "--", path, root.schemeType, root.palette, root._matugenConfigPath];
        applyProcess.running = true;
    }

    function _apply(wallpaperPath, monitor, recolor, persistOverride = true) {
        if (root.applying) {
            root._queue.push({
                kind: "apply",
                wallpaperPath: wallpaperPath,
                monitor: monitor,
                recolor: recolor,
                persistOverride: persistOverride
            });
            return;
        }
        root._runApply(wallpaperPath, monitor, recolor, persistOverride);
    }

    function _runApply(wallpaperPath, monitor, recolor, persistOverride) {
        root.applying = true;
        root.lastError = "";
        root.lastTemplateWarning = "";
        applyProcess._wallpaperPath = wallpaperPath;
        applyProcess._monitor = monitor;
        applyProcess._persistOverride = persistOverride;
        var setCmd = root._wallpaperSetCmd(monitor);
        var parts = [];
        if (setCmd.length > 0)
            parts.push(setCmd);
        if (recolor)
            parts.push(root._matugenCmd("$1", "$3", "$4", "$5"));
        var script = parts.length > 0 ? parts.join(" && ") : "true";
        applyProcess.command = ["bash", "-c", script, "--", wallpaperPath, monitor, root.schemeType, root.palette, root._matugenConfigPath];
        applyProcess.running = true;
    }

    function _runNextQueued() {
        if (root._queue.length === 0)
            return;
        var next = root._queue.shift();
        if (next.kind === "recolor")
            root._runRecolor(next.path);
        else
            root._runApply(next.wallpaperPath, next.monitor, next.recolor, next.persistOverride);
    }

    function setWallpapersDirOverride(dir) {
        root.wallpapersDirOverride = dir;
        root._persistState();
    }

    function togglePalette() {
        root.palette = (root.palette === "dark" ? "light" : "dark");
        root._persistState();
        var path = root._effectiveWallpaper(root.colorSourceMonitor);
        if (path !== "")
            root._recolor(path);
    }

    Process {
        id: applyProcess
        property string _wallpaperPath: ""
        property string _monitor: ""
        property bool _persistOverride: true

        stderr: StdioCollector {
            id: applyStderr
        }

        onExited: (code, status) => { // qmllint disable signal-handler-parameters
            root.applying = false;
            var stderrText = applyStderr.text;
            var markerIdx = stderrText.indexOf(root._templateErrorMarker);
            if (markerIdx !== -1) {
                root.lastTemplateWarning = root._stripAnsi(stderrText.slice(markerIdx + root._templateErrorMarker.length)).trim();
                stderrText = stderrText.slice(0, markerIdx);
            } else {
                root.lastTemplateWarning = "";
            }
            stderrText = root._stripAnsi(stderrText);
            if (code === 0) {
                if (applyProcess._persistOverride) {
                    if (applyProcess._monitor === "") {
                        root.lastWallpaper = applyProcess._wallpaperPath;
                        // A global apply just overwrote every output at the daemon level,
                        // so any per-monitor overrides we were tracking are stale now.
                        if (Object.keys(root.perMonitorWallpaper).length > 0)
                            root.perMonitorWallpaper = {};
                    } else {
                        var next = Object.assign({}, root.perMonitorWallpaper);
                        next[applyProcess._monitor] = applyProcess._wallpaperPath;
                        root.perMonitorWallpaper = next;
                    }
                }
                root._persistState();
                if (!hookProcess.running)
                    hookProcess.running = true;
            } else {
                root.lastError = stderrText.trim() || ("Command exited with code " + code);
            }
            root._runNextQueued();
        }
    }

    Process {
        id: hookProcess
        command: ["bash", "-c", "hook=\"$1\"; [ -x \"$hook\" ] && exec \"$hook\"", "--", root._home + "/.config/zesis/on-theme-change"]
    }

    Process {
        id: saveProcess
    }

    function _persistState() {
        var json = JSON.stringify({
            palette: root.palette,
            lastWallpaper: root.lastWallpaper,
            schemeType: root.schemeType,
            wallpaperBackend: root.wallpaperBackend,
            customWallpaperCommand: root.customWallpaperCommand,
            wallpapersDirOverride: root.wallpapersDirOverride,
            autoStartWallpaperDaemon: root.autoStartWallpaperDaemon,
            perMonitorWallpaper: root.perMonitorWallpaper,
            colorSourceMonitor: root.colorSourceMonitor
        });
        saveProcess.command = ["bash", "-c", "printf '%s' \"$1\" > \"$2\"", "--", json, root._stateFile];
        saveProcess.running = true;
    }
}
