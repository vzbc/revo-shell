pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string _configDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/zesis"
    readonly property string _configPath: _configDir + "/barconfig.json"

    property string side: barData.side
    property int edgeGap: barData.edgeGap
    property int endGap: barData.endGap
    property var itemStates: barData.itemStates

    property var zones: barData.zones

    property var pinnedIds: barData.pinnedIds

    // Legacy migration step
    readonly property var _legacyItemIslands: barData.itemIslands
    // Names of screens (ShellScreen.name) the bar should appear on
    property var monitors: barData.monitors

    readonly property bool isVertical: side === "left" || side === "right"

    // True when FileView completes loading
    property bool ready: false

    function write(newSide) {
        _save(newSide, root.edgeGap, root.endGap, root.itemStates, root.zones, root.monitors, root.pinnedIds);
    }

    function writeEdgeGap(newGap) {
        _save(root.side, newGap, root.endGap, root.itemStates, root.zones, root.monitors, root.pinnedIds);
    }

    function writeEndGap(newGap) {
        _save(root.side, root.edgeGap, newGap, root.itemStates, root.zones, root.monitors, root.pinnedIds);
    }

    function writeItemStates(states) {
        _save(root.side, root.edgeGap, root.endGap, states, root.zones, root.monitors, root.pinnedIds);
    }

    function writeZones(zones) {
        _save(root.side, root.edgeGap, root.endGap, root.itemStates, zones, root.monitors, root.pinnedIds);
    }

    function writeMonitors(monitors) {
        _save(root.side, root.edgeGap, root.endGap, root.itemStates, root.zones, monitors, root.pinnedIds);
    }

    function writePinnedIds(pinnedIds) {
        _save(root.side, root.edgeGap, root.endGap, root.itemStates, root.zones, root.monitors, pinnedIds);
    }

    function _save(s, eg, en, states, zones, monitors, pinnedIds) {
        const json = '{"side":"' + s + '","edgeGap":' + eg + ',"endGap":' + en + ',"itemStates":' + JSON.stringify(states) + ',"zones":' + JSON.stringify(zones) + ',"monitors":' + JSON.stringify(monitors) + ',"pinnedIds":' + JSON.stringify(pinnedIds) + '}';
        writeProc.command = ["sh", "-c", "mkdir -p '" + root._configDir + "' && printf '%s' '" + json + "' > '" + root._configPath + "'"];
        writeProc.running = true;
    }

    JsonAdapter {
        id: barData
        property string side: "top"
        property int edgeGap: 20
        property int endGap: 20
        // Only overrides need listing - _merge() in BarItemsService fills
        // in every other catalog item as enabled.
        property var itemStates: ({
                "mic": false,
                "wifi": false
            })
        property var zones: [[["workspace"]], [["music"], ["taskbar"]], [["systray"], ["sysmon", "theme", "keybinds", "bluetooth", "wifi", "airpods", "weather", "brightness", "sound", "mic", "notifications", "config", "battery", "record", "gitupdate"], ["settings", "home", "lock", "clock"]]]
        // Legacy variable
        property var itemIslands: []
        property var monitors: []
        property var pinnedIds: ["workspace"]
    }

    FileView {
        path: root._configPath
        watchChanges: true
        printErrors: false
        adapter: barData
        onFileChanged: reload()
        onLoaded: root.ready = true
        onLoadFailed: root.ready = true
    }

    Process {
        id: writeProc
        running: false
    }
}
