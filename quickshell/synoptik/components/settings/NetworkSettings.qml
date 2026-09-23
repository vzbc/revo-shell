import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import ".."

Item {
    id: root

    property string activeVpnName: ""
    property bool showFileBrowser: false
    property string currentBrowserPath: "file://" + Quickshell.env("HOME")

    property string downloadSpeed: "0 B/s"
    property string uploadSpeed: "0 B/s"
    property real currentRxSpeed: 0.0
    property real currentTxSpeed: 0.0
    property real maxSessionRx: 1024 * 1024
    property real maxSessionTx: 1024 * 512
    property var lastRxBytes: 0
    property var lastTxBytes: 0
    property var lastTime: 0
    property var lastTextUpdateTime: 0
    property int maxGraphPoints: 40
    property int updateInterval: 250

    // Visual Grid & Smooth Dynamic Scaling
    property int matrixRows: 10
    property real pixelRadius: 2.5
    property color colorDownload: Config.accent
    property color colorUpload: Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.65)
    property real activityPulse: Math.min(1.0, (currentRxSpeed + currentTxSpeed) / (1024 * 1024 * 2))

    Behavior on activityPulse {
        NumberAnimation { duration: 180; easing.type: Easing.OutQuad }
    }

    property real smoothPeakRx: 1024 * 512
    property real smoothPeakTx: 1024 * 256

    Behavior on smoothPeakRx {
        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
    }
    Behavior on smoothPeakTx {
        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
    }

    // Local Network State Tracking
    property string localIfName: "---"
    property string localConnName: ""
    property string localIpAddress: "Disconnected"
    property string localMacAddress: "---"
    property bool localConnected: false

    // Frame sync tracking for jitter-free scrolling
    property real lastPushTimestamp: Date.now()
    property real scrollProgress: 0.0

    readonly property real cardMargin: Config.cardMargin !== undefined ? Config.cardMargin : 12

    ListModel { id: vpnListModel }
    ListModel { id: graphHistoryModel }

    function formatRate(bytesPerSec) {
        if (bytesPerSec < 1024) return Math.max(0, bytesPerSec).toFixed(0) + " B/s"
        if (bytesPerSec < 1048576) return (bytesPerSec / 1024).toFixed(1) + " KB/s"
        return (bytesPerSec / 1048576).toFixed(1) + " MB/s"
    }

    function seedGraphModel() {
        graphHistoryModel.clear()
        for (let i = 0; i < root.maxGraphPoints + 1; i++) {
            graphHistoryModel.append({ "rxValue": 0.0, "txValue": 0.0 })
        }
    }

    Component.onCompleted: {
        seedGraphModel()
    }

    onVisibleChanged: {
        if (root.visible) {
            seedGraphModel()
            vpnListPopulator.running = false
            vpnListPopulator.running = true
            localNetQuery.running = false
            localNetQuery.running = true
        }
    }

    FrameAnimation {
        id: frameGraphSync
        running: root.visible
        onTriggered: {
            let elapsed = Date.now() - root.lastPushTimestamp
            root.scrollProgress = Math.min(elapsed / root.updateInterval, 1.0)
            pixelCanvas.requestPaint()
        }
    }

    Timer {
        interval: 3000
        running: root.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            vpnListPopulator.running = false
            vpnListPopulator.running = true
            localNetQuery.running = false
            localNetQuery.running = true
        }
    }

    // Graph Data Ticker
    Timer {
        interval: root.updateInterval
        running: root.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            graphHistoryModel.append({
                "rxValue": root.currentRxSpeed,
                "txValue": root.currentTxSpeed
            })
            if (graphHistoryModel.count > root.maxGraphPoints + 1) {
                graphHistoryModel.remove(0)
            }

            let maxRx = 1024 * 128
            let maxTx = 1024 * 64
            for (let i = 0; i < graphHistoryModel.count; i++) {
                let item = graphHistoryModel.get(i)
                if (item.rxValue > maxRx) maxRx = item.rxValue
                if (item.txValue > maxTx) maxTx = item.txValue
            }
            root.smoothPeakRx = maxRx
            root.smoothPeakTx = maxTx
            root.lastPushTimestamp = Date.now()
            root.scrollProgress = 0.0
        }
    }

    // LOCAL NETWORK STATUS QUERY
    Process {
        id: localNetQuery
        command: ["fish", "-c", `
            set dev (nmcli -g DEVICE,TYPE,STATE device | awk -F: '$2 ~ /ethernet|wifi/ {print $1; exit}')
            if test -z "$dev"
                set dev (ip route show | awk '/default/ {print $5}' | head -n1)
            end

            if test -n "$dev"
                set ip (ip -4 addr show dev $dev 2>/dev/null | awk '/inet / {print $2}' | cut -d/ -f1)
                set mac (cat /sys/class/net/$dev/address 2>/dev/null)
                set conn (nmcli -g GENERAL.CONNECTION device show $dev 2>/dev/null)
                set state (nmcli -g GENERAL.STATE device show $dev 2>/dev/null)
                
                if test -z "$ip"
                    set ip 'Disconnected'
                end
                if test -z "$mac"
                    set mac '---'
                end
                if test -z "$conn"
                    set conn '--'
                end
                if test -z "$state"
                    set state 'disconnected'
                end
                echo "$dev|$ip|$mac|$state|$conn"
            else
                echo 'none|Disconnected|---|disconnected|--'
            end
        `]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let clean = this.text.trim()
                if (!clean) return
                let parts = clean.split("|")
                if (parts.length >= 5) {
                    root.localIfName = parts[0] !== "none" ? parts[0] : "---"
                    root.localIpAddress = parts[1] ? parts[1] : "Disconnected"
                    root.localMacAddress = parts[2] ? parts[2].toUpperCase() : "---"
                    
                    let rawState = parts[3] ? parts[3].toLowerCase() : ""
                    let isConn = (parts[1] !== "Disconnected") && (rawState.indexOf("connected") !== -1) && (rawState.indexOf("disconnected") === -1)
                    root.localConnected = isConn

                    if (parts[4] && parts[4] !== "--" && parts[4] !== "") {
                        root.localConnName = parts[4]
                    }
                }
            }
        }
    }

    Process {
        id: localNetToggleProc
        running: false
        onExited: {
            localNetQuery.running = false
            localNetQuery.running = true
        }
    }

    function toggleLocalNetwork() {
        if (root.localIfName === "---") return
        let cmd = ""
        if (root.localConnected) {
            cmd = root.localConnName !== "" 
                ? `nmcli connection down id "${root.localConnName}"` 
                : `nmcli device disconnect ${root.localIfName}`
        } else {
            if (root.localConnName !== "") {
                cmd = `nmcli connection up id "${root.localConnName}" || nmcli device connect ${root.localIfName}`
            } else {
                cmd = `nmcli device connect ${root.localIfName}`
            }
        }
        localNetToggleProc.command = ["fish", "-c", cmd]
        localNetToggleProc.running = true
    }

    // High frequency bandwidth background sampler (gated on visibility + 0.25s sleep)
    Process {
        id: bandwidthStreamProc
        command: ["python3", "-u", "-c", `
import time, subprocess
try:
    dev = subprocess.check_output("ip route show | awk '/default/ {print $5}' | head -n1", shell=True).decode().strip()
except Exception:
    dev = ""
while True:
    try:
        with open("/proc/net/dev", "r") as f:
            for line in f:
                if dev and dev in line:
                    print(line.strip(), flush=True)
                    break
    except Exception:
        pass
    time.sleep(0.25)
        `]
        running: root.visible
        stdout: SplitParser {
            onRead: data => {
                let textStr = data.trim()
                if (!textStr) return
                let rawLineParts = textStr.split(":")
                if (rawLineParts.length < 2) return
                let parts = rawLineParts[1].trim().split(/\s+/)
                if (parts.length < 9) return

                let rx = parseInt(parts[0]) 
                let tx = parseInt(parts[8]) 
                let now = Date.now()

                if (root.lastTime > 0) {
                    let elapsed = (now - root.lastTime) / 1000
                    if (elapsed > 0) {
                        let rxSpeed = Math.max(0, (rx - root.lastRxBytes) / elapsed)
                        let txSpeed = Math.max(0, (tx - root.lastTxBytes) / elapsed)

                        root.currentRxSpeed = rxSpeed
                        root.currentTxSpeed = txSpeed

                        if (rxSpeed > root.maxSessionRx) root.maxSessionRx = rxSpeed
                        if (txSpeed > root.maxSessionTx) root.maxSessionTx = txSpeed

                        if (now - root.lastTextUpdateTime >= 200) {
                            root.downloadSpeed = root.formatRate(rxSpeed)
                            root.uploadSpeed = root.formatRate(txSpeed)
                            root.lastTextUpdateTime = now
                        }
                    }
                }
                root.lastRxBytes = rx
                root.lastTxBytes = tx
                root.lastTime = now
            }
        }
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
                    text: "NETWORK & TRAFFIC"
                    color: Config.textMain
                    font.family: Config.sysFont
                    font.pixelSize: Config.size(Config.fontSubhead)
                    font.bold: true
                }

                Text {
                    text: "Monitor real-time network throughput, configure physical Ethernet interfaces, and manage WireGuard and OpenVPN tunnels."
                    color: Config.textMuted
                    font.family: Config.sysFont
                    font.pixelSize: Config.size(Config.fontCaption)
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }
            }

            // ==========================================
            // 1. REAL-TIME PIXEL WAVE MATRIX MONITOR CARD
            // ==========================================
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: matrixCardContent.implicitHeight + 28
                radius: Config.cornerRadius
                color: Qt.rgba(255, 255, 255, 0.05)
                border.width: 1
                border.color: Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.12 + (root.activityPulse * 0.2))

                ColumnLayout {
                    id: matrixCardContent
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12

                    // Metrics & Peak Stats Row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 20

                        // Download Metric
                        RowLayout {
                            spacing: 8
                            Rectangle {
                                implicitWidth: 32; implicitHeight: 32; radius: 16
                                color: Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.18)
                                Text { anchors.centerIn: parent; text: "arrow_downward"; font.family: "Material Symbols Outlined"; font.pixelSize: 16; color: Config.accent }
                            }
                            ColumnLayout {
                                spacing: 1
                                Text { text: "DOWNLOAD"; font.family: Config.sysFont; font.pixelSize: Config.size(Config.fontMicro); color: root.colorDownload; font.bold: true }
                                Text { text: root.downloadSpeed; font.family: Config.sysFont; font.pixelSize: Config.size(Config.fontBody); font.bold: true; color: Config.textMain }
                            }
                        }

                        // Upload Metric
                        RowLayout {
                            spacing: 8
                            Rectangle {
                                implicitWidth: 32; implicitHeight: 32; radius: 16
                                color: Qt.rgba(255, 255, 255, 0.08)
                                Text { anchors.centerIn: parent; text: "arrow_upward"; font.family: "Material Symbols Outlined"; font.pixelSize: 16; color: root.colorUpload }
                            }
                            ColumnLayout {
                                spacing: 1
                                Text { text: "UPLOAD"; font.family: Config.sysFont; font.pixelSize: Config.size(Config.fontMicro); color: root.colorUpload; font.bold: true }
                                Text { text: root.uploadSpeed; font.family: Config.sysFont; font.pixelSize: Config.size(Config.fontBody); font.bold: true; color: Config.textMain }
                            }
                        }

                        Item { Layout.fillWidth: true }

                        // Peak session badge
                        Rectangle {
                            implicitWidth: peakLabel.implicitWidth + 14
                            implicitHeight: 24
                            radius: 12
                            color: Qt.rgba(255, 255, 255, 0.06)
                            border.width: 1
                            border.color: Qt.rgba(255, 255, 255, 0.1)

                            Text {
                                id: peakLabel
                                anchors.centerIn: parent
                                text: `↓ ${root.formatRate(root.maxSessionRx)}  ↑ ${root.formatRate(root.maxSessionTx)}`
                                font.family: Config.sysFont
                                font.pixelSize: 9
                                font.bold: true
                                color: Config.textMuted
                            }
                        }
                    }

                    // 2D Glowing Rounded Pixel Waves
                    Item {
                        id: pixelCanvasWrapper
                        Layout.fillWidth: true
                        implicitHeight: 140
                        clip: true

                        Glow {
                            anchors.fill: pixelCanvas
                            source: pixelCanvas
                            radius: 10
                            samples: 16
                            color: Config.accent
                            spread: 0.25
                            transparentBorder: true
                            visible: Config.clockShowGlow !== undefined ? Config.clockShowGlow : true
                        }

                        Canvas {
                            id: pixelCanvas
                            anchors.fill: parent
                            renderTarget: Canvas.Image
                            renderStrategy: Canvas.Threaded

                            onPaint: {
                                let ctx = getContext("2d")
                                let w = width
                                let h = height
                                ctx.clearRect(0, 0, w, h)

                                let count = graphHistoryModel.count
                                if (count === 0) return

                                let cols = root.maxGraphPoints
                                let rows = root.matrixRows
                                let gap = 2.5
                                let sectionGap = 14
                                let rad = root.pixelRadius

                                let cellW = Math.floor((w - ((cols - 1) * gap)) / cols)
                                let graphH = Math.floor((h - sectionGap) / 2)
                                let cellH = Math.floor((graphH - ((rows - 1) * gap)) / rows)

                                let stepX = cellW + gap
                                let xOffset = root.scrollProgress * stepX

                                function fillRoundedRect(x, y, rw, rh, r, fillStyle) {
                                    ctx.fillStyle = fillStyle
                                    ctx.beginPath()
                                    ctx.moveTo(x + r, y)
                                    ctx.lineTo(x + rw - r, y)
                                    ctx.quadraticCurveTo(x + rw, y, x + rw, y + r)
                                    ctx.lineTo(x + rw, y + rh - r)
                                    ctx.quadraticCurveTo(x + rw, y + rh, x + rw - r, y + rh)
                                    ctx.lineTo(x + r, y + rh)
                                    ctx.quadraticCurveTo(x, y + rh, x, y + rh - r)
                                    ctx.lineTo(x, y + r)
                                    ctx.quadraticCurveTo(x, y, x + r, y)
                                    ctx.closePath()
                                    ctx.fill()
                                }

                                function drawMatrixWave(startY, peakVal, activeColor, valueKey) {
                                    for (let c = 0; c < count; c++) {
                                        let val = graphHistoryModel.get(c)[valueKey]
                                        let activeBlocks = Math.min(rows, Math.ceil((val / peakVal) * rows))
                                        let posX = (c * stepX) - xOffset

                                        if (posX + cellW < 0 || posX > w) continue

                                        for (let r = 0; r < rows; r++) {
                                            let posY = startY + graphH - ((r + 1) * (cellH + gap))
                                            let style = (r < activeBlocks && val > 0) ? activeColor : "rgba(255, 255, 255, 0.035)"
                                            fillRoundedRect(posX, posY, cellW, cellH, rad, style)
                                        }
                                    }
                                }

                                // 1. Download Matrix Wave (Top)
                                drawMatrixWave(0, root.smoothPeakRx, root.colorDownload, "rxValue")

                                // 2. Upload Matrix Wave (Bottom)
                                drawMatrixWave(graphH + sectionGap, root.smoothPeakTx, root.colorUpload, "txValue")
                            }
                        }
                    }
                }
            }

            // ==========================================
            // 2. PHYSICAL INTERFACE CARD
            // ==========================================
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: ifRow.implicitHeight + 24
                radius: Config.cornerRadius
                color: Qt.rgba(255, 255, 255, 0.05)
                border.width: 1
                border.color: Qt.rgba(255, 255, 255, 0.1)

                RowLayout {
                    id: ifRow
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12

                    // Icon & Toggle Switch
                    Rectangle {
                        implicitWidth: 40
                        implicitHeight: 40
                        radius: 20
                        color: root.localConnected
                            ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.2)
                            : Qt.rgba(255, 255, 255, 0.06)
                        border.width: 1.5
                        border.color: root.localConnected ? Config.accent : Qt.rgba(255, 255, 255, 0.15)

                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: root.localConnected ? "lan" : "cloud_off"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 20
                            color: root.localConnected ? Config.accent : Config.textMuted
                        }
                    }

                    // Interface Details
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        RowLayout {
                            spacing: 8
                            Text {
                                text: root.localIpAddress
                                font.family: Config.sysFont
                                font.pixelSize: Config.size(Config.fontBody)
                                font.bold: true
                                color: root.localConnected ? Config.textMain : Config.textMuted
                            }

                            Rectangle {
                                implicitWidth: ifNameText.implicitWidth + 10
                                implicitHeight: 18
                                radius: 9
                                color: Qt.rgba(255, 255, 255, 0.08)

                                Text {
                                    id: ifNameText
                                    anchors.centerIn: parent
                                    text: root.localIfName
                                    font.family: Config.sysFont
                                    font.pixelSize: 9
                                    font.bold: true
                                    color: Config.textMuted
                                }
                            }
                        }

                        Text {
                            text: `${root.localConnected ? "Connected" : "Disconnected"} • MAC: ${root.localMacAddress}`
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontCaption)
                            color: Config.textMuted
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Interface Quick Toggle Action
                    Rectangle {
                        Layout.alignment: Qt.AlignRight
                        implicitWidth: Math.max(ifToggleActionRow.implicitWidth + 24, 84)
                        implicitHeight: 32
                        radius: 16
                        color: toggleHover.hovered
                            ? (root.localConnected ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.2) : Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.85))
                            : (root.localConnected ? Qt.rgba(255, 255, 255, 0.08) : Config.accent)
                        border.width: root.localConnected ? 1 : 0
                        border.color: toggleHover.hovered && root.localConnected ? Config.accent : Qt.rgba(255, 255, 255, 0.12)

                        RowLayout {
                            id: ifToggleActionRow
                            anchors.centerIn: parent
                            spacing: 4

                            Text {
                                text: root.localConnected ? "link_off" : "link"
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: 14
                                color: root.localConnected
                                    ? (toggleHover.hovered ? Config.accent : Config.textMain)
                                    : Config.bgBase
                            }

                            Text {
                                id: toggleActionText
                                text: root.localConnected ? "Disconnect" : "Connect"
                                font.family: Config.sysFont
                                font.bold: true
                                font.pixelSize: 11
                                color: root.localConnected
                                    ? (toggleHover.hovered ? Config.accent : Config.textMain)
                                    : Config.bgBase
                            }
                        }

                        TapHandler {
                            gesturePolicy: TapHandler.WithinBounds
                            onTapped: root.toggleLocalNetwork()
                        }
                        HoverHandler { id: toggleHover; cursorShape: Qt.PointingHandCursor }
                    }
                }
            }

            // ==========================================
            // 3. VPN PROFILES SECTION
            // ==========================================
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                visible: !root.showFileBrowser

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "VPN & TUNNEL PROFILES"
                        color: Config.textMuted
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontMicro)
                        font.bold: true
                    }

                    Rectangle {
                        implicitWidth: vpnCountText.implicitWidth + 10
                        implicitHeight: 16
                        radius: 8
                        color: Qt.rgba(255, 255, 255, 0.08)

                        Text {
                            id: vpnCountText
                            anchors.centerIn: parent
                            text: vpnListModel.count.toString()
                            font.family: Config.sysFont
                            font.pixelSize: 9
                            font.bold: true
                            color: Config.textMuted
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // IMPORT PROFILE BUTTON
                    Rectangle {
                        implicitWidth: impRow.implicitWidth + 14
                        implicitHeight: 28
                        radius: 14
                        color: impHover.hovered ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.85) : Config.accent

                        RowLayout {
                            id: impRow
                            anchors.centerIn: parent
                            spacing: 4

                            Text {
                                text: "add"
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: 15
                                color: Config.bgBase
                            }

                            Text {
                                text: "Import Profile"
                                font.family: Config.sysFont
                                font.pixelSize: 11
                                font.bold: true
                                color: Config.bgBase
                            }
                        }

                        TapHandler { onTapped: root.showFileBrowser = true }
                        HoverHandler { id: impHover; cursorShape: Qt.PointingHandCursor }
                    }
                }

                // VPN PROFILES LIST
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Repeater {
                        model: vpnListModel

                        delegate: Rectangle {
                            id: vpnCard
                            required property string profileName
                            readonly property bool isActive: root.activeVpnName === profileName

                            Layout.fillWidth: true
                            implicitHeight: vpnRow.implicitHeight + 20
                            radius: Config.cornerRadius * 0.75
                            color: isActive
                                ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.12)
                                : (vCardHover.hovered ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(255, 255, 255, 0.04))
                            border.width: 1
                            border.color: isActive ? Config.accent : (vCardHover.hovered ? Qt.rgba(255, 255, 255, 0.15) : Qt.rgba(255, 255, 255, 0.08))
                            clip: true

                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            RowLayout {
                                id: vpnRow
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 12

                                Rectangle {
                                    implicitWidth: 36
                                    implicitHeight: 36
                                    radius: 18
                                    color: isActive
                                        ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.25)
                                        : Qt.rgba(255, 255, 255, 0.06)

                                    Text {
                                        anchors.centerIn: parent
                                        text: isActive ? "vpn_key" : "vpn_key_off"
                                        font.family: "Material Symbols Outlined"
                                        font.pixelSize: 18
                                        color: isActive ? Config.accent : Config.textMain
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    RowLayout {
                                        spacing: 6

                                        Text {
                                            text: profileName
                                            font.family: Config.sysFont
                                            font.bold: true
                                            font.pixelSize: Config.size(Config.fontBody)
                                            color: isActive ? Config.accent : Config.textMain
                                            elide: Text.ElideRight
                                            Layout.maximumWidth: 320
                                        }

                                        Rectangle {
                                            visible: isActive
                                            implicitWidth: vpnActiveBadgeText.implicitWidth + 8
                                            implicitHeight: 16
                                            radius: 8
                                            color: Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.25)
                                            border.width: 1
                                            border.color: Config.accent

                                            Text {
                                                id: vpnActiveBadgeText
                                                anchors.centerIn: parent
                                                text: "ACTIVE"
                                                font.family: Config.sysFont
                                                font.pixelSize: 9
                                                font.bold: true
                                                color: Config.accent
                                            }
                                        }
                                    }

                                    Text {
                                        text: isActive ? "Encrypted tunnel connection active" : "WireGuard / OpenVPN Profile"
                                        font.family: Config.sysFont
                                        font.pixelSize: Config.size(Config.fontMicro)
                                        color: Config.textMuted
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                RowLayout {
                                    spacing: 6
                                    Layout.alignment: Qt.AlignRight

                                    Rectangle {
                                        implicitWidth: Math.max(vpnActionRow.implicitWidth + 24, 76)
                                        implicitHeight: 30
                                        radius: 15
                                        color: vpnActionHover.hovered
                                            ? (isActive ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.2) : Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.85))
                                            : (isActive ? Qt.rgba(255, 255, 255, 0.08) : Config.accent)
                                        border.width: isActive ? 1 : 0
                                        border.color: vpnActionHover.hovered && isActive ? Config.accent : Qt.rgba(255, 255, 255, 0.12)

                                        RowLayout {
                                            id: vpnActionRow
                                            anchors.centerIn: parent
                                            spacing: 4

                                            Text {
                                                text: isActive ? "link_off" : "login"
                                                font.family: "Material Symbols Outlined"
                                                font.pixelSize: 14
                                                color: isActive
                                                    ? (vpnActionHover.hovered ? Config.accent : Config.textMain)
                                                    : Config.bgBase
                                            }

                                            Text {
                                                id: vpnActionText
                                                text: isActive ? "Disconnect" : "Connect"
                                                font.family: Config.sysFont
                                                font.bold: true
                                                font.pixelSize: 11
                                                color: isActive
                                                    ? (vpnActionHover.hovered ? Config.accent : Config.textMain)
                                                    : Config.bgBase
                                            }
                                        }

                                        TapHandler {
                                            gesturePolicy: TapHandler.WithinBounds
                                            onTapped: root.toggleProfileState(profileName, !isActive)
                                        }
                                        HoverHandler { id: vpnActionHover; cursorShape: Qt.PointingHandCursor }
                                    }

                                    Rectangle {
                                        implicitWidth: 30
                                        implicitHeight: 30
                                        radius: 15
                                        color: delHover.hovered ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.2) : Qt.rgba(255, 255, 255, 0.06)
                                        border.width: 1
                                        border.color: delHover.hovered ? Config.accent : Qt.rgba(255, 255, 255, 0.1)

                                        Text {
                                            anchors.centerIn: parent
                                            text: "delete_outline"
                                            font.family: "Material Symbols Outlined"
                                            font.pixelSize: 15
                                            color: delHover.hovered ? Config.accent : Config.textMuted
                                        }

                                        TapHandler {
                                            gesturePolicy: TapHandler.WithinBounds
                                            onTapped: root.deleteProfile(profileName)
                                        }
                                        HoverHandler { id: delHover; cursorShape: Qt.PointingHandCursor }
                                    }
                                }
                            }

                            HoverHandler { id: vCardHover; cursorShape: Qt.PointingHandCursor }
                        }
                    }
                }
            }

            // ==========================================
            // 4. EMBEDDED FILE BROWSER FOR IMPORT
            // ==========================================
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 280
                radius: Config.cornerRadius
                color: Qt.rgba(255, 255, 255, 0.05)
                border.width: 1
                border.color: Qt.rgba(255, 255, 255, 0.1)
                visible: root.showFileBrowser

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "IMPORT CONFIG FILE (.conf, .ovpn)"
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontCaption)
                            font.bold: true
                            color: Config.textMain
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            implicitWidth: 70; implicitHeight: 24; radius: 12
                            color: cancelHover.hovered ? Qt.rgba(255, 255, 255, 0.15) : Qt.rgba(255, 255, 255, 0.08)
                            Text { anchors.centerIn: parent; text: "Cancel"; font.family: Config.sysFont; font.pixelSize: Config.size(Config.fontMicro); font.bold: true; color: Config.textMain }
                            TapHandler { onTapped: root.showFileBrowser = false }
                            HoverHandler { id: cancelHover; cursorShape: Qt.PointingHandCursor }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: Qt.rgba(0, 0, 0, 0.25)
                        radius: 8
                        clip: true

                        ListView {
                            anchors.fill: parent
                            anchors.margins: 6
                            spacing: 2
                            model: FolderListModel {
                                folder: root.currentBrowserPath
                                showDirsFirst: true
                                showDotAndDotDot: true
                                nameFilters: ["*.conf", "*.ovpn", "*.vpn"]
                            }

                            delegate: Rectangle {
                                required property string fileName
                                required property bool fileIsDir
                                required property url fileUrl

                                width: ListView.view.width
                                implicitHeight: fileName === "." ? 0 : 32
                                visible: fileName !== "."
                                radius: 6
                                color: fHover.hovered ? Qt.rgba(255, 255, 255, 0.08) : "transparent"

                                RowLayout {
                                    anchors.fill: parent; anchors.leftMargin: 8
                                    spacing: 8
                                    Text { text: fileIsDir ? "folder" : "description"; font.family: "Material Symbols Outlined"; font.pixelSize: 16; color: Config.accent }
                                    Text { text: fileName; font.family: Config.sysFont; font.pixelSize: Config.size(Config.fontCaption); color: Config.textMain; Layout.fillWidth: true; elide: Text.ElideRight }
                                }

                                TapHandler {
                                    onTapped: {
                                        if (fileIsDir) {
                                            root.currentBrowserPath = fileUrl.toString()
                                        } else {
                                            let parsedPath = fileUrl.toString().replace("file://", "")
                                            let typeStr = parsedPath.endsWith(".conf") ? "wireguard" : "openvpn"
                                            vpnImporter.command = ["fish", "-c", `nmcli connection import type ${typeStr} file "${parsedPath}"`]
                                            vpnImporter.running = true
                                            root.showFileBrowser = false
                                        }
                                    }
                                }
                                HoverHandler { id: fHover; cursorShape: Qt.PointingHandCursor }
                            }
                        }
                    }
                }
            }
        }
    }

    Process {
        id: vpnListPopulator
        command: ["nmcli", "-g", "TYPE,NAME,STATE", "connection", "show"]
        running: false
        stdout: StdioCollector {
            onTextChanged: {
                let cleanText = text.trim()
                if (!cleanText) { vpnListModel.clear(); root.activeVpnName = ""; return }
                let lines = cleanText.split("\n")
                let incoming = [], currentActive = ""
                for (let i = 0; i < lines.length; i++) {
                    let parts = lines[i].trim().split(":")
                    if (parts.length >= 2) {
                        let type = parts[0], name = parts[1], state = parts[2] || ""
                        if (type === "wireguard" || type === "vpn" || type === "tun" || type === "overlay") {
                            if (state.indexOf("activated") !== -1) currentActive = name
                            if (incoming.indexOf(name) === -1) incoming.push(name)
                        }
                    }
                }
                root.activeVpnName = currentActive
                for (let m = vpnListModel.count - 1; m >= 0; m--) {
                    if (incoming.indexOf(vpnListModel.get(m).profileName) === -1) vpnListModel.remove(m)
                }
                for (let p = 0; p < incoming.length; p++) {
                    let pName = incoming[p], found = false
                    for (let m = 0; m < vpnListModel.count; m++) { if (vpnListModel.get(m).profileName === pName) { found = true; break; } }
                    if (!found) vpnListModel.append({ "profileName": pName })
                }
            }
        }
    }

    Process { id: vpnStateExecutor; running: false; onExited: vpnListPopulator.running = true }
    Process { id: vpnImporter; running: false; onExited: vpnListPopulator.running = true }

    function toggleProfileState(profileName, itemChecked) {
        vpnStateExecutor.command = itemChecked ? ["nmcli", "connection", "up", "id", profileName] : ["nmcli", "connection", "down", "id", profileName]
        vpnStateExecutor.running = true
    }

    function deleteProfile(profileName) {
        vpnStateExecutor.command = ["nmcli", "connection", "delete", "id", profileName]
        vpnStateExecutor.running = true
    }
}