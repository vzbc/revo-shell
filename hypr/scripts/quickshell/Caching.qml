import QtQuick
import Quickshell

QtObject {
    id: root
    readonly property string home: Quickshell.env("HOME")
    readonly property string xdgRuntimeDir: Quickshell.env("XDG_RUNTIME_DIR")
    
    // Persistent data on disk
    readonly property string cacheDir: home + "/.cache/quickshell"
    readonly property string stateDir: home + "/.local/state/quickshell"
    
    // Ephemeral data in RAM (tmpfs) - fallback to /tmp if XDG_RUNTIME_DIR is somehow empty
    readonly property string runDir: (xdgRuntimeDir !== "" ? xdgRuntimeDir : "/tmp") + "/quickshell"
    readonly property string logDir: runDir + "/logs"

    function getCacheDir(widgetName) {
        var envPath = Quickshell.env("QS_CACHE_" + widgetName.toUpperCase());
        var finalPath = envPath ? envPath : (cacheDir + "/" + widgetName);
        Quickshell.execDetached(["mkdir", "-p", finalPath]);
        return finalPath;
    }
    
    function getStateDir(widgetName) {
        var envPath = Quickshell.env("QS_STATE_" + widgetName.toUpperCase());
        var finalPath = envPath ? envPath : (stateDir + "/" + widgetName);
        Quickshell.execDetached(["mkdir", "-p", finalPath]);
        return finalPath;
    }
    
    function getRunDir(widgetName) {
        var envPath = Quickshell.env("QS_RUN_" + widgetName.toUpperCase());
        var finalPath = envPath ? envPath : (runDir + "/" + widgetName);
        Quickshell.execDetached(["mkdir", "-p", finalPath]);
        return finalPath;
    }
    
    function getLogDir(widgetName) {
        var envPath = Quickshell.env("QS_LOG_" + widgetName.toUpperCase());
        var finalPath = envPath ? envPath : (logDir + "/" + widgetName);
        Quickshell.execDetached(["mkdir", "-p", finalPath]);
        return finalPath;
    }
}
