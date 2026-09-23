pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string _configDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/zesis"
    readonly property string _path: _configDir + "/record-widget.json"

    // "" = auto (let wf-recorder pick a VAAPI device itself), "software" = force
    // CPU libx264 encode, otherwise an explicit /dev/dri/renderDXXX path
    property string device: ""
    property int qp: 24
    // 0 = uncapped (record at the display's native refresh rate)
    property int fpsCap: 0

    function setDevice(val) {
        root.device = val;
        _save();
    }

    function setQp(val) {
        root.qp = Math.max(0, Math.min(51, Math.round(val)));
        _save();
    }

    function setFpsCap(val) {
        root.fpsCap = val;
        _save();
    }

    function _save() {
        configFile.setText(JSON.stringify({
            device: root.device,
            qp: root.qp,
            fpsCap: root.fpsCap
        }));
    }

    function _load(text) {
        if (!text)
            return;
        try {
            var obj = JSON.parse(text) || {};
            if (typeof obj.device === "string")
                root.device = obj.device;
            if (typeof obj.qp === "number")
                root.qp = Math.max(0, Math.min(51, Math.round(obj.qp)));
            if (typeof obj.fpsCap === "number")
                root.fpsCap = obj.fpsCap;
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
