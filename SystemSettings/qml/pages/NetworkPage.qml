import QtQuick
import ".."

Column {
    id: page

    property string pageId: "network"
    property string accountName: ""
    property string accountEmail: ""
    signal navigate(string pageId)

    readonly property var bumpU: Shell.userCfg
    readonly property var bumpE: Shell.eqCfg
    property int rev: 0

    width: parent ? parent.width : 640
    spacing: 12

    property var nets: []
    property var vpns: []
    property string wifiSsid: ""
    property string wifiState: "Not Connected"
    property bool firewall: false
    property bool location: true

    function uget(k, d) { bumpU; bumpE; return Shell.uget(k, d) }
    function esc(s) { return "'" + String(s).replace(/'/g, "'\\''") + "'" }

    function refresh() {
        var out = Shell.execOut("nmcli -t -f DEVICE,TYPE,STATE dev", 2000)
        var lines = out.split("\n")
        var list = []
        for (var i = 0; i < lines.length; i++) {
            var f = lines[i].split(":")
            if (f.length < 3) continue
            var dev = f[0], type = f[1], state = f[2]
            if (type === "wifi" && dev.indexOf("p2p-") === 0) continue
            if (state === "unmanaged") continue
            list.push({ dev: dev, type: type, state: state })
        }
        nets = list

        var wifi = list.find(function (n) { return n.type === "wifi" && n.state.indexOf("connected") === 0 })
        wifiState = wifi ? wifi.state : "Not Connected"
        wifiSsid = wifi ? Shell.execOut("nmcli -t -f GENERAL.CONNECTION device show " + wifi.dev + " | cut -d: -f2-", 1500) : ""

        var v = []
        var conns = Shell.execOut("nmcli -t -f NAME,TYPE,DEVICE connection show", 2000)
        var cl = conns.split("\n")
        for (var c = 0; c < cl.length; c++) {
            var g = cl[c].split(":")
            if (g.length >= 3 && g[1] === "vpn")
                v.push({ name: g[0], device: g[2], active: g[2].length > 0 })
        }
        vpns = v

        firewall = Shell.execOut("systemctl is-active ufw 2>/dev/null", 1200) === "active"
        rev++
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: page.refresh()
    }

    function label(n) {
        if (n.type === "wifi") return n.state.indexOf("connected") === 0 ? "Connected" : n.state
        if (n.type === "ethernet") return n.state.indexOf("connected") === 0 ? "Connected" : (n.state === "unavailable" ? "Not Connected" : n.state)
        if (n.type === "tun") return "Connected"
        return n.state
    }

    Placard {
        iconFile: "sb_local-network"
        title: "Network"
    }

    GroupCard {
        width: parent.width

        DetailRow {
            title: "Wi-Fi"
            subtitle: page.wifiState
            value: page.wifiSsid
            chevron: true
            onClicked: page.navigate("wifi")
        }

        Repeater {
            model: page.nets.filter(function (n) { return n.type !== "wifi" })

            delegate: DetailRow {
                required property var modelData
                required property int index
                width: parent.width
                separator: index > 0 || true
                title: modelData.type === "ethernet" ? "Ethernet"
                       : modelData.type === "tun" ? "VPN Tunnel"
                       : modelData.dev
                subtitle: page.label(modelData)
                chevron: false
            }
        }

        Repeater {
            model: page.vpns

            delegate: DetailRow {
                required property var modelData
                required property int index
                width: parent.width
                separator: true
                title: modelData.name
                subtitle: modelData.active ? "Connected" : "Off"
                chevron: false
                onClicked: Shell.run("nmcli connection " + (modelData.active ? "down" : "up")
                                     + " id " + page.esc(modelData.name) + " >/dev/null 2>&1")
            }
        }
    }

    Item { width: 1; height: 4 }

    SectionHeader { text: "Other Services" }

    GroupCard {
        DetailRow {
            title: "Thunderbolt Bridge"
            subtitle: "Not Connected"
            chevron: false
        }
        DetailRow {
            separator: true
            title: "Bluetooth PAN"
            subtitle: "Off"
            chevron: false
        }
    }

    Item { width: 1; height: 4 }

    SectionHeader { text: "Options" }

    GroupCard {
        DetailRow {
            title: "Firewall"
            showSwitch: true
            switchOn: page.firewall
            onToggled: (c) => {
                Shell.run((c ? "pkexec systemctl enable --now ufw" : "pkexec systemctl disable --now ufw")
                          + " >/dev/null 2>&1")
                page.firewall = c
                page.rev++
            }
        }
        DetailRow {
            separator: true
            title: "Block all incoming connections"
            showSwitch: true
            switchOn: page.uget("net.blockAll", false) === true
            onToggled: (c) => { Shell.uset("net.blockAll", c); rev++ }
        }
        DetailRow {
            separator: true
            title: "Location Services"
            showSwitch: true
            switchOn: page.uget("privacy.location", true) === true
            onToggled: (c) => { Shell.uset("privacy.location", c); rev++ }
        }
        DetailRow {
            separator: true
            title: "VPN Configuration\u2026"
            chevron: true
            onClicked: page.navigate("network.vpn")
        }
    }

    Text {
        x: 28
        width: parent.width - 56
        wrapMode: Text.WordWrap
        text: "Network services are managed by NetworkManager."
        font { family: Theme.fontText; pixelSize: 12 }
        color: Theme.textSecondary
    }

    Item { width: 1; height: 6 }
}
