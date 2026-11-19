pragma Singleton
pragma ComponentBehavior: Bound

// SettingsBridge — applies what System Settings writes to the real system.
//
// System Settings (~/Documents/Default Project/SystemSettings) stores its
// choices in two files:
//   - ~/.config/quickshell/macos/userconfig.json   (read via Appearance.userCfg)
//   - ~/.config/aureli/config.json                 (eqsh Config, read raw here)
// Anything that is not consumed directly by a shell module is applied here:
// Hyprland input/window options, Night Shift (hyprsunset), cursor size,
// invert colours, volume feedback and notification sounds.
//
// Every setting is applied once at startup and again whenever its value
// changes; values that were never set are left untouched.

import QtQuick
import Quickshell
import Quickshell.Io
import "../modules/common"

Singleton {
    id: root

    readonly property bool ready: true

    // ---------------------------------------------------------------- inputs
    readonly property var u: Appearance.userCfg || ({})
    property var eq: ({})

    FileView {
        id: eqFile
        path: Quickshell.env("HOME") + "/.config/aureli/config.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try { root.eq = JSON.parse(eqFile.text()) } catch (e) { root.eq = ({}) }
        }
    }

    function pick(obj, dotted) {
        var parts = dotted.split(".")
        var cur = obj
        for (var i = 0; i < parts.length; i++) {
            if (cur === null || cur === undefined || typeof cur !== "object") return undefined
            cur = cur[parts[i]]
        }
        return cur
    }
    function ug(k) { return pick(u, k) }
    function eg(k) { return pick(eq, k) }

    // ------------------------------------------------------------ execution
    property var _applied: ({})

    function sh(cmd) {
        runner.createObject(root, { command: ["sh", "-c", cmd] })
    }
    Component {
        id: runner
        Process {
            running: true
            onExited: destroy()
        }
    }

    // Only run when the effective value changed since the last application.
    function once(id, value, fn) {
        if (value === undefined || value === null) return
        var key = JSON.stringify(value)
        if (_applied[id] === key) return
        _applied[id] = key
        fn(value)
    }

    function kw(option, value) { sh("hyprctl keyword " + option + " " + JSON.stringify(String(value)) + " >/dev/null 2>&1") }

    // defaults captured from Hyprland before we touch anything
    property string gapsIn: "6"
    property string gapsOut: "12"
    property string cursorTheme: Quickshell.env("XCURSOR_THEME") || "Adwaita"
    property var touchpads: []

    Process {
        id: probe
        running: true
        command: ["sh", "-c",
            "printf 'gin=%s\\n' \"$(hyprctl getoption general:gaps_in -j | python3 -c 'import json,sys;print(json.load(sys.stdin).get(\"custom\",\"6\").split()[0])' 2>/dev/null)\";" +
            "printf 'gout=%s\\n' \"$(hyprctl getoption general:gaps_out -j | python3 -c 'import json,sys;print(json.load(sys.stdin).get(\"custom\",\"12\").split()[0])' 2>/dev/null)\";" +
            "hyprctl devices -j | python3 -c 'import json,sys;[print(\"tp=\"+m[\"name\"]) for m in json.load(sys.stdin).get(\"mice\",[]) if \"touchpad\" in m[\"name\"].lower()]' 2>/dev/null"]
        stdout: SplitParser {
            onRead: (line) => {
                if (line.indexOf("gin=") === 0 && line.length > 4) root.gapsIn = line.substring(4)
                else if (line.indexOf("gout=") === 0 && line.length > 5) root.gapsOut = line.substring(5)
                else if (line.indexOf("tp=") === 0) root.touchpads = root.touchpads.concat([line.substring(3)])
            }
        }
        onExited: root.probed = true
    }
    property bool probed: false

    // ----------------------------------------------------------------- apply
    function applyAll() {
        if (!probed) return

        // ---- Keyboard ---------------------------------------------------
        once("repeatRate", ug("input.repeatRate"), v => kw("input:repeat_rate", Math.round(v)))
        once("repeatDelay", ug("input.repeatDelay"), v => kw("input:repeat_delay", Math.round(v)))
        once("kbLayout", ug("input.kbLayout"), v => kw("input:kb_layout", v))

        // ---- Mouse ------------------------------------------------------
        once("mouseSpeed", ug("input.mouseSpeed"), v => kw("input:sensitivity", Number(v).toFixed(2)))
        once("naturalScroll", ug("input.naturalScroll"), v => kw("input:natural_scroll", v ? "true" : "false"))
        once("scrollFactor", ug("input.scrollFactor"), v => kw("input:scroll_factor", Number(v).toFixed(2)))
        once("mouseAccel", ug("input.mouseAccel"), v => kw("input:accel_profile", v ? "adaptive" : "flat"))
        once("secondaryClick", ug("input.secondaryClick"), v => kw("input:left_handed", v === "Click Left Side" ? "true" : "false"))

        // ---- Trackpad ---------------------------------------------------
        once("tapToClick", ug("input.tapToClick"), v => kw("input:touchpad:tap-to-click", v ? "true" : "false"))
        once("touchpadNatural", ug("input.touchpadNatural"), v => kw("input:touchpad:natural_scroll", v ? "true" : "false"))
        once("touchpadScroll", ug("input.touchpadScroll"), v => kw("input:touchpad:scroll_factor", Number(v).toFixed(2)))
        once("disableWhileTyping", ug("input.disableWhileTyping"), v => kw("input:touchpad:disable_while_typing", v ? "true" : "false"))
        once("threeFingerDrag", ug("input.threeFingerDrag"), v => kw("input:touchpad:drag_3fg", v ? "1" : "0"))
        once("touchpadSecondary", ug("input.touchpadSecondary"), v => {
            // two-finger click/tap  vs  bottom corner button areas
            kw("input:touchpad:clickfinger_behavior", v === "Click or Tap with Two Fingers" ? "true" : "false")
            kw("input:touchpad:tap_button_map", v === "Off" ? "lmr" : "lrm")
        })
        once("touchpadSpeed", [ug("input.touchpadSpeed"), touchpads], v => {
            if (v[0] === undefined) return
            for (var i = 0; i < v[1].length; i++)
                kw("device[" + v[1][i] + "]:sensitivity", Number(v[0]).toFixed(2))
        })

        // ---- Windows & Spaces (Desktop & Dock) ---------------------------
        once("tileMargins", eg("windows.tileMargins"), v => {
            kw("general:gaps_in", v ? gapsIn : "0")
            kw("general:gaps_out", v ? gapsOut : "0")
        })
        once("edgeTile", eg("windows.edgeTile"), v => kw("general:snap:enabled", v ? "true" : "false"))
        once("switchToSpace", eg("spaces.switchToSpace"), v => kw("misc:focus_on_activate", v ? "true" : "false"))

        // ---- Accessibility -----------------------------------------------
        once("cursorSize", ug("accessibility.cursorSize"), v =>
            sh("hyprctl setcursor " + JSON.stringify(cursorTheme) + " " + Math.round(v) + " >/dev/null 2>&1"))
        once("invertColors", ug("accessibility.invertColors"), v => {
            if (v) {
                sh("mkdir -p \"$HOME/.local/share/systemsettings\" && cat > \"$HOME/.local/share/systemsettings/invert.glsl\" <<'GLSL'\n" +
                   "#version 300 es\nprecision highp float;\nin vec2 v_texcoord;\nuniform sampler2D tex;\nout vec4 fragColor;\n" +
                   "void main() { vec4 c = texture(tex, v_texcoord); fragColor = vec4(1.0 - c.rgb, c.a); }\nGLSL\n" +
                   "hyprctl keyword decoration:screen_shader \"$HOME/.local/share/systemsettings/invert.glsl\" >/dev/null 2>&1")
            } else {
                sh("hyprctl keyword decoration:screen_shader '[[EMPTY]]' >/dev/null 2>&1")
            }
        })

        // ---- Night Shift ---------------------------------------------------
        applyNightShift()
    }

    // Night Shift: manual toggle or "Sunset to Sunrise" (19:00–07:00) /
    // "Custom" (displays.nightShift.from/to, hours) through hyprsunset.
    function nightShiftWanted() {
        var sched = String(eg("display.nightShiftSchedule") || "Off")
        var h = new Date().getHours()
        if (sched === "Sunset to Sunrise") return h >= 19 || h < 7
        if (sched === "Custom") {
            var from = Number(eg("display.nightShiftFrom") || 22), to = Number(eg("display.nightShiftTo") || 7)
            return from > to ? (h >= from || h < to) : (h >= from && h < to)
        }
        return eg("display.nightShift") === true
    }
    function applyNightShift() {
        if (eg("display.nightShift") === undefined && eg("display.nightShiftSchedule") === undefined) return
        var on = nightShiftWanted()
        var t = Math.round(Number(eg("display.nightTemp") || 4500))
        once("nightShift", on ? t : 0, v => {
            sh("pgrep -x hyprsunset >/dev/null || (hyprsunset >/dev/null 2>&1 &); sleep 0.4; " +
               (v > 0 ? "hyprctl hyprsunset temperature " + v : "hyprctl hyprsunset identity") + " >/dev/null 2>&1")
        })
    }
    Timer { interval: 60000; running: true; repeat: true; onTriggered: root.applyNightShift() }

    onUChanged: applyAll()
    onEqChanged: applyAll()
    onProbedChanged: applyAll()
    onTouchpadsChanged: applyAll()

    // ---------------------------------------------------------------- sounds
    readonly property bool doNotDisturb: ug("focus.dnd") === true || ug("focus.sleep") === true

    function play(path, vol) {
        if (!path) return
        sh("(command -v pw-play >/dev/null && pw-play --volume=" + (vol || 0.6) + " " + JSON.stringify(path) +
           " || paplay " + JSON.stringify(path) + ") >/dev/null 2>&1 &")
    }

    // "Play feedback when volume is changed"
    property real _lastVol: -1
    Timer { id: volDebounce; interval: 180; onTriggered: root.play("/usr/share/sounds/freedesktop/stereo/audio-volume-change.oga", 0.5) }
    Connections {
        target: Audio
        function onVolumeChanged() {
            var v = Audio.volume
            if (root._lastVol >= 0 && Math.abs(v - root._lastVol) > 0.004 && root.eg("sound.volumeFeedback") === true)
                volDebounce.restart()
            root._lastVol = v
        }
    }

    // Notification alert sound ("Alert sound" + "Play sound for notification")
    Connections {
        target: Notifications
        function onNotify(n) {
            if (root.doNotDisturb) return
            if (root.ug("notifications.sound") === false) return
            if (root.eg("sound.uiSounds") === false) return
            var p = root.eg("sound.alertSound") || "/usr/share/sounds/freedesktop/stereo/message.oga"
            var vol = root.eg("sound.alertVolume")
            root.play(p, vol !== undefined ? Number(vol) : 0.6)
        }
    }
}
