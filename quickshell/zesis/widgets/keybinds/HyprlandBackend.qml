import QtQuick
import Quickshell.Io
import Quickshell.Hyprland

// Hyprland-specific keybind backend.
//
// Interface (shared with any future backend):
//   property var sections  - [{name, icon, binds: [{keys, label}]}]
//   function refresh()     - re-fetch from the compositor

QtObject {
    id: root

    property var sections: []

    function refresh() {
        sock.connected = false;
        sock.connected = true;
    }

    Component.onCompleted: refresh()

    property QtObject _sock: Socket {
        id: sock
        path: Hyprland.requestSocketPath
        property string _buf: ""

        parser: SplitParser {
            splitMarker: ""
            onRead: data => sock._buf += data
        }

        onConnectedChanged: {
            if (connected) {
                write("j/binds");
                flush();
            } else if (_buf.length > 0) {
                root.sections = root._parse(_buf);
                _buf = "";
            }
        }
    }

    function _normalizeKey(k) {
        var map = {
            "Return": "Enter",
            "Tab": "Tab",
            "Escape": "Esc",
            "space": "Space",
            "Delete": "Del",
            "Print": "Print",
            "grave": "`",
            "minus": "-",
            "equal": "=",
            "bracketleft": "[",
            "bracketright": "]",
            "semicolon": ";",
            "apostrophe": "'",
            "comma": ",",
            "period": ".",
            "slash": "/",
            "backslash": "\\",
            "up": "↑",
            "down": "↓",
            "left": "←",
            "right": "→",
            "XF86AudioPlay": "Play/Pause",
            "XF86AudioNext": "Next",
            "XF86AudioPrev": "Prev",
            "XF86AudioRaiseVolume": "Vol+",
            "XF86AudioLowerVolume": "Vol-",
            "XF86AudioMute": "Mute",
            "XF86AudioMicMute": "Mic Mute",
            "XF86MonBrightnessUp": "Bright+",
            "XF86MonBrightnessDown": "Bright-"
        };
        return map[k] !== undefined ? map[k] : k;
    }

    function _modsFromMask(mask) {
        var mods = [];
        if (mask & 64)
            mods.push("Super");  // Mod4
        if (mask & 1)
            mods.push("Shift");  // Shift
        if (mask & 4)
            mods.push("Ctrl");   // Control
        if (mask & 8)
            mods.push("Alt");    // Mod1
        return mods;
    }

    function _icon(cat) {
        var icons = {
            "Window": "󰖯",
            "App": "󰀻",
            "Workspace": "󰣠",
            "Screenshot": "󰹑",
            "Utilities": "",
            "Media": "󰝚",
            "Volume": "󰕾",
            "Session": ""
        };
        return icons[cat] || "󰌌";
    }

    function _parse(jsonText) {
        var binds;
        try {
            binds = JSON.parse(jsonText);
        } catch (_) {
            return [];
        }

        var ORDER = ["Window", "App", "Workspace", "Screenshot", "Utilities", "Media", "Volume", "Session"];
        var map = {};
        var seen = {};  // deduplicate by description (handles workspace 1-9 loops)

        for (var i = 0; i < binds.length; i++) {
            var b = binds[i];
            if (!b.has_description || !b.description)
                continue;
            if (b.mouse)
                continue;
            if (seen[b.description])
                continue;
            seen[b.description] = true;

            var sep = b.description.indexOf(": ");
            var cat = sep >= 0 ? b.description.substring(0, sep).trim() : "Other";
            var label = sep >= 0 ? b.description.substring(sep + 2).trim() : b.description;

            var keys = _modsFromMask(b.modmask);
            if (b.key)
                keys.push(_normalizeKey(b.key));

            if (!map[cat])
                map[cat] = [];
            map[cat].push({
                keys: keys,
                label: label
            });
        }

        var result = [];
        for (var j = 0; j < ORDER.length; j++) {
            var c = ORDER[j];
            if (map[c]) {
                result.push({
                    name: c,
                    icon: _icon(c),
                    binds: map[c]
                });
                delete map[c];
            }
        }
        for (var rcat in map)
            result.push({
                name: rcat,
                icon: _icon(rcat),
                binds: map[rcat]
            });

        return result;
    }
}
