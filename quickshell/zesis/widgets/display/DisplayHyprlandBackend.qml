import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Hyprland-specific display backend.
//
// Interface (shared with any future compositor backend):
//   property string monitorName
//   property string monitorModel
//   property string monitorMake
//   property int    currentWidth
//   property int    currentHeight
//   property real   currentScale
//   property real   currentRefresh
//   property int    physicalWidthMm
//   property int    physicalHeightMm
//   property var    availableModes   - list of "WxH@RHz" strings
//
//   function refresh()           - re-fetch monitor state
//   function apply(modeStr)      - apply mode string, then refresh

QtObject {
    id: root

    property string monitorName: ""
    property string monitorModel: ""
    property string monitorMake: ""
    property int currentWidth: 0
    property int currentHeight: 0
    property real currentScale: 1.0
    property real currentRefresh: 0
    property int physicalWidthMm: 0
    property int physicalHeightMm: 0
    property var availableModes: []

    readonly property string _cachePath: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/zesis/display.lua"

    function refresh() {
        for (var i = 0; i < Quickshell.screens.length; i++)
            Hyprland.monitorFor(Quickshell.screens[i]);
        Hyprland.refreshMonitors();
    }

    function apply(modeStr) {
        var pos = root.currentWidth > 0 ? "0x0" : "auto";
        Hyprland.dispatch("hl.monitor({output=\"" + root.monitorName + "\", mode=\"" + modeStr + "\", position=\"" + pos + "\", scale=" + root.currentScale + "})");
        cacheFile.setText('return { output = "' + root.monitorName + '", mode = "' + modeStr + '" }\n');
        applySettleTimer.restart();
    }

    function _sync() {
        var m = Hyprland.focusedMonitor;
        if (!m)
            return;
        var obj = m.lastIpcObject;
        root.monitorName = obj.name ?? "";
        root.monitorModel = obj.model ?? "";
        root.monitorMake = obj.make ?? "";
        root.currentWidth = obj.width ?? 0;
        root.currentHeight = obj.height ?? 0;
        root.currentScale = obj.scale ?? 1.0;
        root.currentRefresh = obj.refreshRate ?? 0;
        root.physicalWidthMm = obj.physicalWidth ?? 0;
        root.physicalHeightMm = obj.physicalHeight ?? 0;
        root.availableModes = obj.availableModes ?? [];
    }

    property QtObject _applySettleTimer: Timer {
        id: applySettleTimer
        interval: 250
        onTriggered: root.refresh()
    }

    property QtObject _focusWatcher: Connections {
        target: Hyprland
        function onFocusedMonitorChanged() {
            root._sync();
        }
    }

    property QtObject _monitorWatcher: Connections {
        target: Hyprland.focusedMonitor
        function onLastIpcObjectChanged() {
            root._sync();
        }
    }

    property QtObject _cacheFile: FileView {
        id: cacheFile
        path: root._cachePath
        printErrors: false
    }
}
