import QtQuick
import ".."

Column {
    id: page

    property string pageId: "bluetooth"
    property string accountName: ""
    property string accountEmail: ""
    signal navigate(string pageId)

    readonly property var bumpU: Shell.userCfg
    readonly property var bumpE: Shell.eqCfg
    property int rev: 0

    width: parent ? parent.width : 640
    spacing: 12

    property bool btOn: true
    property bool scanning: false
    property var paired: []
    property var nearby: []

    function uget(k, d) { bumpU; bumpE; return Shell.uget(k, d) }
    function esc(s) { return "'" + String(s).replace(/'/g, "'\\''") + "'" }

    function info(mac, key, def) {
        var out = Shell.execOut("bluetoothctl info " + mac + " 2>/dev/null", 1800)
        var re = new RegExp("^\\s*" + key + ":\\s*(.*)$", "m")
        var m = out.match(re)
        return m ? m[1].trim() : def
    }

    function refresh() {
        btOn = Shell.execOut("bluetoothctl show 2>/dev/null | grep -m1 Powered | awk '{print $2}'", 1500) === "yes"
        scanning = Shell.execOut("bluetoothctl show 2>/dev/null | grep -m1 Discovering | awk '{print $2}'", 1500) === "yes"

        var p = []
        var n = []
        var out = Shell.execOut("bluetoothctl devices 2>/dev/null", 2000)
        var lines = out.split("\n")
        for (var i = 0; i < lines.length; i++) {
            var l = lines[i].trim()
            if (l.indexOf("Device ") !== 0) continue
            var mac = l.slice(7, 7 + 17)
            var name = l.slice(7 + 17 + 1).trim()
            if (mac.length < 17) continue
            var isPaired = info(mac, "Paired", "no") === "yes"
            var isConnected = info(mac, "Connected", "no") === "yes"
            var bat = info(mac, "Battery Percentage", "")
            var item = { mac: mac, name: name.length > 0 ? name : mac, connected: isConnected, battery: bat }
            if (isPaired) p.push(item)
            else n.push(item)
        }
        paired = p
        nearby = n
        rev++
    }

    function act(mac, cmds) {
        for (var i = 0; i < cmds.length; i++)
            Shell.run("bluetoothctl " + cmds[i] + " " + esc(mac) + " >/dev/null 2>&1")
        rescan.restart()
    }

    Timer {
        id: rescan
        interval: 1600
        onTriggered: page.refresh()
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: page.refresh()
    }

    Component.onCompleted: Shell.run("bluetoothctl scan on >/dev/null 2>&1")
    Component.onDestruction: Shell.run("bluetoothctl scan off >/dev/null 2>&1")

    Placard {
        iconFile: "sb_bluetooth"
        title: "Bluetooth"
        subtitle: page.btOn ? "On" : "Off"
    }

    GroupCard {
        DetailRow {
            title: "Bluetooth"
            showSwitch: true
            switchOn: page.btOn
            onToggled: (c) => {
                Shell.run("bluetoothctl power " + (c ? "on" : "off") + " >/dev/null 2>&1")
                page.btOn = c
                rescan.restart()
            }
        }
        DetailRow {
            separator: true
            title: "Now discoverable as \u201C" + Shell.execOut("hostname", 800) + "\u201D"
            dimmed: true
        }
    }

    Item { width: 1; height: 4 }

    SectionHeader { text: "My Devices" }

    GroupCard {
        width: parent.width

        Repeater {
            model: page.paired

            delegate: DetailRow {
                required property var modelData
                required property int index
                width: parent.width
                title: modelData.name
                subtitle: modelData.connected ? "Connected"
                          : (modelData.battery.length > 0 ? "Not Connected" : "Not Connected")
                value: modelData.battery.length > 0 ? modelData.battery : ""
                chevron: false
                separator: index > 0
                onClicked: {
                    if (modelData.connected)
                        page.act(modelData.mac, ["disconnect"])
                    else
                        page.act(modelData.mac, ["connect"])
                }
            }
        }

        DetailRow {
            visible: page.paired.length === 0
            title: "No Paired Devices"
            dimmed: true
        }
    }

    Item { width: 1; height: 4 }

    SectionHeader { text: "Nearby Devices" }

    GroupCard {
        width: parent.width

        Repeater {
            model: page.nearby

            delegate: DetailRow {
                required property var modelData
                required property int index
                width: parent.width
                title: modelData.name
                subtitle: "Not Paired"
                chevron: false
                separator: index > 0
                onClicked: page.act(modelData.mac, ["pair", "trust", "connect"])
            }
        }

        DetailRow {
            visible: page.nearby.length === 0
            title: page.btOn ? (page.scanning ? "Searching\u2026" : "Searching\u2026") : "Bluetooth is off"
            dimmed: true
        }
    }

    Item { width: 1; height: 4 }

    SectionHeader { text: "Options" }

    GroupCard {
        DetailRow {
            title: "Show Bluetooth in menu bar"
            showSwitch: true
            switchOn: page.uget("menubarBluetooth", true) === true
            onToggled: (c) => { Shell.uset("menubarBluetooth", c); Shell.uset("menubar.bluetooth", c); rev++ }
        }
        DetailRow {
            separator: true
            title: "Advanced\u2026"
            chevron: true
            onClicked: Shell.run("kitty --title 'Bluetooth' -e bluetoothctl info 2>/dev/null; sh -c 'read -r -p \"Press Enter\" _'")
        }
    }

    Item { width: 1; height: 6 }
}
