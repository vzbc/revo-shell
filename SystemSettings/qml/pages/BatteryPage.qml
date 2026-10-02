import QtQuick
import ".."

Column {
    id: page

    property string pageId: "battery"
    property string accountName: ""
    property string accountEmail: ""
    signal navigate(string pageId)

    readonly property var bumpU: Shell.userCfg
    readonly property var bumpE: Shell.eqCfg
    property int rev: 0

    width: parent ? parent.width : 640
    spacing: 12

    property var bat: ({ pct: -1, state: "", health: "", energy: "", design: "", remaining: "", ac: false })
    property string profile: "balanced"

    function uget(k, d) { bumpU; bumpE; return Shell.uget(k, d) }

    function kv(out, key) {
        var re = new RegExp("^\\s*" + key + ":\\s*(.*)$", "m")
        var m = out.match(re)
        return m ? m[1].trim() : ""
    }

    function refresh() {
        var dev = Shell.execOut("upower -e 2>/dev/null | grep -m1 '/battery_'", 1500)
        var o = dev.length > 0 ? Shell.execOut("upower -i " + dev + " 2>/dev/null", 2000) : ""
        var disp = Shell.execOut("upower -i /org/freedesktop/UPower/devices/DisplayDevice 2>/dev/null", 2000)
        var pct = kv(o, "percentage").replace("%", "")
        bat = {
            pct: pct.length > 0 ? parseFloat(pct) : -1,
            state: kv(o, "state"),
            health: kv(o, "capacity"),
            energy: kv(o, "energy"),
            design: kv(o, "energy-full-design"),
            remaining: kv(disp, "time to empty").length > 0
                       ? kv(disp, "time to empty") + " until empty"
                       : (kv(disp, "time to full").length > 0 ? kv(disp, "time to full") + " until full" : ""),
            ac: Shell.execOut("cat /sys/class/power_supply/ACAD/online 2>/dev/null", 800) === "1"
        }
        profile = Shell.execOut("powerprofilesctl get 2>/dev/null", 1200)
        rev++
    }

    Timer {
        interval: 8000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: page.refresh()
    }

    Placard {
        iconFile: "sb_battery"
        title: "Battery"
        subtitle: page.bat.pct >= 0
                  ? Math.round(page.bat.pct) + "% \u00B7 " + page.acText()
                  : "No Battery"
    }

    function acText() {
        if (bat.ac) return "Power Adapter"
        if (bat.state === "fully-charged") return "Fully Charged"
        if (bat.state === "charging") return "Charging"
        if (bat.state === "discharging") return "Battery"
        return bat.state
    }

    function cond() {
        var h = parseFloat(bat.health)
        if (isNaN(h)) return "Normal"
        return h >= 80 ? "Normal" : (h >= 60 ? "Service Recommended" : "Service Soon")
    }

    function timeLeft() {
        return bat.remaining.length > 0 ? bat.remaining : "\u2014"
    }

    // ---------- level card ----------
    Rectangle {
        x: 12
        width: parent.width - 24
        height: lvCol.implicitHeight + 36
        radius: 10
        color: Theme.cardBg

        Column {
            id: lvCol
            width: parent.width - 32
            x: 16
            y: 18
            spacing: 0

            Row {
                width: parent.width
                spacing: 12

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: page.bat.pct >= 0 ? Math.round(page.bat.pct) + "%" : "\u2014"
                    font { family: Theme.fontDisplay; pixelSize: 34; weight: Font.Bold }
                    color: Theme.textPrimary
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        text: page.acText()
                        font { family: Theme.fontText; pixelSize: 13; weight: Font.DemiBold }
                        color: Theme.textPrimary
                    }
                    Text {
                        text: page.timeLeft()
                        font { family: Theme.fontText; pixelSize: 12 }
                        color: Theme.textSecondary
                    }
                }
            }

            Item { width: 1; height: 14 }

            Rectangle {
                width: parent.width
                height: 10
                radius: 5
                color: Theme.dark ? "#2a2a2f" : "#e6e7ec"

                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, (page.bat.pct >= 0 ? page.bat.pct : 0) / 100))
                    height: parent.height
                    radius: 5
                    color: (page.bat.pct >= 0 && page.bat.pct <= 20 && !page.bat.ac) ? Theme.red : Theme.accent
                    Behavior on width { NumberAnimation { duration: 300 } }
                }
            }
        }
    }

    Item { width: 1; height: 4 }

    SectionHeader { text: "Battery" }

    GroupCard {
        DetailRow {
            title: "Low Power Mode"
            pickerOptions: ["Never", "Always"]
            value: String(page.uget("battery.lowPower", "Never"))
            onPicked: (v) => {
                Shell.uset("battery.lowPower", v)
                Shell.run("powerprofilesctl set " + (v === "Always" ? "power-saver" : "balanced") + " >/dev/null 2>&1")
                rescan.restart()
                rev++
            }
        }
        DetailRow {
            separator: true
            title: "Power Source"
            subtitle: page.ac ? "Power Adapter" : "Battery"
            pickerOptions: ["performance", "balanced", "power-saver"]
            value: page.profile
            onPicked: (v) => {
                Shell.run("powerprofilesctl set " + v + " >/dev/null 2>&1")
                rescan.restart()
            }
        }
        DetailRow {
            separator: true
            title: "Options\u2026"
            chevron: true
            onClicked: page.navigate("battery.options")
        }
    }

    Timer {
        id: rescan
        interval: 900
        onTriggered: page.refresh()
    }

    Item { width: 1; height: 4 }

    SectionHeader { text: "Power Source" }

    GroupCard {
        DetailRow {
            title: "Turn display off on battery when inactive"
            pickerOptions: ["Never", "2 Minutes", "5 Minutes", "10 Minutes", "20 Minutes"]
            value: String(page.uget("battery.displayOff", "10 Minutes"))
            onPicked: (v) => { Shell.uset("battery.displayOff", v); rev++ }
        }
        DetailRow {
            separator: true
            title: "Prevent automatic sleeping on power adapter when the display is off"
            showSwitch: true
            switchOn: page.uget("battery.noSleepAc", false) === true
            onToggled: (c) => { Shell.uset("battery.noSleepAc", c); rev++ }
        }
        DetailRow {
            separator: true
            title: "Start up automatically after a power failure"
            showSwitch: true
            switchOn: page.uget("battery.restartFailure", true) === true
            onToggled: (c) => { Shell.uset("battery.restartFailure", c); rev++ }
        }
    }

    Item { width: 1; height: 4 }

    SectionHeader { text: "Battery Health" }

    GroupCard {
        DetailRow {
            title: "Condition"
            value: page.cond()
        }
        DetailRow {
            separator: true
            title: "Maximum Capacity"
            value: page.bat.health.length > 0 ? page.bat.health : "\u2014"
        }
        DetailRow {
            separator: true
            title: "Full Charge Capacity"
            value: page.bat.energy.length > 0 ? page.bat.energy : "\u2014"
        }
        DetailRow {
            separator: true
            title: "Design Capacity"
            value: page.bat.design.length > 0 ? page.bat.design : "\u2014"
        }
    }

    Text {
        x: 28
        width: parent.width - 56
        wrapMode: Text.WordWrap
        text: "Battery data is read live from UPower."
        font { family: Theme.fontText; pixelSize: 12 }
        color: Theme.textSecondary
    }

    Item { width: 1; height: 6 }
}
