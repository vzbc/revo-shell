import QtQuick
import ".."

// Battery (macOS 27, PowerPreferences.appex): Energy Mode, Battery Health,
// Usage History charts (UPower's own history + journal boot sessions) and
// Options…. pageIds: battery | battery.health | battery.options
Column {
    id: page

    property string pageId: "battery"
    property string accountName: ""
    property string accountEmail: ""
    signal navigate(string pageId)

    readonly property var bumpU: Shell.userCfg
    property int rev: 0
    function ug(k, d) { bumpU; rev; return Shell.uget(k, d) }
    function us(k, v) { Shell.uset(k, v); rev++ }

    width: parent ? parent.width : 640
    spacing: 12

    property var bat: ({ pct: -1, state: "", health: -1, full: "", design: "", ac: false })
    property var hist: null
    property int range: 0          // 0 = Last 24 Hours, 1 = Last 10 Days

    function kv(out, key) {
        const m = out.match(new RegExp("^\\s*" + key + ":\\s*(.+)$", "m"))
        return m ? m[1].trim() : ""
    }
    function refresh() {
        const dev = Shell.execOut("upower -e 2>/dev/null | grep -m1 '/battery_'", 1500)
        const o = dev ? Shell.execOut("upower -i " + dev + " 2>/dev/null", 2000) : ""
        bat = {
            pct: parseFloat(kv(o, "percentage")) || -1,
            state: kv(o, "state"),
            health: parseFloat(kv(o, "capacity")) || -1,
            full: kv(o, "energy-full"),
            design: kv(o, "energy-full-design"),
            ac: Shell.execOut("cat /sys/class/power_supply/A*/online /sys/class/power_supply/AC*/online 2>/dev/null | head -1", 800) === "1"
        }
        const script = HOME_DIR + "/.cache/systemsettings/battery_history.py"
        Shell.writeFile(script, Shell.readFile(":/scripts/battery_history.py"))
        try { hist = JSON.parse(Shell.execOut("python3 -I " + script, 8000) || "null") } catch (e) { hist = null }
    }
    Component.onCompleted: { Shell.execOut("mkdir -p " + HOME_DIR + "/.cache/systemsettings", 1000); refresh() }

    readonly property string condition: bat.health < 0 ? "Normal" : (bat.health >= 80 ? "Normal" : "Service Recommended")

    // Energy Mode ↔ power-profiles-daemon; the row for the current power source applies now
    readonly property var modes: ["Automatic", "Low Power", "High Power"]
    function profileFor(m) { return m === "Low Power" ? "power-saver" : m === "High Power" ? "performance" : "balanced" }
    function setMode(key, v, isCurrent) {
        us(key, v)
        if (isCurrent) Shell.run("powerprofilesctl set " + profileFor(v) + " >/dev/null 2>&1")
    }
    function modeText(m) {
        return m === "Low Power" ? "Your Mac will reduce energy usage to increase battery life and operate more quietly."
             : m === "High Power" ? "Your Mac will optimize performance to better support resource-intensive tasks. This may result in louder fan noise."
             : "Your Mac will automatically choose the best level of performance and energy usage."
    }

    function fmtTime(t) {
        const d = new Date(t * 1000), now = new Date()
        const day = d.toDateString() === now.toDateString() ? "Today"
                  : new Date(now - 86400000).toDateString() === d.toDateString() ? "Yesterday"
                  : d.toLocaleDateString(Qt.locale("en_US"), "ddd d MMM")
        return day + ", " + d.toLocaleTimeString(Qt.locale("en_US"), "h:mm AP")
    }

    component Note: Text {
        x: Theme.cardMargin + 4
        width: page.width - 2 * (Theme.cardMargin + 4)
        visible: text.length > 0
        wrapMode: Text.WordWrap
        font.family: Theme.fontText; font.pixelSize: 12; color: Theme.textSecondary
    }

    // ---------------------------------------------------------------- chart
    component BarChart: Item {
        id: ch
        property var values: []          // numbers, < 0 = no data
        property var charging: []        // bools (green hatch while charging)
        property real maxV: 100
        property var yLabels: []         // [top, mid, bottom]
        property var xLabels: []         // [{at: 0..1, text}]
        property color barColor: "#30D158"
        property real barGap: 2
        width: parent ? parent.width : 100
        height: 128
        readonly property real plotW: width - 44
        readonly property real plotH: height - 22

        // grid
        Repeater {
            model: 3
            delegate: Canvas {
                required property int index
                x: 0; y: Math.round(index * ch.plotH / 2); width: ch.plotW; height: 1
                onPaint: {
                    const c = getContext("2d"); c.reset()
                    c.strokeStyle = Theme.dark ? "rgba(255,255,255,0.18)" : "rgba(0,0,0,0.16)"
                    c.setLineDash(index === 2 ? [] : [2, 3]); c.lineWidth = 1
                    c.beginPath(); c.moveTo(0, 0.5); c.lineTo(width, 0.5); c.stroke()
                }
            }
        }
        Repeater {
            model: ch.yLabels
            delegate: Text {
                required property var modelData
                required property int index
                x: ch.plotW + 6; y: index * ch.plotH / 2 - height / 2
                text: modelData; font.family: Theme.fontText; font.pixelSize: 10; color: Theme.textSecondary
            }
        }
        // bars
        Row {
            y: 0; height: ch.plotH
            spacing: ch.barGap
            Repeater {
                model: ch.values
                delegate: Item {
                    required property var modelData
                    required property int index
                    width: (ch.plotW - ch.barGap * (ch.values.length - 1)) / Math.max(1, ch.values.length)
                    height: ch.plotH
                    Rectangle {
                        visible: modelData >= 0
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: Math.max(modelData > 0 ? 2 : 0, ch.plotH * Math.min(1, modelData / ch.maxV))
                        radius: Math.min(2, width / 2)
                        color: ch.barColor
                        opacity: ch.charging[index] ? 0.55 : 1
                    }
                }
            }
        }
        // x labels
        Repeater {
            model: ch.xLabels
            delegate: Text {
                required property var modelData
                x: Math.min(ch.plotW - width, Math.max(0, modelData.at * ch.plotW - (modelData.center ? width / 2 : 0)))
                y: ch.plotH + 5
                text: modelData.text; font.family: Theme.fontText; font.pixelSize: 10; color: Theme.textSecondary
            }
        }
    }

    // ======================================================== Battery (main)
    Column {
        visible: page.pageId === "battery"
        width: page.width
        spacing: 12

        Placard { iconFile: "sb_battery"; title: "Battery" }

        SectionHeader { text: "Energy Mode" }
        GroupCard {
            DetailRow {
                title: "On battery"
                pickerOptions: page.modes
                value: String(page.ug("battery.modeBattery", "Automatic"))
                onPicked: (v) => page.setMode("battery.modeBattery", v, !page.bat.ac)
            }
            DetailRow {
                separator: true
                title: "On power adapter"
                pickerOptions: page.modes
                value: String(page.ug("battery.modeAdapter", "Automatic"))
                onPicked: (v) => page.setMode("battery.modeAdapter", v, page.bat.ac)
            }
        }
        Note { text: page.modeText(String(page.ug(page.bat.ac ? "battery.modeAdapter" : "battery.modeBattery", "Automatic"))) }

        GroupCard {
            DetailRow {
                title: "Battery Health"
                value: page.condition
                showInfo: true
                onInfoClicked: page.navigate("battery.health")
            }
        }

        // ------------------------------------------------- Usage History
        Item { width: 1; height: 2 }
        MacSegmented {
            anchors.horizontalCenter: parent.horizontalCenter
            options: ["Last 24 Hours", "Last 10 Days"]
            currentIndex: page.range
            onActivated: (i) => page.range = i
        }

        Rectangle {
            x: Theme.cardMargin
            width: parent.width - 2 * Theme.cardMargin
            height: histCol.implicitHeight + 32
            radius: Theme.cardRadius
            color: Theme.cardBg
            border.width: 1
            border.color: Theme.cardStroke

            Column {
                id: histCol
                x: 16; y: 16
                width: parent.width - 32
                spacing: 10

                // header: chart title + last charged
                Item {
                    width: parent.width; height: 32
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: page.range === 0 ? "Battery Level" : "Energy Usage"
                        font.family: Theme.fontText; font.pixelSize: 13; font.weight: Font.DemiBold; color: Theme.textPrimary
                    }
                    Column {
                        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                        visible: page.range === 0 && !!(page.hist && page.hist.lastCharged)
                        Text {
                            anchors.right: parent.right
                            text: page.hist && page.hist.lastCharged ? "Last charged to " + page.hist.lastCharged.p + "%" : ""
                            font.family: Theme.fontText; font.pixelSize: 11; font.weight: Font.DemiBold; color: Theme.textPrimary
                        }
                        Text {
                            anchors.right: parent.right
                            text: page.hist && page.hist.lastCharged ? page.fmtTime(page.hist.lastCharged.t) : ""
                            font.family: Theme.fontText; font.pixelSize: 11; color: Theme.textSecondary
                        }
                    }
                }

                // 24 h battery level
                BarChart {
                    visible: page.range === 0
                    values: page.hist ? page.hist.level.map(b => b.p) : []
                    charging: page.hist ? page.hist.level.map(b => b.c) : []
                    maxV: 100
                    barGap: 1
                    yLabels: ["100%", "50%", "0%"]
                    xLabels: {
                        if (!page.hist) return []
                        const out = [], s = page.hist.start24
                        for (let i = 1; i < 8; i++) {
                            const t = s + i * 3 * 3600, d = new Date(t * 1000)
                            const h = d.getHours(), hh = Math.floor(h / 3) * 3
                            out.push({ at: i / 8, center: true, text: (hh % 12 === 0 ? 12 : hh % 12) + " " + (hh < 12 ? "AM" : "PM") })
                        }
                        return out
                    }
                }
                // 10 d energy usage (percent of battery used per day)
                BarChart {
                    visible: page.range === 1
                    values: page.hist ? page.hist.used : []
                    maxV: Math.max(100, page.hist ? Math.max.apply(null, page.hist.used) : 100)
                    barGap: 10
                    barColor: "#30D158"
                    yLabels: ["100%", "50%", "0%"]
                    xLabels: page.hist ? page.hist.used.map((v, i) => ({ at: (i + 0.5) / 10, center: true,
                        text: new Date((page.hist.day0 - (9 - i) * 86400) * 1000).toLocaleDateString(Qt.locale("en_US"), "d") })) : []
                }

                Text {
                    text: "Screen On Usage"
                    font.family: Theme.fontText; font.pixelSize: 13; font.weight: Font.DemiBold; color: Theme.textPrimary
                }
                BarChart {
                    visible: page.range === 0
                    values: page.hist ? page.hist.hourly : []
                    maxV: 60
                    barGap: 3
                    barColor: "#0A84FF"
                    yLabels: ["60m", "30m", "0m"]
                    xLabels: {
                        if (!page.hist) return []
                        const out = [], s = page.hist.start24
                        for (let i = 1; i < 8; i++) {
                            const d = new Date((s + i * 3 * 3600) * 1000), hh = Math.floor(d.getHours() / 3) * 3
                            out.push({ at: i / 8, center: true, text: (hh % 12 === 0 ? 12 : hh % 12) + " " + (hh < 12 ? "AM" : "PM") })
                        }
                        return out
                    }
                }
                BarChart {
                    visible: page.range === 1
                    readonly property real topH: page.hist ? Math.max(4, Math.ceil(Math.max.apply(null, page.hist.daily) / 2) * 2) : 8
                    values: page.hist ? page.hist.daily : []
                    maxV: topH
                    barGap: 10
                    barColor: "#0A84FF"
                    yLabels: [topH + "h", (topH / 2) + "h", "0h"]
                    xLabels: page.hist ? page.hist.daily.map((v, i) => ({ at: (i + 0.5) / 10, center: true,
                        text: new Date((page.hist.day0 - (9 - i) * 86400) * 1000).toLocaleDateString(Qt.locale("en_US"), "d") })) : []
                }
            }
        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: Theme.cardMargin
            spacing: 10
            MacButton { text: "Options…"; onClicked: page.navigate("battery.options") }
            HelpCircle { anchors.verticalCenter: parent.verticalCenter }
        }
        Item { width: 1; height: 4 }
    }

    // ========================================================= Battery Health
    Column {
        visible: page.pageId === "battery.health"
        width: page.width
        spacing: 12

        Placard { iconFile: "sb_battery"; title: "Battery Health" }
        GroupCard {
            DetailRow { title: "Battery Condition"; value: page.condition }
            DetailRow {
                separator: true
                title: "Maximum Capacity"
                value: page.bat.health >= 0 ? Math.round(page.bat.health) + "%" : "—"
            }
        }
        Note { text: "This is a measure of battery capacity relative to when it was new. Lower capacity may result in fewer hours of usage between charges." }
        Note {
            text: page.condition === "Normal"
                ? "Mac batteries, like all rechargeable batteries, are consumable components that become less effective as they age."
                : "The battery’s capacity is significantly reduced. To restore capacity, please check your service options."
        }
        GroupCard {
            DetailRow {
                title: "Battery health management"
                subtitle: "As your battery ages, maximum capacity is reduced to extend battery lifespan."
                showSwitch: true
                switchOn: page.ug("battery.healthMgmt", true) === true
                onToggled: (c) => page.us("battery.healthMgmt", c)
            }
        }
        Item { width: 1; height: 4 }
    }

    // ============================================================== Options…
    Column {
        visible: page.pageId === "battery.options"
        width: page.width
        spacing: 12

        GroupCard {
            DetailRow {
                title: "Prevent automatic sleeping on power adapter when the display is off"
                showSwitch: true
                switchOn: page.ug("battery.neverSleepOnAC", false) === true
                onToggled: (c) => page.us("battery.neverSleepOnAC", c)
            }
            DetailRow {
                separator: true
                title: "Wake for network access"
                pickerOptions: ["Always", "Only on Power Adapter", "Never"]
                value: String(page.ug("battery.wakeNetwork", "Only on Power Adapter"))
                onPicked: (v) => page.us("battery.wakeNetwork", v)
            }
            DetailRow {
                separator: true
                title: "Optimize video streaming while on battery"
                showSwitch: true
                switchOn: page.ug("battery.hdrStreaming", false) === true
                onToggled: (c) => page.us("battery.hdrStreaming", c)
            }
            DetailRow {
                separator: true
                title: "Slightly dim the display while on battery power"
                showSwitch: true
                switchOn: page.ug("battery.dimOnBattery", true) === true
                onToggled: (c) => page.us("battery.dimOnBattery", c)
            }
        }
        Item { width: 1; height: 4 }
    }
}
