pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string _configDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/zesis"
    readonly property string _configPath: _configDir + "/clocksettings.json"

    // "breathe" | "on" | "off" | "hidden"
    property string colonMode: settingsData.colonMode
    // "fixed" | "fluid"
    property string widthMode: settingsData.widthMode
    property bool showDate: settingsData.showDate
    property bool use12Hour: settingsData.use12Hour

    signal altModeRequested

    function write(cm, wm, sd, h12) {
        writeProc.command = ["sh", "-c", "mkdir -p '" + root._configDir + "' && echo '{\"colonMode\":\"" + cm + "\",\"widthMode\":\"" + wm + "\",\"showDate\":" + (sd ? "true" : "false") + ",\"use12Hour\":" + (h12 ? "true" : "false") + "}' > '" + root._configPath + "'"];
        writeProc.running = true;
    }

    function writeColonMode(mode) {
        write(mode, root.widthMode, root.showDate, root.use12Hour);
    }
    function writeWidthMode(mode) {
        write(root.colonMode, mode, root.showDate, root.use12Hour);
    }
    function writeShowDate(val) {
        write(root.colonMode, root.widthMode, val, root.use12Hour);
    }
    function writeUse12Hour(val) {
        write(root.colonMode, root.widthMode, root.showDate, val);
    }

    JsonAdapter {
        id: settingsData
        property string colonMode: "breathe"
        property string widthMode: "fixed"
        property bool showDate: false
        property bool use12Hour: false
    }

    FileView {
        path: root._configPath
        watchChanges: true
        adapter: settingsData
        onFileChanged: reload()
    }

    Process {
        id: writeProc
        running: false
    }
}
