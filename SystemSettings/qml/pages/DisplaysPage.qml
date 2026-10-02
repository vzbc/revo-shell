import QtQuick
import ".."
import "../Pages.js" as Pages

Column {
    id: page

    property string pageId: "displays"
    property string accountName: ""
    property string accountEmail: ""
    signal navigate(string pageId)

    readonly property var bumpU: Shell.userCfg
    readonly property var bumpE: Shell.eqCfg
    property int rev: 0

    property var disp: ({ brightness: -1, name: "", scale: 1, width: 0, height: 0, refreshRate: 60 })
    property var mons: []

    readonly property string dispLabel: {
        var make = String(disp.make || "").replace(/\s+$/, "")
        var model = String(disp.model || "").replace(/^\s+|\s+$/g, "")
        if (model.length > 0 && model !== "Unknown")
            return make.length > 0 ? make + " " + model : model
        if (make.length > 0)
            return make + " Display"
        return disp.name.length > 0 ? disp.name : "Display"
    }

    readonly property var hzOptions: {
        bumpE
        var src = mons.length > 0 && mons[0].modes ? mons[0].modes : []
        var out = []
        for (var i = 0; i < src.length; i++) {
            var t = String(src[i])
            var at = t.indexOf("@")
            if (at < 0)
                continue
            var hz = Math.round(parseFloat(t.slice(at + 1)))
            if (hz > 0 && out.indexOf(hz) < 0)
                out.push(hz)
        }
        out.sort(function (a, b) { return b - a })
        if (out.length === 0)
            out = [Math.round(disp.refreshRate > 0 ? disp.refreshRate : 60)]
        return out
    }

    function eget(k, d) { bumpU; bumpE; return Shell.eget(k, d) }
    function uget(k, d) { bumpU; bumpE; return Shell.uget(k, d) }

    width: parent ? parent.width : 640
    spacing: 12

    Timer {
        interval: 900
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            page.disp = Shell.displayState()
            page.mons = Shell.displays()
        }
    }

    readonly property int resolutionIndex: {
        bumpE
        var s = Number(Shell.eget("display.scale", 1))
        if (s >= 1.2) return 0
        if (s <= 0.85) return 2
        return 1
    }

    Placard {
        iconFile: "sb_display"
        title: "Displays"
    }

    // ---------- animated preview ----------
    Item {
        width: parent.width
        height: Math.round(width * 0.46)

        Rectangle {
            id: bezel
            anchors.centerIn: parent
            width: parent.width * 0.72
            height: parent.height * 0.80
            radius: 12
            color: Theme.dark ? "#0d0d10" : "#2a2a2e"
            border.width: 3
            border.color: Theme.dark ? "#3a3a40" : "#1a1a1e"
        }

        Rectangle {
            anchors.fill: bezel
            anchors.margins: 4
            radius: 8
            clip: true
            gradient: Gradient {
                GradientStop { position: 0.0; color: Theme.accent }
                GradientStop { position: 0.6; color: Theme.dark ? "#25304a" : "#7f9ad0" }
                GradientStop { position: 1.0; color: Theme.dark ? "#11131a" : "#4f5f80" }
            }

            // sample content that scales with the resolution choice
            Item {
                id: sample
                anchors.centerIn: parent
                width: parent.width * 0.8
                height: parent.height * 0.7
                scale: [1.18, 1.0, 0.84][page.resolutionIndex]
                Behavior on scale { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }

                Column {
                    anchors.centerIn: parent
                    spacing: 8

                    Rectangle { width: 150; height: 14; radius: 7; color: Qt.rgba(1, 1, 1, 0.85) }
                    Rectangle { width: 110; height: 9; radius: 4.5; color: Qt.rgba(1, 1, 1, 0.5) }
                    Rectangle { width: 130; height: 9; radius: 4.5; color: Qt.rgba(1, 1, 1, 0.35) }
                    Row {
                        spacing: 8
                        Rectangle { width: 34; height: 34; radius: 9; color: Qt.rgba(1, 1, 1, 0.7) }
                        Rectangle { width: 34; height: 34; radius: 9; color: Qt.rgba(1, 1, 1, 0.5) }
                        Rectangle { width: 34; height: 34; radius: 9; color: Qt.rgba(1, 1, 1, 0.3) }
                    }
                }
            }

            // brightness veil follows the real backlight value
            Rectangle {
                anchors.fill: parent
                color: "black"
                opacity: page.disp.brightness >= 0
                    ? Math.max(0, Math.min(0.75, (100 - page.disp.brightness) / 100 * 0.75)) : 0
                Behavior on opacity { NumberAnimation { duration: 180 } }
            }

            Text {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 8
                anchors.horizontalCenter: parent.horizontalCenter
                text: page.disp.width > 0
                      ? page.disp.width + " \u00D7 " + page.disp.height
                        + "  \u00B7  " + Math.round(page.disp.refreshRate) + " Hz"
                      : "Display"
                font.family: Theme.fontText
                font.pixelSize: 11
                color: Qt.rgba(1, 1, 1, 0.85)
            }
        }

        // stand
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: bezel.horizontalCenter
            width: 90
            height: 8
            radius: 3
            color: Theme.dark ? "#26262b" : "#3c3c42"
        }
    }

    SectionHeader { text: "Brightness" }

    GroupCard {
        DetailRow {
            title: "Brightness"
            isSlider: true
            sliderValue: page.disp.brightness >= 0 ? page.disp.brightness / 100 : 0.5
            onMoved: (r) => {
                page.disp.brightness = Math.round(r * 100)
                Shell.setBrightness(r)
            }
        }
        DetailRow {
            separator: true
            title: "Automatically adjust brightness"
            showSwitch: true
            switchOn: eget("display.autoBrightness", false) === true
            onToggled: (c) => { Shell.eset("display.autoBrightness", c); rev++ }
        }
        DetailRow {
            title: "True Tone"
            showSwitch: true
            switchOn: eget("display.trueTone", true) === true
            onToggled: (c) => { Shell.eset("display.trueTone", c); rev++ }
        }
    }

    Item { width: 1; height: 4 }

    SectionHeader { text: "Night Shift" }

    GroupCard {
        DetailRow {
            title: "Night Shift"
            showSwitch: true
            switchOn: eget("display.nightShift", false) === true
            onToggled: (c) => {
                Shell.eset("display.nightShift", c)
                Shell.run(c
                    ? "systemctl --user start hyprsunset.service >/dev/null 2>&1; sleep 0.5; hyprctl hyprsunset temperature 4500 >/dev/null 2>&1"
                    : "hyprctl hyprsunset temperature 6500 >/dev/null 2>&1")
                rev++
            }
        }
        DetailRow {
            separator: true
            title: "Schedule"
            pickerOptions: ["Off", "Sunset to Sunrise", "Custom"]
            value: String(eget("display.nightShiftSchedule", "Off"))
            onPicked: (v) => { Shell.eset("display.nightShiftSchedule", v); rev++ }
        }
        DetailRow {
            title: "Colour temperature"
            isSlider: true
            sliderValue: {
                bumpE
                return Math.max(0, Math.min(1, (Number(Shell.eget("display.nightTemp", 4500)) - 2500) / 5000))
            }
            onMoved: (r) => {
                var t = Math.round((2500 + r * 5000) / 100) * 100
                Shell.eset("display.nightTemp", t)
                Shell.run("hyprctl hyprsunset temperature " + t + " >/dev/null 2>&1")
                rev++
            }
        }
    }

    Item { width: 1; height: 4 }

    SectionHeader { text: "Resolution" }

    GroupCard {
        Repeater {
            model: [
                { label: "Larger Text", scale: 1.25, hint: "Easier to read items on your display." },
                { label: "Default", scale: 1.0, hint: "Usually the best option for your display." },
                { label: "More Space", scale: 0.85, hint: "More room for windows and apps." }
            ]

            delegate: DetailRow {
                required property var modelData
                required property int index
                separator: index > 0
                iconFile: index === 0 ? "dt_display2" : ""
                title: modelData.label
                subtitle: modelData.hint
                showSwitch: true
                switchOn: page.resolutionIndex === index
                onToggled: (c) => {
                    if (!c)
                        return
                    Shell.eset("display.scale", modelData.scale)
                    Shell.setMonitorScale(modelData.scale)
                    page.disp = Shell.displayState()
                    rev++
                }
                onClicked: {
                    Shell.eset("display.scale", modelData.scale)
                    Shell.setMonitorScale(modelData.scale)
                    page.disp = Shell.displayState()
                    rev++
                }
            }
        }
    }

    Item { width: 1; height: 4 }

    SectionHeader { text: "Display" }

    GroupCard {
        DetailRow {
            title: page.dispLabel
            subtitle: (page.disp.width > 0
                       ? page.disp.width + " \u00D7 " + page.disp.height + "  \u00B7  "
                         + Math.round(page.disp.refreshRate) + " Hz  \u00B7  "
                         + page.disp.scale + "\u00D7" : "")
                       + (page.disp.name.length > 0 ? "\n" + page.disp.name : "")
            chevron: true
            onClicked: Shell.run("hyprctl monitors >> /tmp/opencode/monitors.txt 2>&1")
        }
        DetailRow {
            separator: true
            title: "Brightness"
            isSlider: true
            sliderValue: page.disp.brightness >= 0 ? page.disp.brightness / 100 : 0.5
            onMoved: (r) => {
                page.disp.brightness = Math.round(r * 100)
                Shell.setBrightness(r)
            }
        }
    }

    Item { width: 1; height: 4 }

    SectionHeader { text: "Refresh Rate" }

    GroupCard {
        Repeater {
            model: page.hzOptions

            delegate: DetailRow {
                required property var modelData
                required property int index
                separator: index > 0
                title: modelData + " Hz"
                showSwitch: true
                switchOn: Math.round(page.disp.refreshRate) === modelData
                onToggled: (c) => {
                    if (!c)
                        return
                    Shell.setMonitorRefresh(modelData)
                    page.disp = Shell.displayState()
                    page.mons = Shell.displays()
                    rev++
                }
                onClicked: {
                    Shell.setMonitorRefresh(modelData)
                    page.disp = Shell.displayState()
                    page.mons = Shell.displays()
                    rev++
                }
            }
        }
    }

    Item { width: 1; height: 4 }

    SectionHeader { text: "Advanced" }

    GroupCard {
        DetailRow {
            title: "Colour profile"
            pickerOptions: ["Built-in Display", "sRGB IEC61966-2.1", "Display P3"]
            value: String(eget("display.profile", "Built-in Display"))
            onPicked: (v) => { Shell.eset("display.profile", v); rev++ }
        }
        DetailRow {
            title: "Show in menu bar"
            showSwitch: true
            switchOn: uget("menubarDisplay", true) === true
            onToggled: (c) => { Shell.uset("menubarDisplay", c); Shell.uset("menubar.display", c); rev++ }
        }
        DetailRow {
            separator: true
            title: "Show in Stage Manager"
            showSwitch: true
            switchOn: eget("display.stageManager", false) === true
            onToggled: (c) => { Shell.eset("display.stageManager", c); rev++ }
        }
    }

    Item { width: 1; height: 2 }
}
