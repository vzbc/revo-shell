pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string _configDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/zesis"
    readonly property string _configPath: _configDir + "/assemblytestsettings.json"

    property string aaMode: settingsData.aaMode // "Off" | "Medium" | "High" | "VeryHigh"
    property bool useImageCache: settingsData.useImageCache

    function write(am, uic) {
        writeProc.command = ["sh", "-c", "mkdir -p '" + root._configDir + "' && echo '{\"aaMode\":\"" + am + "\",\"useImageCache\":" + (uic ? "true" : "false") + "}' > '" + root._configPath + "'"];
        writeProc.running = true;
    }

    function writeAaMode(mode) {
        write(mode, root.useImageCache);
    }
    function writeUseImageCache(val) {
        write(root.aaMode, val);
    }

    JsonAdapter {
        id: settingsData
        property string aaMode: "High"
        property bool useImageCache: true
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
