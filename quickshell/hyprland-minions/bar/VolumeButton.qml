import QtQuick
import Quickshell.Services.Pipewire
import qs.components
import qs.popups

// Click for the mixer popup, scroll to change volume, middle click to mute.
BarButton {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var audio: sink?.audio ?? null

    implicitWidth: 72
    active: popup.shown
    text: !audio ? "VOL: --" : audio.muted ? "VOL: Mute" : "VOL: " + Math.round(audio.volume * 100) + "%"
    tooltip: sink ? (sink.description || sink.nickname || sink.name) : ""

    onClicked: mouse => {
        if (mouse.button === Qt.MiddleButton) {
            if (audio) audio.muted = !audio.muted
        } else {
            popup.toggle()
        }
    }
    onScrolled: wheel => {
        if (!audio) return
        audio.muted = false
        audio.volume = Math.min(1, Math.max(0, audio.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05)))
    }

    PwObjectTracker {
        objects: [root.sink]
    }

    VolumePopup {
        id: popup
        anchorItem: root
    }
}
