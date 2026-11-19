import QtQuick
import Quickshell
import Quickshell.Io

// Siri (macOS 27) for this shell: edge light + Type-to-Siri bubble +
// voice pipeline (~/.local/share/siri27/siri27d.py: whisper.cpp ->
// ChatGPT / Claude / local Ollama -> Piper).
// Settings: System Settings › Apple Intelligence & Siri  ->  ~/.config/siri27/config.json
Scope {
    id: siri

    property bool active: false
    property string state: "idle"      // idle | listening | thinking | speaking
    property real voiceLevel: 0
    property string heard: ""
    property string answer: ""
    property string error: ""
    property bool voiceRequest: false  // current request was spoken (not typed)
    property bool spoken: false        // Siri is answering out loud

    readonly property string home: Quickshell.env("HOME")
    readonly property string daemon: home + "/.local/share/siri27/siri27d.py"

    // ------------------------------------------------------------- settings
    property var cfg: ({})
    readonly property bool enabled: cfg.enabled !== false && cfg.apple_intelligence !== false
    readonly property bool captions: cfg.captions !== false
    readonly property bool showSpeech: cfg.show_speech !== false
    FileView {
        id: cfgFile
        path: siri.home + "/.config/siri27/config.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: { try { siri.cfg = JSON.parse(text()) } catch (e) { siri.cfg = {} } }
        onLoadFailed: siri.cfg = {}
    }

    function open(listen, ptt) {
        if (!siri.enabled) return
        siri.heard = ""; siri.answer = ""; siri.error = ""; siri.spoken = false
        siri.active = true
        if (listen) startListening(ptt)   // the daemon plays the sound, muting the mic meanwhile
        else chime.running = true          // Type to Siri
    }

    // activation sound (~/.local/share/siri27/sounds/activate.wav)
    Process {
        id: chime
        command: ["pw-play", siri.home + "/.local/share/siri27/sounds/activate.wav"]
    }
    function close() {
        if (worker.running) worker.signal(15)
        siri.active = false
        siri.state = "idle"
        siri.voiceLevel = 0
    }
    function startListening(ptt) {
        if (worker.running) worker.signal(15)
        siri.heard = ""; siri.answer = ""; siri.error = ""; siri.spoken = false
        siri.voiceRequest = true
        worker.command = ["python3", "-I", siri.daemon, "listen"].concat(ptt ? ["ptt"] : [])
        worker.running = true
    }
    function askText(t) {
        if (worker.running) worker.signal(15)
        siri.heard = t; siri.answer = ""; siri.error = ""; siri.spoken = false
        siri.voiceRequest = false
        worker.command = ["python3", "-I", siri.daemon, "ask", t]
        worker.running = true
    }

    // ------------------------------------------------ Siri key (macOS style)
    // press = Type to Siri, hold = speak to Siri until the key is released.
    property bool keyHeld: false
    property bool holding: false
    Timer {
        id: holdTimer
        interval: 350
        onTriggered: {
            siri.holding = true
            siri.open(true, true)
        }
    }
    function keyDown() {
        if (siri.keyHeld) return          // key repeat
        siri.keyHeld = true
        siri.holding = false
        holdTimer.restart()
    }
    function keyUp() {
        siri.keyHeld = false
        if (holdTimer.running) {          // short press
            holdTimer.stop()
            if (siri.active) siri.close(); else siri.open(false)
        } else if (siri.holding) {        // released after speaking: send it
            siri.holding = false
            if (worker.running && siri.state === "listening") worker.signal(10)   // SIGUSR1
        }
    }

    Process {
        id: worker
        stdout: SplitParser {
            onRead: (line) => {
                var m
                try { m = JSON.parse(line) } catch (e) { return }
                if (m.state !== undefined) siri.state = m.state
                if (m.level !== undefined) siri.voiceLevel = m.level
                if (m.heard !== undefined) siri.heard = m.heard
                if (m.delta !== undefined) siri.answer += m.delta
                if (m.answer !== undefined) siri.answer = m.answer
                if (m.spoken !== undefined) siri.spoken = m.spoken
                if (m.error !== undefined) siri.error = m.error
            }
        }
        onExited: { siri.voiceLevel = 0; siri.state = "idle" }
    }

    SiriGlow {
        id: glow
        active: siri.active
        voiceLevel: siri.voiceLevel
    }

    SiriBubble {
        active: siri.active
        state: siri.state
        // "Always show speech" / "Always show Siri captions"
        heard: (!siri.voiceRequest || siri.showSpeech) ? siri.heard : ""
        answer: (!siri.spoken || siri.captions) ? siri.answer : ""
        error: siri.error
        onSubmitted: (t) => siri.askText(t)
        onMicPressed: siri.startListening(false)
        onDismissRequested: siri.close()
    }

    IpcHandler {
        target: "siri"
        function toggle(): void { if (siri.active) siri.close(); else siri.open(false) }
        function listen(): void { siri.open(true, false) }
        function activate(): void { siri.open(false) }
        function dismiss(): void { siri.close() }
        function ask(text: string): void { siri.open(false); siri.askText(text) }
        function keyDown(): void { siri.keyDown() }
        function keyUp(): void { siri.keyUp() }
    }
}
