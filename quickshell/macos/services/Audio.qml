pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real volume: 0.5
    property bool muted: false
    property bool hasSink: true
    property var sinks: []      // [{id, name, isDefault}]
    property var sources: []    // [{id, name, isDefault}]

    function poll() {
        _getVolume.running = true;
        _sinks.running = true;
        _sources.running = true;
    }

    function setDefaultSink(id) {
        _def.command = ["bash", "-c", "timeout 3 wpctl set-default " + id];
        _def.running = true;
        root.poll();
    }

    function setDefaultSource(id) {
        _def.command = ["bash", "-c", "timeout 3 wpctl set-default " + id];
        _def.running = true;
        root.poll();
    }

    function _parse(text, header) {
        if (typeof text !== "string") return [];
        const lines = text.split("\n");
        let mode = "";
        const out = [];
        for (const raw of lines) {
            const line = (typeof raw === "string") ? raw.replace(/\s+$/, "").replace(/^\s+/, "") : "";
            if (line === "Sink:") { mode = "Sink"; continue; }
            if (line === "Sources:") { mode = "Sources"; continue; }
            if (line === "Source:") { mode = "Sources"; continue; }
            if (mode !== header) continue;
            const m = line.match(/\*?\s*(\d+)\.\s*(.+)/);
            if (m) out.push({ id: m[1], name: m[2].trim(), isDefault: line.trimStart().startsWith("*") });
        }
        return out;
    }

    function setVolume(v) {
        const value = Math.max(0, Math.min(1, v));
        root.volume = value;
        _setVolume.command = ["bash", "-c", "timeout 3 wpctl set-volume @DEFAULT_AUDIO_SINK@ " + Math.round(value * 100) + "%"];
        _setVolume.running = true;
    }

    function toggleMute() {
        _setMute.running = true;
        root.muted = !root.muted;
    }

    Process {
        id: _sinks
        running: false
        command: ["bash", "-c", "wpctl status 2>/dev/null || true"]
        stdout: StdioCollector {
            onStreamFinished: root.sinks = root._parse(text, "Sink")
        }
    }

    Process {
        id: _sources
        running: false
        command: ["bash", "-c", "wpctl status 2>/dev/null || true"]
        stdout: StdioCollector {
            onStreamFinished: root.sources = root._parse(text, "Sources")
        }
    }

    Process {
        id: _def
        running: false
        stdout: StdioCollector {}
        stderr: StdioCollector {}
    }

    Process {
        id: _getVolume
        running: false
        command: ["bash", "-c", "timeout 3 wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || echo failed"]
        stdout: StdioCollector {
            onStreamFinished: {
                const raw = (typeof text === "string") ? text : "";
                if (raw.trim() === "failed") {
                    root.hasSink = false;
                    return;
                }
                root.hasSink = true;
                const m = text.match(/([\d.]+)/);
                if (m) root.volume = Math.max(0, Math.min(1, parseFloat(m[1])));
                root.muted = text.includes("MUTED");
            }
        }
    }

    Process {
        id: _setVolume
        running: false
        stdout: StdioCollector {}
        stderr: StdioCollector {}
    }

    Process {
        id: _setMute
        running: false
        command: ["bash", "-c", "timeout 3 wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"]
        stdout: StdioCollector {}
        stderr: StdioCollector {}
    }

    Timer {
        interval: 1500
        running: true
        repeat: true
        onTriggered: root.poll()
    }

    Component.onCompleted: root.poll()
}
