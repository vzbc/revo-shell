import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import ".."

Item {
    id: root

    property bool hasPolledOnce: false
    property bool hasAdapter: true
    property bool isPowered: true
    property bool isScanning: false
    property string activeDeviceName: ""
    property string connectingMac: ""

    readonly property real cardMargin: Config.cardMargin !== undefined ? Config.cardMargin : 12

    ListModel { id: btModel }

    Component.onCompleted: {
        fetchBtStatusProc.running = false
        fetchBtStatusProc.running = true
    }

    function getDeviceIcon(name) {
        let n = (name || "").toLowerCase()
        if (n.includes("headphone") || n.includes("headset") || n.includes("airpod") || n.includes("wh-") || n.includes("wf-") || n.includes("buds") || n.includes("audio") || n.includes("earphone") || n.includes("pods")) return "headphones"
        if (n.includes("speaker") || n.includes("soundbar") || n.includes("echo") || n.includes("jbl") || n.includes("bose") || n.includes("marshall")) return "speaker"
        if (n.includes("mouse") || n.includes("trackpad") || n.includes("touchpad") || n.includes("mx master") || n.includes("mx anywhere")) return "mouse"
        if (n.includes("keyboard") || n.includes("keychron") || n.includes("nuphy") || n.includes("logi k")) return "keyboard"
        if (n.includes("controller") || n.includes("gamepad") || n.includes("xbox") || n.includes("dualshock") || n.includes("dualsense") || n.includes("joy-con") || n.includes("switch")) return "sports_esports"
        if (n.includes("phone") || n.includes("iphone") || n.includes("pixel") || n.includes("galaxy") || n.includes("android")) return "smartphone"
        if (n.includes("watch") || n.includes("band") || n.includes("garmin") || n.includes("fitbit")) return "watch"
        if (n.includes("macbook") || n.includes("laptop") || n.includes("desktop") || n.includes("thinkpad") || n.includes("pc")) return "computer"
        return "bluetooth"
    }

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: parent.width
            spacing: root.cardMargin

            // ==========================================
            // HEADER & DESCRIPTION
            // ==========================================
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    text: "BLUETOOTH WIRELESS"
                    color: Config.textMain
                    font.family: Config.sysFont
                    font.pixelSize: Config.size(Config.fontSubhead)
                    font.bold: true
                }

                Text {
                    text: "Manage Bluetooth controller state, discover discoverable peripherals, pair wireless audio accessories, and configure trusted devices."
                    color: Config.textMuted
                    font.family: Config.sysFont
                    font.pixelSize: Config.size(Config.fontCaption)
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }
            }

            // ==========================================
            // 1. HERO CONTROLLER & STATUS CARD
            // ==========================================
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: heroRow.implicitHeight + 28
                radius: Config.cornerRadius
                color: Qt.rgba(255, 255, 255, 0.05)
                border.width: 1
                border.color: Qt.rgba(255, 255, 255, 0.1)

                RowLayout {
                    id: heroRow
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 14

                    // Hero Status Icon Badge
                    Rectangle {
                        implicitWidth: 44
                        implicitHeight: 44
                        radius: 22
                        color: (root.isPowered && root.hasAdapter)
                            ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.2)
                            : Qt.rgba(255, 255, 255, 0.06)
                        border.width: 1.5
                        border.color: (root.isPowered && root.hasAdapter) ? Config.accent : Qt.rgba(255, 255, 255, 0.15)

                        Behavior on color { ColorAnimation { duration: 200 } }
                        Behavior on border.color { ColorAnimation { duration: 200 } }

                        Text {
                            anchors.centerIn: parent
                            text: !root.hasAdapter ? "bluetooth_disabled" : (root.isPowered ? (root.activeDeviceName !== "" ? "bluetooth_connected" : "bluetooth") : "bluetooth_disabled")
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 22
                            color: (root.isPowered && root.hasAdapter) ? Config.accent : Config.textMuted
                        }
                    }

                    // Status Text
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        RowLayout {
                            spacing: 8
                            Text {
                                text: "Bluetooth Adapter"
                                font.family: Config.sysFont
                                font.bold: true
                                color: Config.textMain
                                font.pixelSize: Config.size(Config.fontBody)
                            }

                            Rectangle {
                                implicitWidth: statusPillText.implicitWidth + 10
                                implicitHeight: 18
                                radius: 9
                                color: !root.hasAdapter
                                    ? Qt.rgba(255, 255, 255, 0.08)
                                    : (root.isPowered ? (root.activeDeviceName !== "" ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.2) : Qt.rgba(255, 255, 255, 0.1)) : Qt.rgba(255, 255, 255, 0.08))
                                border.width: 1
                                border.color: !root.hasAdapter
                                    ? Qt.rgba(255, 255, 255, 0.15)
                                    : (root.isPowered && root.activeDeviceName !== "" ? Config.accent : Qt.rgba(255, 255, 255, 0.15))

                                Text {
                                    id: statusPillText
                                    anchors.centerIn: parent
                                    text: !root.hasAdapter ? "NO CONTROLLER" : (!root.isPowered ? "POWERED OFF" : (root.activeDeviceName !== "" ? "CONNECTED" : "DISCOVERABLE"))
                                    font.family: Config.sysFont
                                    font.pixelSize: 9
                                    font.bold: true
                                    color: !root.hasAdapter
                                        ? Config.textMuted
                                        : (root.isPowered && root.activeDeviceName !== "" ? Config.accent : Config.textMuted)
                                }
                            }
                        }

                        Text {
                            text: !root.hasAdapter
                                ? "No Bluetooth controller hardware detected on this system"
                                : (!root.isPowered
                                    ? "Bluetooth controller is powered off"
                                    : (root.activeDeviceName !== "" ? ("Connected to " + root.activeDeviceName) : "Ready • Scanning for discoverable Bluetooth accessories"))
                            font.family: Config.sysFont
                            color: (root.isPowered && root.activeDeviceName !== "") ? Config.accent : Config.textMuted
                            font.pixelSize: Config.size(Config.fontCaption)
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    // Spacer to push action buttons to the right
                    Item { Layout.fillWidth: true }

                    // Action Buttons (Scan & Power Toggle)
                    RowLayout {
                        spacing: 8
                        Layout.alignment: Qt.AlignRight

                        // DISCOVER BUTTON
                        Rectangle {
                            implicitWidth: discRow.implicitWidth + 16
                            implicitHeight: 32
                            radius: 16
                            visible: root.isPowered && root.hasAdapter
                            color: discHover.hovered ? Qt.rgba(255, 255, 255, 0.12) : Qt.rgba(255, 255, 255, 0.06)
                            border.width: 1
                            border.color: Qt.rgba(255, 255, 255, 0.12)

                            Behavior on color { ColorAnimation { duration: 150 } }

                            RowLayout {
                                id: discRow
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    id: btScanIcon
                                    text: "refresh"
                                    font.family: "Material Symbols Outlined"
                                    font.pixelSize: 16
                                    color: discHover.hovered ? Config.accent : Config.textMain

                                    RotationAnimator {
                                        target: btScanIcon; from: 0; to: 360; duration: 1000
                                        loops: Animation.Infinite; running: root.isScanning
                                    }
                                }

                                Text {
                                    text: root.isScanning ? "Scanning..." : "Discover"
                                    font.family: Config.sysFont
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: discHover.hovered ? Config.accent : Config.textMain
                                }
                            }

                            TapHandler { onTapped: root.triggerScan() }
                            HoverHandler { id: discHover; cursorShape: Qt.PointingHandCursor }
                        }

                        // POWER TOGGLE BUTTON
                        Rectangle {
                            id: pwrBtBtn
                            implicitWidth: pwrBtRow.implicitWidth + 18
                            implicitHeight: 32
                            radius: 16
                            enabled: root.hasAdapter
                            color: (root.isPowered && root.hasAdapter)
                                ? (pwrBtHover.hovered ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.85) : Config.accent)
                                : (pwrBtHover.hovered ? Qt.rgba(255, 255, 255, 0.15) : Qt.rgba(255, 255, 255, 0.08))

                            Behavior on color { ColorAnimation { duration: 180 } }

                            RowLayout {
                                id: pwrBtRow
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    text: root.isPowered ? "power_settings_new" : "power_off"
                                    font.family: "Material Symbols Outlined"
                                    font.pixelSize: 16
                                    color: (root.isPowered && root.hasAdapter) ? Config.bgBase : Config.textMuted
                                }

                                Text {
                                    text: root.isPowered ? "ON" : "OFF"
                                    font.family: Config.sysFont
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: (root.isPowered && root.hasAdapter) ? Config.bgBase : Config.textMuted
                                }
                            }

                            TapHandler {
                                enabled: root.hasAdapter
                                onTapped: {
                                    powerBtProc.command = ["fish", "-c", "bluetoothctl power " + (root.isPowered ? "off" : "on")]
                                    powerBtProc.running = true
                                }
                            }
                            HoverHandler { id: pwrBtHover; cursorShape: Qt.PointingHandCursor }
                        }
                    }
                }
            }

            // ==========================================
            // 2. DISCOVERED & PAIRED DEVICES LIST
            // ==========================================
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                visible: root.hasAdapter && root.isPowered

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "PAIRED & NEARBY ACCESSORIES"
                        color: Config.textMuted
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontMicro)
                        font.bold: true
                    }

                    Rectangle {
                        implicitWidth: btCountText.implicitWidth + 10
                        implicitHeight: 16
                        radius: 8
                        color: Qt.rgba(255, 255, 255, 0.08)

                        Text {
                            id: btCountText
                            anchors.centerIn: parent
                            text: btModel.count.toString()
                            font.family: Config.sysFont
                            font.pixelSize: 9
                            font.bold: true
                            color: Config.textMuted
                        }
                    }

                    Item { Layout.fillWidth: true }
                }

                // DEVICES LIST
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Repeater {
                        model: btModel

                        delegate: Rectangle {
                            id: devCard
                            required property string mac
                            required property string name
                            required property bool connected
                            required property bool paired
                            readonly property bool isConnecting: root.connectingMac === mac

                            Layout.fillWidth: true
                            implicitHeight: devRow.implicitHeight + 20
                            radius: Config.cornerRadius * 0.75
                            color: connected
                                ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.12)
                                : (devHover.hovered ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(255, 255, 255, 0.04))
                            border.width: 1
                            border.color: connected
                                ? Config.accent
                                : (devHover.hovered ? Qt.rgba(255, 255, 255, 0.15) : Qt.rgba(255, 255, 255, 0.08))
                            clip: true

                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            RowLayout {
                                id: devRow
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 12

                                // Device Type Icon Badge
                                Rectangle {
                                    implicitWidth: 36
                                    implicitHeight: 36
                                    radius: 18
                                    color: connected
                                        ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.25)
                                        : Qt.rgba(255, 255, 255, 0.06)

                                    Text {
                                        anchors.centerIn: parent
                                        text: root.getDeviceIcon(name)
                                        font.family: "Material Symbols Outlined"
                                        font.pixelSize: 18
                                        color: connected ? Config.accent : Config.textMain
                                    }
                                }

                                // Device Name, MAC & Status Badges
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    RowLayout {
                                        spacing: 6

                                        Text {
                                            text: name
                                            color: connected ? Config.accent : Config.textMain
                                            font.family: Config.sysFont
                                            font.pixelSize: Config.size(Config.fontBody)
                                            font.bold: true
                                            elide: Text.ElideRight
                                            Layout.maximumWidth: 320
                                        }

                                        // PAIRED BADGE
                                        Rectangle {
                                            visible: paired && !connected
                                            implicitWidth: pairedBadgeText.implicitWidth + 8
                                            implicitHeight: 16
                                            radius: 8
                                            color: Qt.rgba(255, 255, 255, 0.1)

                                            Text {
                                                id: pairedBadgeText
                                                anchors.centerIn: parent
                                                text: "PAIRED"
                                                font.family: Config.sysFont
                                                font.pixelSize: 9
                                                font.bold: true
                                                color: Config.textMuted
                                            }
                                        }

                                        // CONNECTED ACTIVE BADGE
                                        Rectangle {
                                            visible: connected
                                            implicitWidth: activeBadgeText.implicitWidth + 8
                                            implicitHeight: 16
                                            radius: 8
                                            color: Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.25)
                                            border.width: 1
                                            border.color: Config.accent

                                            Text {
                                                id: activeBadgeText
                                                anchors.centerIn: parent
                                                text: "CONNECTED"
                                                font.family: Config.sysFont
                                                font.pixelSize: 9
                                                font.bold: true
                                                color: Config.accent
                                            }
                                        }
                                    }

                                    Text {
                                        text: `${mac} • ${connected ? "Active Audio/HID Link" : (paired ? "Trusted Profile" : "Discoverable Peripheral")}`
                                        color: Config.textMuted
                                        font.family: Config.sysFont
                                        font.pixelSize: Config.size(Config.fontMicro)
                                    }
                                }

                                // Spacer to push action buttons to the right
                                Item { Layout.fillWidth: true }

                                // Action Buttons
                                RowLayout {
                                    spacing: 6
                                    Layout.alignment: Qt.AlignRight

                                    // CONNECT / DISCONNECT / PAIR BUTTON
                                    Rectangle {
                                        implicitWidth: Math.max(actionRow.implicitWidth + 24, 76)
                                        implicitHeight: 30
                                        radius: 15
                                        color: isConnecting
                                            ? Qt.rgba(255, 255, 255, 0.1)
                                            : (actionHover.hovered
                                                ? (connected ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.2) : Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.85))
                                                : (connected ? Qt.rgba(255, 255, 255, 0.08) : Config.accent))
                                        border.width: connected ? 1 : 0
                                        border.color: actionHover.hovered && connected ? Config.accent : Qt.rgba(255, 255, 255, 0.12)

                                        RowLayout {
                                            id: actionRow
                                            anchors.centerIn: parent
                                            spacing: 6

                                            Text {
                                                text: connected ? "link_off" : (paired ? "login" : "add_link")
                                                font.family: "Material Symbols Outlined"
                                                font.pixelSize: 14
                                                color: connected
                                                    ? (actionHover.hovered ? Config.accent : Config.textMain)
                                                    : Config.bgBase
                                            }

                                            Text {
                                                id: actionBtnText
                                                text: isConnecting ? "..." : (connected ? "Disconnect" : (paired ? "Connect" : "Pair"))
                                                font.family: Config.sysFont
                                                font.bold: true
                                                font.pixelSize: 11
                                                color: connected
                                                    ? (actionHover.hovered ? Config.accent : Config.textMain)
                                                    : Config.bgBase
                                            }
                                        }

                                        TapHandler {
                                            onTapped: {
                                                if (isConnecting || !root.hasAdapter) return
                                                if (connected) {
                                                    root.execBtCmd(`bluetoothctl disconnect ${mac}`)
                                                } else if (paired) {
                                                    root.execBtCmd(`bluetoothctl connect ${mac}`, mac)
                                                } else {
                                                    root.execBtCmd(`bluetoothctl pair ${mac}; bluetoothctl trust ${mac}; bluetoothctl connect ${mac}`, mac)
                                                }
                                            }
                                        }
                                        HoverHandler { id: actionHover; cursorShape: Qt.PointingHandCursor }
                                    }

                                    // FORGET / UNPAIR BUTTON
                                    Rectangle {
                                        visible: true
                                        implicitWidth: 30
                                        implicitHeight: 30
                                        radius: 15
                                        color: forgetHover.hovered ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.2) : Qt.rgba(255, 255, 255, 0.06)
                                        border.width: 1
                                        border.color: forgetHover.hovered ? Config.accent : Qt.rgba(255, 255, 255, 0.1)

                                        Text {
                                            anchors.centerIn: parent
                                            text: "delete_outline"
                                            font.family: "Material Symbols Outlined"
                                            font.pixelSize: 15
                                            color: forgetHover.hovered ? Config.accent : Config.textMuted
                                        }

                                        TapHandler {
                                            onTapped: {
                                                if (!root.hasAdapter) return
                                                root.execBtCmd(`bluetoothctl disconnect ${mac}; bluetoothctl untrust ${mac}; bluetoothctl remove ${mac}`)
                                            }
                                        }
                                        HoverHandler { id: forgetHover; cursorShape: Qt.PointingHandCursor }
                                    }
                                }
                            }

                            HoverHandler { id: devHover; cursorShape: Qt.PointingHandCursor }
                        }
                    }
                }
            }

            // ==========================================
            // 3. EMPTY / DISABLED STATE CARD
            // ==========================================
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 160
                radius: Config.cornerRadius
                color: Qt.rgba(255, 255, 255, 0.03)
                border.width: 1
                border.color: Qt.rgba(255, 255, 255, 0.06)
                visible: root.hasPolledOnce && (!root.hasAdapter || !root.isPowered || (btModel.count === 0 && !root.isScanning))

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 10

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: !root.hasAdapter ? "bluetooth_disabled" : (!root.isPowered ? "bluetooth_disabled" : "bluetooth_searching")
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 36
                        color: Config.textMuted
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: !root.hasAdapter
                            ? "No Bluetooth controller detected"
                            : (!root.isPowered ? "Bluetooth is currently powered off" : "No nearby Bluetooth devices found")
                        font.family: Config.sysFont
                        font.bold: true
                        font.pixelSize: Config.size(Config.fontBody)
                        color: Config.textMain
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: !root.hasAdapter
                            ? "Check your system Bluetooth hardware or bluez daemon"
                            : (!root.isPowered ? "Toggle the controller power switch above to begin discovering devices" : "Put your accessory into pairing mode and click Discover")
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontCaption)
                        color: Config.textMuted
                    }
                }
            }
        }
    }

    // ==========================================
    // BACKEND IPC PROCESSES & TIMERS
    // ==========================================
    Timer { 
        interval: 3000; running: root.visible && root.hasAdapter; repeat: true; triggeredOnStart: true; 
        onTriggered: {
            fetchBtStatusProc.running = false
            fetchBtStatusProc.running = true
        }
    }

    Process { 
        id: powerBtProc; running: false; 
        onExited: {
            fetchBtStatusProc.running = false
            fetchBtStatusProc.running = true
        }
    }
    
    Process { 
        id: execBtProc
        running: false
        onExited: {
            root.connectingMac = ""
            fetchBtStatusProc.running = false
            fetchBtStatusProc.running = true 
        }
    }

    Process {
        id: fetchBtStatusProc
        command: ["fish", "-c", "bluetoothctl show"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let textStr = this.text
                root.hasPolledOnce = true
                if (!textStr || textStr.includes("No default controller available")) {
                    root.hasAdapter = false
                    root.isPowered = false
                    root.activeDeviceName = ""
                    btModel.clear()
                } else {
                    root.hasAdapter = true
                    root.isPowered = textStr.includes("Powered: yes")
                    if (root.isPowered) {
                        fetchBtDevicesProc.running = true
                    } else {
                        root.activeDeviceName = ""
                        btModel.clear()
                    }
                }
            }
        }
    }

    Process {
        id: fetchBtDevicesProc
        command: ["fish", "-c", "for dev in (bluetoothctl devices); set mac (string match -r '([0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}:[0-9A-Fa-f]{2})' $dev)[1]; if test -n '$mac'; bluetoothctl info $mac; echo '---DEV_END---'; end; end"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let chunks = this.text.trim().split("---DEV_END---")
                let newResults = []
                let seenMacs = {}
                let connectedNames = []

                for (let i = 0; i < chunks.length; i++) {
                    let text = chunks[i].trim()
                    if (!text) continue

                    let macMatch = text.match(/Device ([0-9A-FA-f:]+)/)
                    if (!macMatch) continue
                    let mac = macMatch[1]

                    if (seenMacs[mac]) continue
                    seenMacs[mac] = true

                    let nameMatch = text.match(/Name: (.*)/) || text.match(/Alias: (.*)/)
                    let name = nameMatch ? nameMatch[1].trim() : mac
                    let isConn = text.includes("Connected: yes")

                    if (isConn) {
                        connectedNames.push(name)
                    }

                    newResults.push({
                        mac: mac,
                        name: name,
                        connected: isConn,
                        paired: text.includes("Paired: yes")
                    })
                }

                root.activeDeviceName = connectedNames.length > 0 ? connectedNames.join(", ") : ""

                // Map current indices by MAC
                let existingMap = {}
                for (let idx = 0; idx < btModel.count; idx++) {
                    existingMap[btModel.get(idx).mac] = idx
                }

                let freshMap = {}
                let toAppend = []

                // In-place property updates to prevent layout jumping
                for (let k = 0; k < newResults.length; k++) {
                    let item = newResults[k]
                    freshMap[item.mac] = true

                    if (item.mac in existingMap) {
                        let tIndex = existingMap[item.mac]
                        let cur = btModel.get(tIndex)
                        if (cur.name !== item.name) btModel.setProperty(tIndex, "name", item.name)
                        if (cur.connected !== item.connected) btModel.setProperty(tIndex, "connected", item.connected)
                        if (cur.paired !== item.paired) btModel.setProperty(tIndex, "paired", item.paired)
                    } else {
                        toAppend.push(item)
                    }
                }

                // Append new devices to the end so row positions remain static
                for (let a = 0; a < toAppend.length; a++) {
                    btModel.append(toAppend[a])
                }

                // Remove vanished items from model
                for (let r = btModel.count - 1; r >= 0; r--) {
                    if (!freshMap[btModel.get(r).mac]) {
                        btModel.remove(r)
                    }
                }
            }
        }
    }

    function triggerScan() {
        if (!root.hasAdapter) return
        root.isScanning = true
        scanBtProc.command = ["fish", "-c", "bluetoothctl --timeout 5 scan on"]
        scanBtProc.running = true
    }

    Process { id: scanBtProc; running: false; onExited: { root.isScanning = false; fetchBtStatusProc.running = true } }
    
    function execBtCmd(cmd, mac = "") { 
        if (!root.hasAdapter) return
        root.connectingMac = mac
        execBtProc.command = ["fish", "-c", cmd]
        execBtProc.running = true 
    }
}