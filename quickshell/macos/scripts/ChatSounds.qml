pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string soundDir: Quickshell.env("HOME") + "/.config/hypr/sounds"
    property real volume: 0.5

    property string _typeSound:    soundDir + "/type.ogg"
    property string _sendSound:    soundDir + "/send.ogg"
    property string _removeSound:  soundDir + "/remove.ogg"

    property real _lastTypeTime: 0
    property int  _typeCooldown: 80

    Process {
        id: typeProc
        command: ["pw-play", "--volume", String(Math.round(root.volume * 65536)), root._typeSound]
    }

    Process {
        id: sendProc
        command: ["pw-play", "--volume", String(Math.round(root.volume * 65536)), root._sendSound]
    }

    Process {
        id: removeProc
        command: ["pw-play", "--volume", String(Math.round(root.volume * 65536)), root._removeSound]
    }

    function playType() {
        const now = Date.now()
        if (now - root._lastTypeTime < root._typeCooldown) return
        root._lastTypeTime = now
        if (typeProc.running) typeProc.kill()
        typeProc.running = true
    }

    function playSend() {
        if (sendProc.running) sendProc.kill()
        sendProc.running = true
    }

    function playRemove() {
        if (removeProc.running) removeProc.kill()
        removeProc.running = true
    }
}
