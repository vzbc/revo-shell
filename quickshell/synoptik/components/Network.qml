import QtQuick
import Qt5Compat.GraphicalEffects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root

    readonly property real cardMargin: Config.cardMargin !== undefined ? Config.cardMargin : 12

    implicitWidth: mainLayout.implicitWidth + (cardMargin * 2)
    implicitHeight: mainLayout.implicitHeight + (cardMargin * 2)

    // --- State Properties ---
    property string activeVpnName: ""
    property string localIp: ""
    property string interfaceName: ""
    property string ssid: ""

    // --- Live Bandwidth & Activity Tracking ---
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

    // Frame sync tracking for buttery smooth sub-pixel horizontal scrolling
    property real lastPushTimestamp: Date.now()
    property real scrollProgress: 0.0

    // Visual Grid Parameters
    property int matrixRows: 10
    property real pixelRadius: 2.5
    property color colorDownload: Config.accent
    property color colorUpload: Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.65)
    property real activityPulse: Math.min(1.0, (currentRxSpeed + currentTxSpeed) / (1024 * 1024 * 2))

    Behavior on activityPulse {
        NumberAnimation { duration: 180; easing.type: Easing.OutQuad }
    }

    // Cubic interpolated peak values for normalized matrix height scaling
    property real smoothPeakRx: 1024 * 512
    property real smoothPeakTx: 1024 * 256

    Behavior on smoothPeakRx {
        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
    }
    Behavior on smoothPeakTx {
        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
    }

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
        fetchNetInfoProc.running = false
        fetchNetInfoProc.running = true
    }

    // Smooth sub-pixel horizontal glide loop (only runs when network card is visible)
    FrameAnimation {
        id: frameGraphSync
        running: Config.showNetwork
        onTriggered: {
            let elapsed = Date.now() - root.lastPushTimestamp
            root.scrollProgress = Math.min(elapsed / root.updateInterval, 1.0)
            pixelCanvas.requestPaint()
        }
    }

    Timer {
        id: netInfoTimer
        interval: 4000
        running: Config.showNetwork
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            fetchNetInfoProc.running = false
            fetchNetInfoProc.running = true
        }
    }

    // Graph Data Ticker
    Timer {
        id: timelineGraphTicker
        interval: root.updateInterval
        running: Config.showNetwork
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

    // Bandwidth Stream via /proc/net/dev (relaxed sleep from 0.12s to 0.25s to stop IPC thrashing)
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
        running: Config.showNetwork
        
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

    // Info Process (SSID, Interface, IP, VPN)
    Process {
        id: fetchNetInfoProc
        command: ["fish", "-c", `
            set s (nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | awk -F: '$1 ~ /yes|true/ {print $2; exit}')
            set d (ip route show 2>/dev/null | awk '/default/ {print $5}' | head -n1)
            set ip ""
            if test -n "$d"
                set ip (ip -4 addr show dev $d 2>/dev/null | awk '/inet / {print $2}' | cut -d/ -f1)
            end
            set v (nmcli -t -f TYPE,NAME connection show --active 2>/dev/null | awk -F: '$1 ~ /wireguard|vpn|tun|overlay/ {print $2; exit}')
            echo "$s|$d|$ip|$v"
        `]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let clean = this.text.trim()
                if (!clean) return
                let parts = clean.split("|")
                if (parts.length >= 4) {
                    root.ssid = parts[0] ? parts[0].trim() : ""
                    root.interfaceName = parts[1] ? parts[1].trim() : ""
                    root.localIp = parts[2] ? parts[2].trim() : ""
                    root.activeVpnName = parts[3] ? parts[3].trim() : ""
                }
            }
        }
    }

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.margins: root.cardMargin
        spacing: root.cardMargin * 0.75

        // ==========================================
        // CARD 1: EXPANDED TITLE & 10-ROW WAVE MATRIX
        // ==========================================
        Rectangle {
            Layout.fillWidth: true
            implicitWidth: 380
            implicitHeight: topCardContent.implicitHeight + (root.cardMargin * 2)
            radius: Config.cornerRadius
            color: Qt.rgba(1, 1, 1, 0.04)
            border.color: Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.12 + (root.activityPulse * 0.2))
            border.width: 1
            clip: true

            Watermark {
                icon: root.activeVpnName !== "" ? "vpn_key" : Config.getIcon("network")
                iconSize: 180
                seed: 19
            }

            ColumnLayout {
                id: topCardContent
                anchors.fill: parent
                anchors.margins: root.cardMargin * 1.2
                spacing: 12

                // Header Row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        implicitWidth: 30
                        implicitHeight: 30
                        radius: 8
                        color: Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.15)
                        border.color: Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.3)
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: root.activeVpnName !== "" ? "vpn_key" : Config.getIcon("network")
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 16
                            color: Config.accent
                        }
                    }

                    Item {
                        implicitWidth: netTitleText.implicitWidth
                        implicitHeight: netTitleText.implicitHeight
                        Layout.fillWidth: true

                        Glow {
                            anchors.fill: netTitleText
                            source: netTitleText
                            radius: 10
                            samples: 16
                            color: Config.accent
                            spread: 0.25
                            transparentBorder: true
                            visible: Config.clockShowGlow
                        }

                        Text {
                            id: netTitleText
                            anchors.fill: parent
                            text: "NETWORK"
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontTitle)
                            font.bold: true
                            font.italic: true
                            font.letterSpacing: 1.5
                        }
                    }

                    // VPN Active Key Badge
                    Rectangle {
                        visible: root.activeVpnName !== ""
                        implicitWidth: vpnBadgeRow.implicitWidth + 12
                        implicitHeight: 24
                        radius: 6
                        color: Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.2)
                        border.color: Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.35)
                        border.width: 1

                        RowLayout {
                            id: vpnBadgeRow
                            anchors.centerIn: parent
                            spacing: 4

                            Text {
                                text: "vpn_key"
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: 12
                                color: Config.accent
                            }

                            Text {
                                text: root.activeVpnName
                                font.family: Config.sysFont
                                font.pixelSize: Config.size(Config.fontMicro)
                                font.bold: true
                                color: Config.accent
                                elide: Text.ElideRight
                                Layout.maximumWidth: 110
                            }
                        }
                    }
                }

                // Subtitle Connection Info & Interface Tag
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Rectangle {
                        implicitWidth: 6
                        implicitHeight: 6
                        radius: 3
                        color: Config.accent
                    }

                    Text {
                        text: {
                            if (root.ssid && root.localIp) return root.ssid + "  •  " + root.localIp
                            if (root.ssid) return root.ssid
                            if (root.localIp) return root.localIp + (root.interfaceName ? ("  •  " + root.interfaceName) : "")
                            return "Connected"
                        }
                        color: Config.textMuted
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontSubhead)
                        font.bold: true
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                // Tall Matrix Container (150px Height)
                Item {
                    id: pixelCanvasWrapper
                    Layout.fillWidth: true
                    implicitHeight: 150
                    clip: true

                    // Glowing backdrop pass matching header bloom
                    Glow {
                        anchors.fill: pixelCanvas
                        source: pixelCanvas
                        radius: 10
                        samples: 16
                        color: Config.accent
                        spread: 0.25
                        transparentBorder: true
                        visible: Config.clockShowGlow
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
                            let sectionGap = 16
                            let rad = root.pixelRadius

                            // Layout geometry
                            let cellW = Math.floor((w - ((cols - 1) * gap)) / cols)
                            let graphH = Math.floor((h - sectionGap) / 2)
                            let cellH = Math.floor((graphH - ((rows - 1) * gap)) / rows)
                            
                            let stepX = cellW + gap
                            let xOffset = root.scrollProgress * stepX

                            // Smooth rounded rectangle primitive
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

                            // Dynamic channel renderer with uniform active accent styling
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

                            // 1. Download Channel (Top Wave)
                            drawMatrixWave(0, root.smoothPeakRx, root.colorDownload, "rxValue")

                            // 2. Upload Channel (Bottom Wave)
                            drawMatrixWave(graphH + sectionGap, root.smoothPeakTx, root.colorUpload, "txValue")
                        }
                    }
                }
            }
        }

        // ==========================================
        // CARD 2 & 3: EXPANDED STATS & PEAK METRICS
        // ==========================================
        RowLayout {
            Layout.fillWidth: true
            spacing: root.cardMargin * 0.75

            // Download Sub-Card
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 88
                radius: Config.cornerRadius
                color: Qt.rgba(1, 1, 1, 0.04)
                border.color: Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.12)
                border.width: 1
                clip: true

                Watermark {
                    icon: "arrow_downward"
                    iconSize: 100
                    seed: 20
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 2

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 4

                        Text {
                            text: "arrow_downward"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 13
                            color: root.colorDownload
                        }

                        Text {
                            text: "DOWNLOAD"
                            color: root.colorDownload
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontMicro)
                            font.bold: true
                            font.letterSpacing: 1
                        }
                    }

                    Text {
                        text: root.downloadSpeed
                        color: Config.textMain
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontHeadline || Config.fontTitle)
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: "PEAK " + root.formatRate(root.maxSessionRx)
                        color: Config.textMuted
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontNano || Config.fontMicro)
                        font.bold: true
                        opacity: 0.65
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

            // Upload Sub-Card
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 88
                radius: Config.cornerRadius
                color: Qt.rgba(1, 1, 1, 0.04)
                border.color: Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.12)
                border.width: 1
                clip: true

                Watermark {
                    icon: "arrow_upward"
                    iconSize: 100
                    seed: 21
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 2

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 4

                        Text {
                            text: "arrow_upward"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 13
                            color: root.colorUpload
                        }

                        Text {
                            text: "UPLOAD"
                            color: root.colorUpload
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontMicro)
                            font.bold: true
                            font.letterSpacing: 1
                        }
                    }

                    Text {
                        text: root.uploadSpeed
                        color: Config.textMain
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontHeadline || Config.fontTitle)
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: "PEAK " + root.formatRate(root.maxSessionTx)
                        color: Config.textMuted
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontNano || Config.fontMicro)
                        font.bold: true
                        opacity: 0.65
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }
        }
    }

    Connections {
        target: Config
        function onShowNetworkChanged() {
            if (Config.showNetwork) {
                seedGraphModel()
                fetchNetInfoProc.running = false
                fetchNetInfoProc.running = true
            }
        }
    }
}