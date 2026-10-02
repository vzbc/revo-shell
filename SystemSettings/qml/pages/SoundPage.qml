import QtQuick
import ".."
import "../Pages.js" as Pages

Column {
    id: page

    property string pageId: "sound"
    property string accountName: ""
    property string accountEmail: ""
    signal navigate(string pageId)

    readonly property var bumpU: Shell.userCfg
    readonly property var bumpE: Shell.eqCfg
    property int rev: 0

    property var audio: ({ volume: -1, sinks: [], sources: [] })
    property string playingId: ""
    property int tick: 0

    function eget(k, d) { bumpU; bumpE; return Shell.eget(k, d) }
    function uget(k, d) { bumpU; bumpE; return Shell.uget(k, d) }

    width: parent ? parent.width : 640
    spacing: 12

    Timer {
        id: poll
        interval: 1200
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: page.audio = Shell.audioState()
    }

    Timer {
        id: barTick
        interval: 110
        running: page.playingId.length > 0
        repeat: true
        onTriggered: page.tick++
    }

    Timer {
        id: stopPlay
        interval: 900
        onTriggered: page.playingId = ""
    }

    readonly property var alerts: {
        var a = Shell.listFiles("/usr/share/sounds/freedesktop/stereo", "oga;ogg")
        var b = Shell.listFiles("/usr/share/sounds/gnome/default/alerts", "ogg")
        var out = []
        for (var i = 0; i < b.length; i++) out.push(b[i])
        for (var j = 0; j < a.length; j++) {
            var n = a[j].split("/").pop()
            if (n.indexOf("audio-") === 0 || n.indexOf("bell") === 0 ||
                n.indexOf("complete") === 0 || n.indexOf("message-") === 0 ||
                n.indexOf("dialog-") === 0 || n.indexOf("camera-") === 0 ||
                n.indexOf("power-") === 0 || n.indexOf("button-") === 0)
                out.push(a[j])
        }
        return out
    }

    function baseName(p) {
        return p.split("/").pop().replace(/\.[^.]+$/, "").replace(/-/g, " ")
    }

    function play(path) {
        page.playingId = path
        stopPlay.restart()
        Shell.run("paplay --volume=40000 " + path.replace(/'/g, "'\\''") + " >/dev/null 2>&1 &")
        Shell.eset("sound.alertSound", path)
        rev++
    }

    Placard {
        iconFile: "sb_sound"
        title: "Sound"
    }

    SectionHeader { text: "Sound Effects" }

    GroupCard {
        DetailRow {
            title: "Alert volume"
            isSlider: true
            sliderValue: page.audio.volume >= 0 ? page.audio.volume : 0.6
            onMoved: (r) => {
                page.audio.volume = r
                Shell.setSinkVolume(r)
                Shell.ipc("audio", "setVolume", [String(r)])
            }
        }

        DetailRow {
            separator: true
            title: "Play sound effects through"
            pickerOptions: page.audio.sinks.map(function (s) { return s.name })
            value: {
                page.audio
                for (var i = 0; i < page.audio.sinks.length; i++)
                    if (page.audio.sinks[i]["default"])
                        return page.audio.sinks[i].name
                return "\u2014"
            }
            onPicked: (v) => {
                for (var i = 0; i < page.audio.sinks.length; i++) {
                    if (page.audio.sinks[i].name === v) {
                        Shell.setDefaultNode(page.audio.sinks[i].id)
                        page.audio = Shell.audioState()
                        rev++
                        break
                    }
                }
            }
        }

        DetailRow {
            title: "Play user interface sound effects"
            showSwitch: true
            switchOn: eget("sound.uiSounds", true) === true
            onToggled: (c) => { Shell.eset("sound.uiSounds", c); rev++ }
        }

        DetailRow {
            title: "Play feedback when changing volume"
            showSwitch: true
            switchOn: eget("sound.volumeFeedback", false) === true
            onToggled: (c) => { Shell.eset("sound.volumeFeedback", c); rev++ }
        }
    }

    Item { width: 1; height: 4 }

    SectionHeader { text: "Alert sound" }

    GroupCard {
        width: parent.width
        height: alertsCol.implicitHeight + 8

        Column {
            id: alertsCol
            width: parent.width
            spacing: 0

            Repeater {
                model: page.alerts

                delegate: DetailRow {
                    id: alertRow
                    required property var modelData
                    required property int index
                    width: alertsCol.width
                    separator: index > 0
                    title: page.baseName(modelData)
                    titleColor: eget("sound.alertSound", "") === modelData ? Theme.accent : Theme.textPrimary

                    // animated level bars while the sample plays
                    Row {
                        anchors.right: parent.right
                        anchors.rightMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 3
                        visible: page.playingId === modelData

                        Repeater {
                            model: 5
                            delegate: Rectangle {
                                required property int index
                                width: 4
                                height: 8 + (page.playingId === modelData
                                             ? (Math.sin(page.tick * 0.9 + index * 1.1) * 0.5 + 0.5) * 16 : 0)
                                radius: 2
                                color: Theme.accent
                                Behavior on height { NumberAnimation { duration: 120 } }
                            }
                        }
                    }

                    onClicked: page.play(modelData)
                }
            }
        }
    }

    Item { width: 1; height: 4 }

    SectionHeader { text: "Output" }

    GroupCard {
        Repeater {
            model: page.audio.sinks

            delegate: DetailRow {
                required property var modelData
                title: modelData.name
                value: modelData["default"] ? "\u2713" : ""
                chevron: !modelData["default"]
                onClicked: {
                    Shell.setDefaultNode(modelData.id)
                    page.audio = Shell.audioState()
                    rev++
                }
            }
        }
    }

    Item { width: 1; height: 4 }

    SectionHeader { text: "Input" }

    GroupCard {
        DetailRow {
            title: "Input volume"
            isSlider: true
            sliderValue: page.audio.inputVolume >= 0 ? page.audio.inputVolume : 0.5
            onMoved: (r) => { page.audio.inputVolume = r; Shell.setSourceVolume(r) }
        }

        DetailRow {
            separator: true
            title: "Mute"
            showSwitch: true
            switchOn: page.audio.inputMuted === true
            onToggled: (c) => {
                Shell.run(c ? "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ 1"
                            : "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ 0")
                page.audio = Shell.audioState()
                rev++
            }
        }

        DetailRow {
            title: "Show input level meter"
            showSwitch: true
            switchOn: eget("sound.inputMeter", true) === true
            onToggled: (c) => { Shell.eset("sound.inputMeter", c); rev++ }
        }
    }

    Item { width: 1; height: 4 }

    SectionHeader { text: "Menu Bar" }

    GroupCard {
        DetailRow {
            title: "Show Sound in menu bar"
            showSwitch: true
            switchOn: uget("menubarSound", true) === true
            onToggled: (c) => {
                Shell.uset("menubarSound", c)
                Shell.uset("menubar.sound", c)
                rev++
            }
        }
        DetailRow {
            separator: true
            title: "Show in menu bar when playing"
            pickerOptions: ["Always", "Automatically", "Never"]
            value: String(eget("sound.showPlaying", "Automatically"))
            onPicked: (v) => { Shell.eset("sound.showPlaying", v); rev++ }
        }
    }

    Item { width: 1; height: 2 }
}
