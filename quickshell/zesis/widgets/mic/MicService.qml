pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property real vol: source?.audio?.volume ?? 0
    readonly property bool muted: source?.audio?.muted ?? false

    PwObjectTracker {
        objects: [root.source]
    }
}
