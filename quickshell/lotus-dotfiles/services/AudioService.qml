import QtQuick
import Quickshell.Services.Pipewire

QtObject {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property bool ready: Pipewire.ready && sink !== null && sink.ready && sink.audio !== null
    readonly property bool inputReady: Pipewire.ready && source !== null && source.ready && source.audio !== null
    readonly property bool muted: ready ? sink.audio.muted : false
    readonly property bool inputMuted: inputReady ? source.audio.muted : false
    readonly property real volume: ready ? sink.audio.volume : 0
    readonly property real inputVolume: inputReady ? source.audio.volume : 0
    readonly property int volumePercent: Math.max(0, Math.round(volume * 100))
    readonly property int inputVolumePercent: Math.max(0, Math.round(inputVolume * 100))
    readonly property string statusText: !ready ? "Audio unavailable" : (muted ? "Audio muted" : "Volume " + volumePercent + " percent")
    readonly property string inputStatusText: !inputReady ? "Microphone unavailable" : (inputMuted ? "Microphone muted" : "Microphone " + inputVolumePercent + " percent")
    readonly property var outputNodes: Pipewire.nodes.values.filter(function(node) {
        return node !== null && node.isSink && !node.isStream && node.audio !== null;
    })
    readonly property var inputNodes: Pipewire.nodes.values.filter(function(node) {
        return node !== null && !node.isSink && !node.isStream && node.audio !== null;
    })
    property PwObjectTracker nodeTracker

    function deviceName(node) {
        if (node === null || node === undefined)
            return "Unknown device";

        const description = String(node.description || "").trim();
        if (description.length > 0)
            return description;

        const nickname = String(node.nickname || "").trim();
        return nickname.length > 0 ? nickname : String(node.name || "Audio device");
    }

    function isDefaultOutput(node) {
        return node !== null && sink !== null && node.id === sink.id;
    }

    function isDefaultInput(node) {
        return node !== null && source !== null && node.id === source.id;
    }

    function selectOutput(node) {
        if (node !== null && node.ready)
            Pipewire.preferredDefaultAudioSink = node;

    }

    function selectInput(node) {
        if (node !== null && node.ready)
            Pipewire.preferredDefaultAudioSource = node;

    }

    function toggleMuted() {
        if (ready)
            sink.audio.muted = !sink.audio.muted;

    }

    function setVolume(nextVolume) {
        if (!ready)
            return ;

        sink.audio.volume = Math.max(0, Math.min(1, nextVolume));
        if (sink.audio.muted && nextVolume > 0)
            sink.audio.muted = false;

    }

    function toggleInputMuted() {
        if (inputReady)
            source.audio.muted = !source.audio.muted;

    }

    function setInputVolume(nextVolume) {
        if (!inputReady)
            return ;

        source.audio.volume = Math.max(0, Math.min(1, nextVolume));
        if (source.audio.muted && nextVolume > 0)
            source.audio.muted = false;

    }

    nodeTracker: PwObjectTracker {
        objects: root.outputNodes.concat(root.inputNodes)
    }

}
