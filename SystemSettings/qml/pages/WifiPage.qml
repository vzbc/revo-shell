import QtQuick
import QtQuick.Controls
import ".."

Column {
    id: page

    property string pageId: "wifi"
    property string accountName: ""
    property string accountEmail: ""
    signal navigate(string pageId)

    readonly property var bumpU: Shell.userCfg
    readonly property var bumpE: Shell.eqCfg
    property int rev: 0

    width: parent ? parent.width : 640
    spacing: 12

    property bool wifiOn: true
    property string current: ""
    property var known: []
    property var others: []
    property string pending: ""
    property string failMsg: ""

    function uget(k, d) { bumpU; bumpE; return Shell.uget(k, d) }

    function splitF(line) {
        var parts = []
        var rest = line
        while (true) {
            var i = rest.lastIndexOf(":")
            if (i < 0) { parts.unshift(rest); break }
            parts.unshift(rest.slice(i + 1))
            rest = rest.slice(0, i)
        }
        return parts
    }

    function refresh() {
        wifiOn = Shell.execOut("nmcli radio wifi", 1200).indexOf("enabled") === 0

        var act = {}
        var activeOut = Shell.execOut("nmcli -t -f NAME,TYPE connection show --active", 1500)
        var al = activeOut.split("\n")
        for (var a = 0; a < al.length; a++) {
            var f = al[a].split(":")
            if (f.length >= 2 && f[1] === "802-11-wireless")
                act[f[0]] = true
        }

        var k = []
        var conn = Shell.execOut("nmcli -t -f NAME,TYPE connection show", 1500)
        var cl = conn.split("\n")
        for (var c = 0; c < cl.length; c++) {
            var g = cl[c].split(":")
            if (g.length >= 2 && g[1] === "802-11-wireless" && g[0].length > 0)
                k.push({ name: g[0], active: act[g[0]] === true })
        }
        known = k

        current = Shell.execOut("nmcli -t -f GENERAL.CONNECTION device show wlan0 | cut -d: -f2-", 1500)

        var knownNames = {}
        for (var n = 0; n < k.length; n++) knownNames[k[n].name] = true

        var o = []
        if (wifiOn) {
            var scan = Shell.execOut("nmcli -t -f SSID,SIGNAL,SECURITY,ACTIVE dev wifi list --rescan no", 2500)
            var sl = scan.split("\n")
            var seen = {}
            for (var s = 0; s < sl.length; s++) {
                if (sl[s].length === 0) continue
                var p = splitF(sl[s])
                if (p.length < 4) continue
                var ssid = p[0]
                if (ssid.length === 0 || seen[ssid]) continue
                seen[ssid] = true
                if (knownNames[ssid]) continue
                o.push({ ssid: ssid, signal: parseInt(p[1]) || 0, security: p[2], active: p[3] === "yes" })
            }
            o.sort(function (x, y) { return y.signal - x.signal })
        }
        others = o
        rev++
    }

    function securityLabel(sec) {
        if (!sec || sec.length === 0) return "Open"
        if (sec.indexOf("WPA3") >= 0) return "WPA3"
        if (sec.indexOf("WPA2") >= 0) return "WPA2"
        if (sec.indexOf("WEP") >= 0) return "WEP"
        return sec
    }

    function bars(sig) {
        if (sig >= 75) return "\u2582\u2583\u2584\u2585"
        if (sig >= 50) return "\u2582\u2583\u2584\u2581"
        if (sig >= 25) return "\u2582\u2583\u2581\u2581"
        return "\u2582\u2581\u2581\u2581"
    }

    function esc(s) { return "'" + String(s).replace(/'/g, "'\\''") + "'" }

    function connectSaved(name) {
        failMsg = ""
        if (known.find(function (k) { return k.name === name && k.active })) {
            Shell.run("nmcli connection down id " + esc(name) + " >/dev/null 2>&1 &")
        } else {
            Shell.run("nmcli connection up id " + esc(name) + " >/dev/null 2>&1")
        }
        rescan.restart()
    }

    function connectOpen(ssid) {
        failMsg = ""
        Shell.run("nmcli device wifi connect " + esc(ssid) + " >/dev/null 2>&1")
        rescan.restart()
    }

    function connectSecure(ssid, pass) {
        failMsg = ""
        Shell.run("nmcli device wifi connect " + esc(ssid) + " password " + esc(pass) + " >/dev/null 2>&1")
        rescan.restart()
    }

    Timer {
        id: rescan
        interval: 1400
        onTriggered: page.refresh()
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: page.refresh()
    }

    Placard {
        iconFile: "sb_wifi"
        title: "Wi-Fi"
        subtitle: page.wifiOn
                  ? (page.current.length > 0 ? page.current : "Not Connected")
                  : "Wi-Fi is off"
    }

    // ---------------- password prompt ----------------
    Popup {
        id: passDlg
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        width: 360
        height: passCol.implicitHeight + 36
        anchors.centerIn: Overlay.overlay

        background: Rectangle {
            radius: 12
            color: Theme.menuBg
            border.width: 1
            border.color: Theme.menuBorder
        }

        Column {
            id: passCol
            width: parent.width - 36
            x: 18
            y: 18
            spacing: 8

            Text {
                width: parent.width
                text: "The network \"" + page.pending + "\" requires a password."
                wrapMode: Text.WordWrap
                font { family: Theme.fontText; pixelSize: 13; weight: Font.DemiBold }
                color: Theme.textPrimary
            }

            TextField {
                id: passField
                width: parent.width
                placeholderText: "Password"
                echoMode: TextInput.Password
                font { family: Theme.fontText; pixelSize: 13 }
                color: Theme.textPrimary
                onAccepted: acceptPass()

                background: Rectangle {
                    radius: 7
                    color: Theme.checkBg
                    border.width: 1
                    border.color: Theme.checkBorder
                }
            }

            Text {
                width: parent.width
                visible: page.failMsg.length > 0
                text: page.failMsg
                wrapMode: Text.WordWrap
                font { family: Theme.fontText; pixelSize: 11 }
                color: Theme.red
            }

            Row {
                width: parent.width
                spacing: 8

                function acceptIt() { page.connectSecure(page.pending, passField.text); passDlg.close() }

                MacButton {
                    width: (parent.width - 8) / 2
                    text: "Cancel"
                    onClicked: passDlg.close()
                }
                MacButton {
                    width: (parent.width - 8) / 2
                    text: "Join"
                    primary: true
                    btnEnabled: passField.text.length > 0
                    onClicked: parent.acceptIt()
                }
            }
        }
    }

    function askPassword(ssid) {
        pending = ssid
        failMsg = ""
        passField.text = ""
        passDlg.open()
        passField.forceActiveFocus()
    }

    // ---------------- known networks ----------------
    SectionHeader { text: "Known Network"; visible: page.known.length > 0 }

    GroupCard {
        visible: page.known.length > 0
        width: parent.width

        Repeater {
            model: page.known

            delegate: DetailRow {
                required property var modelData
                required property int index
                width: parent.width
                title: modelData.name
                subtitle: modelData.active ? "Connected" : ""
                value: modelData.active ? "\u2713" : ""
                chevron: false
                onClicked: page.connectSaved(modelData.name)
                separator: index > 0
            }
        }
    }

    Item { width: 1; height: 4; visible: page.known.length > 0 }

    // ---------------- other networks ----------------
    SectionHeader {
        text: "Other Networks"
        visible: page.wifiOn && page.others.length > 0
    }

    GroupCard {
        visible: page.wifiOn && page.others.length > 0
        width: parent.width

        Repeater {
            model: page.others

            delegate: DetailRow {
                required property var modelData
                required property int index
                width: parent.width
                title: modelData.ssid
                subtitle: page.securityLabel(modelData.security)
                          + (modelData.security.length > 0 ? " \u00B7 " : " \u00B7 ")
                          + page.bars(modelData.signal) + " " + modelData.signal + "%"
                chevron: false
                separator: index > 0
                onClicked: {
                    if (modelData.security.length === 0)
                        page.connectOpen(modelData.ssid)
                    else
                        page.askPassword(modelData.ssid)
                }
            }
        }
    }

    Item { width: 1; height: 4; visible: page.others.length > 0 }

    SectionHeader { text: "Options" }

    GroupCard {
        DetailRow {
            title: "Wi-Fi"
            showSwitch: true
            switchOn: page.wifiOn
            onToggled: (c) => {
                Shell.run("nmcli radio wifi " + (c ? "on" : "off") + " >/dev/null 2>&1")
                page.wifiOn = c
                rescan.restart()
            }
        }
        DetailRow {
            separator: true
            title: "Ask to join networks"
            pickerOptions: ["Notify", "Ask to Join", "Don't Ask"]
            value: String(page.uget("wifi.askJoin", "Notify"))
            onPicked: (v) => { Shell.uset("wifi.askJoin", v); rev++ }
        }
        DetailRow {
            separator: true
            title: "Ask to join hotspots"
            pickerOptions: ["Notify", "Ask to Join", "Don't Ask"]
            value: String(page.uget("wifi.askHotspot", "Ask to Join"))
            onPicked: (v) => { Shell.uset("wifi.askHotspot", v); rev++ }
        }
        DetailRow {
            separator: true
            title: "Advanced\u2026"
            chevron: true
            onClicked: page.navigate("wifi.details")
        }
    }

    Text {
        x: 28
        width: parent.width - 56
        wrapMode: Text.WordWrap
        text: "Wi-Fi lets you connect to the internet and local network."
        font { family: Theme.fontText; pixelSize: 12 }
        color: Theme.textSecondary
    }

    Item { width: 1; height: 6 }
}
