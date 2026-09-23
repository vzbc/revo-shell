pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Persisted preference for the Globe desktop widget's rotation behaviour.
Singleton {
    id: root

    readonly property string _configDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/zesis"
    readonly property string _path: _configDir + "/globe2d-widget.json"

    // "auto" spins continuously via Globe2D's own FrameAnimation.
    // "manual" renders a single static frame and stays idle, so
    // we don't fry their GPU.
    property string rotateMode: "auto"

    function setRotateMode(mode) {
        root.rotateMode = mode;
        _save();
    }

    function _save() {
        configFile.setText(JSON.stringify({
            rotateMode: root.rotateMode
        }));
    }

    function _load(text) {
        if (!text)
            return;
        try {
            var obj = JSON.parse(text) || {};
            if (obj.rotateMode === "auto" || obj.rotateMode === "manual")
                root.rotateMode = obj.rotateMode;
        } catch (_) {}
    }

    FileView {
        id: configFile
        path: root._path
        blockLoading: true
        printErrors: false
        onLoaded: root._load(configFile.text())
    }

    Component.onCompleted: _load(configFile.text())
}
