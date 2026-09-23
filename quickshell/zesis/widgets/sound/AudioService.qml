pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property real vol: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false

    readonly property string _configDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/zesis"
    readonly property string _configPath: _configDir + "/sound.json"

    property bool osdEnabled: soundData.osdEnabled
    onOsdEnabledChanged: {
        saveProc.command = ["sh", "-c", "mkdir -p '" + _configDir + "' && printf '%s' '{\"osdEnabled\":" + (osdEnabled ? "true" : "false") + "}' > '" + _configPath + "'"];
        saveProc.running = true;
    }

    JsonAdapter {
        id: soundData
        property bool osdEnabled: true
    }

    FileView {
        path: root._configPath
        watchChanges: true
        adapter: soundData
        onFileChanged: reload()
    }

    Process {
        id: saveProc
        running: false
    }

    PwObjectTracker {
        objects: [root.sink]
    }
}
