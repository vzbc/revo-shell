pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string soundDir: Quickshell.env("HOME") + "/.config/hypr/sounds"
    property real volume: 0.5

    property real _lastTypeTime: 0
    property int  _typeCooldown: 80

    function _play(file) {
        const vol = String(Math.round(root.volume * 65536))
        const p = Qt.createQmlObject('import QtQuick; import Quickshell.Io; Process {}', root)
        p.command = ["pw-play", "--volume", vol, file]
        p.onExited.connect(function() { p.destroy() })
        p.running = true
    }

    function playType() {
        const now = Date.now()
        if (now - root._lastTypeTime < root._typeCooldown) return
        root._lastTypeTime = now
        _play(root.soundDir + "/type.ogg")
    }

    function playSend() {
        _play(root.soundDir + "/send.ogg")
    }

    function playRemove() {
        _play(root.soundDir + "/remove.ogg")
    }
}
