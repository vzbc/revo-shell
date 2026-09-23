pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Per-role overrides on top of the wallpaper-generated theme, kept separately
// for the dark and light palettes so switching modes picks the matching set
// up. A role that isn't in the map falls back to the generated theme, which
// is the default and what every existing config gets.
//
// Where an override lives depends on `scope`:
// - "wallpaper" (default): overrides are kept per wallpaper path, so
//   swapping wallpapers swaps in whatever was saved for that specific image.
//   The path used as the key is whichever wallpaper is actually driving the
//   color scheme right now - ThemeState.colorSourceMonitor's effective
//   wallpaper, not necessarily the global one, since this system supports
//   picking a different monitor's wallpaper as the color source.
// - "global": a single override set applies no matter which wallpaper is
//   active.
// Switching scope doesn't move or merge anything - it just changes which
// bucket reads/writes target, so flipping back and forth is non-destructive.
Singleton {
    id: root

    readonly property string _configDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/zesis"
    readonly property string _configPath: _configDir + "/coloroverrides.json"

    // Roles that exist in the generated theme (colors.json), in the order the
    // palette preview in the wallpaper panel shows them.
    readonly property var paletteRoles: [
        {
            id: "background",
            label: "bg",
            desc: "Panel and bar background"
        },
        {
            id: "surface_container",
            label: "surface",
            desc: "Cards, rows, popups"
        },
        {
            id: "surface_container_high",
            label: "surf+",
            desc: "Raised chips and inputs"
        },
        {
            id: "outline_variant",
            label: "border",
            desc: "Panel outlines"
        },
        {
            id: "primary",
            label: "primary",
            desc: "Accent: highlights, active state"
        },
        {
            id: "primary_fixed_dim",
            label: "p.dim",
            desc: "Dimmed accent"
        },
        {
            id: "primary_container",
            label: "p.cont",
            desc: "Accent-tinted fills"
        },
        {
            id: "on_primary",
            label: "on-p",
            desc: "Text drawn on the accent"
        },
        {
            id: "on_background",
            label: "text",
            desc: "Primary text"
        },
        {
            id: "on_surface_variant",
            label: "dim",
            desc: "Muted / secondary text"
        }
    ]

    // "bar" is not a theme role - it only exists as an override, so the bar can
    // be recolored without dragging every other panel's background with it.
    readonly property var roles: paletteRoles.concat([
        {
            id: "bar",
            label: "bar",
            desc: "Bar only, defaults to bg"
        }
    ])

    // Override system
    property bool enabled: true

    // "wallpaper" or "global" - which bucket set()/clear()/get() target.
    property string scope: "wallpaper"

    // Every wallpaper's override set, keyed by its absolute path (whatever
    // ThemeState._effectiveWallpaper(ThemeState.colorSourceMonitor) holds).
    // "" is the bucket used before any wallpaper has ever been applied.
    property var byWallpaper: ({})

    // The single override set used when scope === "global".
    property var global: ({
            dark: {},
            light: {}
        })

    // The wallpaper actually driving the color scheme right now - not
    // necessarily the global one, since a specific monitor can be picked as
    // the color source (see ThemeState.colorSourceMonitor).
    function _currentWallpaper() {
        return ThemeState._effectiveWallpaper(ThemeState.colorSourceMonitor);
    }

    readonly property var _current: root.scope === "global" ? root.global : (root.byWallpaper[root._currentWallpaper()] || {})
    // Authoritative in memory, not bound to the adapter: the file write is
    // async, so reading edits back off disk would lose any change made before
    // the previous one landed. Disk only feeds back in via _adopt().
    readonly property var dark: root._current.dark || {}
    readonly property var light: root._current.light || {}

    function setScope(newScope) {
        if (newScope !== "wallpaper" && newScope !== "global")
            return;
        root.scope = newScope;
        root._persist();
    }

    function setEnabled(v) {
        if (root.enabled === v)
            return;
        root.enabled = v;
        root._persist();
    }

    function forPalette(palette) {
        return palette === "dark" ? root.dark : root.light;
    }

    function get(palette, role) {
        var map = root.forPalette(palette);
        var v = map ? map[role] : "";
        return (v && root.isValid(v)) ? v : "";
    }

    function isOverridden(palette, role) {
        return root.get(palette, role).length > 0;
    }

    function set(palette, role, hex) {
        if (!root.isValid(hex))
            return;
        var entry = root._copyEntry();
        var target = palette === "dark" ? entry.dark : entry.light;
        target[role] = hex.trim().toLowerCase();
        root._saveEntry(entry);
    }

    function clear(palette, role) {
        var entry = root._copyEntry();
        delete (palette === "dark" ? entry.dark : entry.light)[role];
        root._saveEntry(entry);
    }

    function clearPalette(palette) {
        var entry = root._copyEntry();
        if (palette === "dark")
            entry.dark = {};
        else
            entry.light = {};
        root._saveEntry(entry);
    }

    function isValid(hex) {
        return /^#([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/.test((hex || "").trim());
    }

    function _copyEntry() {
        var e = root.scope === "global" ? root.global : root.byWallpaper[root._currentWallpaper()];
        return {
            dark: e && e.dark ? root._copy(e.dark) : {},
            light: e && e.light ? root._copy(e.light) : {}
        };
    }

    function _copy(map) {
        return map ? JSON.parse(JSON.stringify(map)) : ({});
    }

    function _saveEntry(entry) {
        if (root.scope === "global") {
            root.global = entry;
        } else {
            var all = root._copy(root.byWallpaper);
            all[root._currentWallpaper()] = entry;
            root.byWallpaper = all;
        }
        root._persist();
    }

    // A single writer, with the latest state queued behind whatever is in
    // flight - assigning to a running Process would drop the write.
    property string _pendingJson: ""

    function _persist() {
        root._pendingJson = JSON.stringify({
            enabled: root.enabled,
            scope: root.scope,
            byWallpaper: root.byWallpaper,
            global: root.global
        });
        root._flush();
    }

    function _flush() {
        if (writeProc.running || root._pendingJson.length === 0)
            return;
        var json = root._pendingJson;
        root._pendingJson = "";
        writeProc.command = ["bash", "-c", "mkdir -p \"$1\" && printf '%s' \"$2\" > \"$3\"", "--", root._configDir, json, root._configPath];
        writeProc.running = true;
    }

    // Pick the file up on startup and on external edits, but never on top of a
    // write we haven't finished issuing. Also migrates the pre-scope, flat
    // {dark, light} format into the current wallpaper's bucket the first time
    // it's loaded, rather than silently discarding it.
    function _adopt() {
        if (writeProc.running || root._pendingJson.length > 0)
            return;
        var hasByWallpaper = overrideData.byWallpaper && Object.keys(overrideData.byWallpaper).length > 0;
        var g = overrideData.global || {};
        var hasGlobal = (g.dark && Object.keys(g.dark).length > 0) || (g.light && Object.keys(g.light).length > 0);
        var legacyDark = overrideData.dark || {};
        var legacyLight = overrideData.light || {};
        var hasLegacy = Object.keys(legacyDark).length > 0 || Object.keys(legacyLight).length > 0;

        root.scope = overrideData.scope === "global" ? "global" : "wallpaper";
        root.enabled = overrideData.enabled;

        if (!hasByWallpaper && !hasGlobal && hasLegacy) {
            var migrated = {};
            migrated[root._currentWallpaper()] = {
                dark: root._copy(legacyDark),
                light: root._copy(legacyLight)
            };
            root.byWallpaper = migrated;
            root.global = {
                dark: {},
                light: {}
            };
            root._persist();
        } else {
            root.byWallpaper = root._copy(overrideData.byWallpaper);
            root.global = {
                dark: root._copy(g.dark),
                light: root._copy(g.light)
            };
        }
    }

    JsonAdapter {
        id: overrideData
        property bool enabled: true
        property string scope: "wallpaper"
        property var byWallpaper: ({})
        property var global: ({})
        // Legacy pre-scope fields, only read once for migration.
        property var dark: ({})
        property var light: ({})
    }

    Connections {
        target: overrideData
        function onEnabledChanged() {
            root._adopt();
        }
        function onScopeChanged() {
            root._adopt();
        }
        function onByWallpaperChanged() {
            root._adopt();
        }
        function onGlobalChanged() {
            root._adopt();
        }
        function onDarkChanged() {
            root._adopt();
        }
        function onLightChanged() {
            root._adopt();
        }
    }

    FileView {
        path: root._configPath
        watchChanges: true
        adapter: overrideData // qmllint disable missing-type
        onFileChanged: reload()
        onLoaded: root._adopt()
    }

    Process {
        id: writeProc
        running: false
        onExited: root._flush()
    }
}
