pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property bool recording: _recorder.running
    property int elapsed: 0
    property string lastFile: ""
    property string _currentFile: ""
    property var _pendingCmd: null

    function _timestamp() {
        var now = new Date();
        var pad = n => String(n).padStart(2, "0");
        return now.getFullYear() + pad(now.getMonth() + 1) + pad(now.getDate()) + "_" + pad(now.getHours()) + pad(now.getMinutes()) + pad(now.getSeconds());
    }

    function _videoDir() {
        return (Quickshell.env("HOME") || "") + "/Videos";
    }

    // GPUs discovered on this machine, for the device picker in RecordItem's
    // settings popup: [{value: "/dev/dri/renderD128", label: "AMD (renderD128)"}, ...].
    // Populated by _deviceProbe below so this stays hardware-agnostic.
    property var gpuDevices: []

    function _vendorName(hex) {
        switch (hex) {
        case "0x1002":
            return "AMD";
        case "0x8086":
            return "Intel";
        case "0x10de":
            return "NVIDIA";
        default:
            return "GPU";
        }
    }

    function _addDevice(line) {
        line = line.trim();
        if (!line)
            return;
        var parts = line.split("|");
        var path = parts[0];
        var vendor = _vendorName(parts[1] || "");
        var list = root.gpuDevices.slice();
        list.push({
            value: path,
            label: vendor + " (" + path.split("/").pop() + ")"
        });
        root.gpuDevices = list;
    }

    function start(geometry) {
        if (recording)
            return;
        var file = _videoDir() + "/recording_" + _timestamp() + ".mp4";
        _currentFile = file;
        var cmd = ["wf-recorder"];
        if (RecordSettings.device === "software") {
            // No -c/-d, wf-recorder's own default (software libx264). Universal
            // fallback for machines without a usable VAAPI encode path.
        } else {
            cmd.push("-c", "hevc_vaapi");
            if (RecordSettings.device !== "")
                cmd.push("-d", RecordSettings.device);
            cmd.push("-p", "qp=" + RecordSettings.qp);
        }
        if (RecordSettings.fpsCap > 0)
            cmd.push("-r", String(RecordSettings.fpsCap));
        if (geometry)
            cmd.push("-g", geometry);
        cmd.push("-f", file);
        _pendingCmd = cmd;
        _mkdir.running = true;
    }

    function stop() {
        if (!recording)
            return;
        _stopper.running = true;
    }

    function toggle() {
        if (recording)
            stop();
        else
            start(null);
    }

    function startRegion() {
        if (recording)
            return;
        _slurpBuf = "";
        _slurp.running = true;
    }

    property string _slurpBuf: ""

    Process {
        id: _mkdir
        running: false
        command: ["mkdir", "-p", root._videoDir()]
        onRunningChanged: {
            if (!running && root._pendingCmd) {
                _recorder.command = root._pendingCmd;
                _recorder.running = true;
                root._pendingCmd = null;
            }
        }
    }

    Process {
        id: _slurp
        running: false
        command: ["slurp"]
        stdout: SplitParser {
            onRead: data => root._slurpBuf = data.trim()
        }
        onRunningChanged: {
            if (!running && root._slurpBuf !== "") {
                root.start(root._slurpBuf);
                root._slurpBuf = "";
            }
        }
    }

    Process {
        id: _recorder
        running: false
        onRunningChanged: {
            if (!running) {
                root.lastFile = root._currentFile;
                root._currentFile = "";
            }
        }
    }

    Process {
        id: _stopper
        running: false
        command: ["pkill", "-INT", "wf-recorder"]
    }

    Process {
        id: _deviceProbe
        running: true
        command: ["sh", "-c", "for d in /dev/dri/render*; do [ -e \"$d\" ] || continue; rn=$(basename \"$d\"); v=$(cat \"/sys/class/drm/$rn/device/vendor\" 2>/dev/null); echo \"$d|$v\"; done"]
        stdout: SplitParser {
            onRead: data => root._addDevice(data)
        }
    }

    Timer {
        interval: 1000
        running: root.recording
        repeat: true
        onTriggered: root.elapsed++
    }

    onRecordingChanged: {
        if (!recording)
            elapsed = 0;
    }
}
