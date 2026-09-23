import QtQuick
import Qt5Compat.GraphicalEffects
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import ".."

PanelWindow {
    id: sysInfoWindow
    visible: (Config.showDesktopSysInfo !== false) && (screen ? (Config.isSysInfoEnabledForScreen ? Config.isSysInfoEnabledForScreen(screen.name) : true) : true)

    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "quickshell-desktop-sysinfo"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    exclusiveZone: 0

    mask: Region { item: infoContainer }

    // --- SYSTEM METRICS STATE ---
    // Static / Hardware Metadata (Fetched once at startup)
    property string hostUser: "---"
    property string osDistro: "---"
    property string kernelVer: "---"
    property string packageCount: "---"
    property string wmCompositor: "---"
    property string boardModel: "---"
    property string cpuModel: "---"
    property string cpuCores: "---"
    property string gpuModel: "---"

    // Dynamic Runtime Telemetry (Polled at interval)
    property string sysUptime: "---"
    property string loadAvg: "---"
    property string localIp: "---"
    property string gatewayIp: "---"
    property string dnsServer: "---"

    property string ramText: "---"
    property real ramPct: 0.0
    property string swapText: "---"
    property real swapPct: 0.0
    property string diskRootText: "---"
    property real diskRootPct: 0.0
    property string diskHomeText: "---"
    property real diskHomePct: 0.0

    // --- 1. ONE-TIME STATIC HARDWARE & SYSTEM QUERY ---
    Process {
        id: staticSysInfoProc
        running: false
        command: [
            "fish", "-c",
            "set -l u (whoami); " +
            "set -l h (uname -n); " +
            "set -l os (grep -m1 '^PRETTY_NAME=' /etc/os-release 2>/dev/null | cut -d= -f2 | string trim -c '\"'); " +
            "test -z \"$os\"; and set os 'Arch Linux'; " +
            "set -l k (uname -r); " +
            "set -l pkgs (pacman -Qq 2>/dev/null | count); " +
            "test \"$pkgs\" = \"0\"; and set pkgs '---'; " +
            "set -l wm (echo 'Hyprland '(hyprctl version 2>/dev/null | grep -m1 'Tag:' | awk '{print $2}')); " +
            "test \"$wm\" = 'Hyprland '; and set wm 'Hyprland'; " +
            "set -l board (cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null); " +
            "test -z \"$board\" -o \"$board\" = 'None' -o \"$board\" = 'Default string'; and set board (cat /sys/devices/virtual/dmi/id/board_name 2>/dev/null); " +
            "test -z \"$board\"; and set board 'Generic Board'; " +
            "set -l cpu (grep -m1 'model name' /proc/cpuinfo 2>/dev/null | cut -d: -f2 | string trim | string replace -r '[(][^)]*[)]' '' | string replace -r ' @.*' ''); " +
            "set -l cores (nproc 2>/dev/null); " +
            "set -l raw_gpu (lspci 2>/dev/null | grep -iE 'vga|3d|display' | grep -i 'nvidia' | head -n1); " +
            "test -z \"$raw_gpu\"; and set raw_gpu (lspci 2>/dev/null | grep -iE 'vga|3d|display' | head -n1); " +
            "set -l gpu (echo $raw_gpu | string match -r '\\[([^\\]]+)\\]' | tail -n1); " +
            "test -z \"$gpu\"; and set gpu (echo $raw_gpu | cut -d: -f3 | string trim | string replace -r '[(][^)]*[)]' '' | string replace -r 'Corporation ' '' | string replace -r 'NVIDIA ' ''); " +
            "test -z \"$gpu\"; and set gpu 'Integrated'; " +
            "printf '{\"user\":\"%s\",\"host\":\"%s\",\"os\":\"%s\",\"kernel\":\"%s\",\"pkgs\":\"%s\",\"wm\":\"%s\",\"board\":\"%s\",\"cpu\":\"%s\",\"cores\":\"%s\",\"gpu\":\"%s\"}\\n' \"$u\" \"$h\" \"$os\" \"$k\" \"$pkgs\" \"$wm\" \"$board\" \"$cpu\" \"$cores\" \"$gpu\""
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text ? this.text.trim() : ""
                if (!txt) return
                try {
                    let d = JSON.parse(txt)
                    sysInfoWindow.hostUser = (d.user && d.host) ? `${d.user}@${d.host}` : "localhost"
                    sysInfoWindow.osDistro = d.os || "Linux"
                    sysInfoWindow.kernelVer = d.kernel || "Linux"
                    sysInfoWindow.packageCount = d.pkgs ? `${d.pkgs} (pacman)` : "---"
                    sysInfoWindow.wmCompositor = d.wm || "Hyprland"
                    sysInfoWindow.boardModel = d.board || "Generic Board"
                    sysInfoWindow.cpuModel = d.cpu || "Generic CPU"
                    sysInfoWindow.cpuCores = d.cores ? `${d.cores} threads` : "---"
                    sysInfoWindow.gpuModel = d.gpu || "Integrated GPU"
                } catch(e) {}
            }
        }
    }

    // --- 2. LIGHTWEIGHT DYNAMIC RUNTIME TELEMETRY ---
    Process {
        id: dynamicSysInfoProc
        running: false
        command: [
            "fish", "-c",
            "set -l upt (uptime -p 2>/dev/null | string replace 'up ' ''); " +
            "set -l load (awk '{print $1\", \"$2\", \"$3}' /proc/loadavg 2>/dev/null); " +
            "set -l ip (ip -4 route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}'); " +
            "test -z \"$ip\"; and set ip (hostname -I 2>/dev/null | awk '{print $1}'); " +
            "test -z \"$ip\"; and set ip '127.0.0.1'; " +
            "set -l gw (ip -4 route show default 2>/dev/null | awk '{print $3; exit}'); " +
            "test -z \"$gw\"; and set gw '---'; " +
            "set -l dns (awk '/nameserver/ {print $2; exit}' /etc/resolv.conf 2>/dev/null); " +
            "test -z \"$dns\"; and set dns '---'; " +
            "set -l mem (free -b | awk '/Mem:/ {printf \"{\\\"used\\\":%.1f,\\\"total\\\":%.1f,\\\"pct\\\":%.1f}\", $3/1073741824, $2/1073741824, ($3/$2)*100}'); " +
            "set -l swap (free -b | awk '/Swap:/ {if ($2>0) printf \"{\\\"used\\\":%.1f,\\\"total\\\":%.1f,\\\"pct\\\":%.1f}\", $3/1073741824, $2/1073741824, ($3/$2)*100; else print \"null\"}'); " +
            "set -l diskRoot (df -h / 2>/dev/null | awk 'NR==2 {gsub(/%/,\"\",$5); printf \"{\\\"used\\\":\\\"%s\\\",\\\"total\\\":\\\"%s\\\",\\\"pct\\\":%s}\", $3, $2, $5}'); " +
            "set -l diskHome (df -h /home 2>/dev/null | awk 'NR==2 {gsub(/%/,\"\",$5); printf \"{\\\"used\\\":\\\"%s\\\",\\\"total\\\":\\\"%s\\\",\\\"pct\\\":%s}\", $3, $2, $5}'); " +
            "printf '{\"uptime\":\"%s\",\"load\":\"%s\",\"ip\":\"%s\",\"gw\":\"%s\",\"dns\":\"%s\",\"mem\":%s,\"swap\":%s,\"diskRoot\":%s,\"diskHome\":%s}\\n' \"$upt\" \"$load\" \"$ip\" \"$gw\" \"$dns\" \"$mem\" \"$swap\" \"$diskRoot\" \"$diskHome\""
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text ? this.text.trim() : ""
                if (!txt) return
                try {
                    let d = JSON.parse(txt)
                    sysInfoWindow.sysUptime = d.uptime || "Just booted"
                    sysInfoWindow.loadAvg = d.load || "---"
                    sysInfoWindow.localIp = d.ip || "127.0.0.1"
                    sysInfoWindow.gatewayIp = d.gw || "---"
                    sysInfoWindow.dnsServer = d.dns || "---"

                    if (d.mem) {
                        sysInfoWindow.ramPct = Math.min(100, Math.max(0, d.mem.pct)) / 100.0
                        sysInfoWindow.ramText = `${d.mem.used.toFixed(1)} / ${d.mem.total.toFixed(1)} GB`
                    }
                    if (d.swap) {
                        sysInfoWindow.swapPct = Math.min(100, Math.max(0, d.swap.pct)) / 100.0
                        sysInfoWindow.swapText = `${d.swap.used.toFixed(1)} / ${d.swap.total.toFixed(1)} GB`
                    } else {
                        sysInfoWindow.swapPct = 0.0
                        sysInfoWindow.swapText = "Disabled"
                    }
                    if (d.diskRoot) {
                        sysInfoWindow.diskRootPct = Math.min(100, Math.max(0, parseFloat(d.diskRoot.pct))) / 100.0
                        sysInfoWindow.diskRootText = `${d.diskRoot.used} / ${d.diskRoot.total}`
                    }
                    if (d.diskHome) {
                        sysInfoWindow.diskHomePct = Math.min(100, Math.max(0, parseFloat(d.diskHome.pct))) / 100.0
                        sysInfoWindow.diskHomeText = `${d.diskHome.used} / ${d.diskHome.total}`
                    }
                } catch(e) {}
            }
        }
    }

    Component.onCompleted: {
        staticSysInfoProc.running = true
        dynamicSysInfoProc.running = true
    }

    Timer {
        interval: Config.sysInfoRefreshInterval || 3000
        running: sysInfoWindow.visible
        repeat: true
        onTriggered: {
            if (!dynamicSysInfoProc.running) {
                dynamicSysInfoProc.running = true
            }
        }
    }

    Item {
        id: infoContainer

        readonly property real basePadding: 14
        property real currentScale: 1.0

        implicitWidth: (mainLayout.implicitWidth + (basePadding * 2))
        implicitHeight: (mainLayout.implicitHeight + (basePadding * 2))
        width: implicitWidth
        height: implicitHeight

        property real dragX: 60
        property real dragY: 100
        property bool initialized: false

        x: dragX
        y: dragY

        function restorePosition() {
            if (!sysInfoWindow.screen) return
            let savedPos = Config.getSysInfoPosition ? Config.getSysInfoPosition(sysInfoWindow.screen.name, 60, 100) : null
            if (savedPos && typeof savedPos.x === "number" && typeof savedPos.y === "number") {
                dragX = savedPos.x
                dragY = savedPos.y
                initialized = true
            }

            if (Config.getSysInfoScale) {
                currentScale = Config.getSysInfoScale(sysInfoWindow.screen.name)
            }
        }

        Connections {
            target: Config
            function onIsLoadedChanged() {
                if (Config.isLoaded) infoContainer.restorePosition()
            }
            function onSysInfoPositionsChanged() {
                infoContainer.restorePosition()
            }
            function onSysInfoScalesChanged() {
                if (sysInfoWindow.screen && Config.getSysInfoScale) {
                    infoContainer.currentScale = Config.getSysInfoScale(sysInfoWindow.screen.name)
                }
            }
        }

        Component.onCompleted: {
            if (Config.isLoaded) restorePosition()
        }

        onXChanged: {
            if (initialized && dragArea.drag.active && sysInfoWindow.screen && Config.saveSysInfoPosition) {
                Config.saveSysInfoPosition(sysInfoWindow.screen.name, dragX, dragY)
            }
        }
        onYChanged: {
            if (initialized && dragArea.drag.active && sysInfoWindow.screen && Config.saveSysInfoPosition) {
                Config.saveSysInfoPosition(sysInfoWindow.screen.name, dragX, dragY)
            }
        }

        // BACKGROUND CARD
        Rectangle {
            anchors.fill: parent
            visible: Config.sysInfoShowBg !== false
            radius: Config.cornerRadius
            color: Qt.rgba(Config.bgBase.r, Config.bgBase.g, Config.bgBase.b, 0.85)
            border.width: Config.showBorders ? 2 : 1
            border.color: Config.showBorders ? Config.accent : Qt.rgba(255, 255, 255, 0.12)
        }

        ColumnLayout {
            id: mainLayout
            anchors.centerIn: parent
            spacing: 8 * infoContainer.currentScale
            width: 320 * infoContainer.currentScale

            // HEADER ROW
            RowLayout {
                Layout.fillWidth: true
                spacing: 8 * infoContainer.currentScale
                visible: Config.sysInfoShowHost !== false

                Item {
                    implicitWidth: headerIcon.implicitWidth
                    implicitHeight: headerIcon.implicitHeight

                    Glow {
                        anchors.fill: headerIcon
                        source: headerIcon
                        radius: 6
                        samples: 12
                        color: Config.accent
                        spread: 0.2
                        transparentBorder: true
                        visible: Config.sysInfoShowGlow !== false
                    }

                    Text {
                        id: headerIcon
                        text: "terminal"
                        color: Config.accent
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: Config.size(Config.fontTitle) * infoContainer.currentScale
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        text: "SYSTEM SPECIFICATION"
                        color: Config.textMain
                        renderType: Config.textRenderType
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontCaption) * infoContainer.currentScale
                        font.italic: true
                        font.letterSpacing: 1.2
                    }

                    Text {
                        text: sysInfoWindow.hostUser
                        color: Config.accent
                        renderType: Config.textRenderType
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontMicro) * infoContainer.currentScale
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(255, 255, 255, 0.08)
                visible: Config.sysInfoShowHost !== false
            }

            // TELEMETRY KEY-VALUE METRICS
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4 * infoContainer.currentScale

                // OS / Distro
                RowLayout {
                    Layout.fillWidth: true
                    visible: Config.sysInfoShowOs !== false
                    Text { text: "OS Distro"; color: Config.textMuted; renderType: Config.textRenderType; font.family: Config.sysFont; font.pixelSize: Config.size(Config.fontMicro) * infoContainer.currentScale; Layout.preferredWidth: 84 * infoContainer.currentScale }
                    Text { text: sysInfoWindow.osDistro; color: Config.textMain; renderType: Config.textRenderType; font.family: Config.sysFont; font.pixelSize: Config.size(Config.fontMicro) * infoContainer.currentScale; elide: Text.ElideRight; Layout.fillWidth: true }
                }

                // Kernel
                RowLayout {
                    Layout.fillWidth: true
                    visible: Config.sysInfoShowKernel !== false
                    Text { text: "Kernel"; color: Config.textMuted; renderType: Config.textRenderType; font.family: Config.sysFont; font.pixelSize: Config.size(Config.fontMicro) * infoContainer.currentScale; Layout.preferredWidth: 84 * infoContainer.currentScale }
                    Text { text: sysInfoWindow.kernelVer; color: Config.textMain; renderType: Config.textRenderType; font.family: Config.sysFont; font.pixelSize: Config.size(Config.fontMicro) * infoContainer.currentScale; elide: Text.ElideRight; Layout.fillWidth: true }
                }

                // Uptime
                RowLayout {
                    Layout.fillWidth: true
                    visible: Config.sysInfoShowUptime !== false
                    Text { text: "Uptime"; color: Config.textMuted; renderType: Config.textRenderType; font.family: Config.sysFont; font.pixelSize: Config.size(Config.fontMicro) * infoContainer.currentScale; Layout.preferredWidth: 84 * infoContainer.currentScale }
                    Text { text: sysInfoWindow.sysUptime; color: Config.textMain; renderType: Config.textRenderType; font.family: Config.sysFont; font.pixelSize: Config.size(Config.fontMicro) * infoContainer.currentScale; elide: Text.ElideRight; Layout.fillWidth: true }
                }

                // Packages
                RowLayout {
                    Layout.fillWidth: true
                    visible: Config.sysInfoShowPackages !== false
                    Text { text: "Packages"; color: Config.textMuted; renderType: Config.textRenderType; font.family: Config.sysFont; font.pixelSize: Config.size(Config.fontMicro) * infoContainer.currentScale; Layout.preferredWidth: 84 * infoContainer.currentScale }
                    Text { text: sysInfoWindow.packageCount; color: Config.textMain; renderType: Config.textRenderType; font.family: Config.sysFont; font.pixelSize: Config.size(Config.fontMicro) * infoContainer.currentScale; elide: Text.ElideRight; Layout.fillWidth: true }
                }

                // Window Manager
                RowLayout {
                    Layout.fillWidth: true
                    visible: Config.sysInfoShowWm !== false
                    Text { text: "Compositor"; color: Config.textMuted; renderType: Config.textRenderType; font.family: Config.sysFont; font.pixelSize: Config.size(Config.fontMicro) * infoContainer.currentScale; Layout.preferredWidth: 84 * infoContainer.currentScale }
                    Text { text: sysInfoWindow.wmCompositor; color: Config.textMain; renderType: Config.textRenderType; font.family: Config.sysFont; font.pixelSize: Config.size(Config.fontMicro) * infoContainer.currentScale; elide: Text.ElideRight; Layout.fillWidth: true }
                }

                // Motherboard / Machine
                RowLayout {
                    Layout.fillWidth: true
                    visible: Config.sysInfoShowBoard !== false
                    Text { text: "Motherboard"; color: Config.textMuted; renderType: Config.textRenderType; font.family: Config.sysFont; font.pixelSize: Config.size(Config.fontMicro) * infoContainer.currentScale; Layout.preferredWidth: 84 * infoContainer.currentScale }
                    Text { text: sysInfoWindow.boardModel; color: Config.textMain; renderType: Config.textRenderType; font.family: Config.sysFont; font.pixelSize: Config.size(Config.fontMicro) * infoContainer.currentScale; elide: Text.ElideRight; Layout.fillWidth: true }
                }

                // Processor
                RowLayout {
                    Layout.fillWidth: true
                    visible: Config.sysInfoShowCpu !== false
                    Text { text: "Processor"; color: Config.textMuted; renderType: Config.textRenderType; font.family: Config.sysFont; font.pixelSize: Config.size(Config.fontMicro) * infoContainer.currentScale; Layout.preferredWidth: 84 * infoContainer.currentScale }
                    Text { text: sysInfoWindow.cpuModel; color: Config.textMain; renderType: Config.textRenderType; font.family: Config.sysFont; font.pixelSize: Config.size(Config.fontMicro) * infoContainer.currentScale; elide: Text.ElideRight; Layout.fillWidth: true }
                }

                // CPU Threads
                RowLayout {
                    Layout.fillWidth: true
                    visible: Config.sysInfoShowCores !== false
                    Text { text: "CPU Cores"; color: Config.textMuted; renderType: Config.textRenderType; font.family: Config.sysFont; font.pixelSize: Config.size(Config.fontMicro) * infoContainer.currentScale; Layout.preferredWidth: 84 * infoContainer.currentScale }
                    Text { text: sysInfoWindow.cpuCores; color: Config.textMain; renderType: Config.textRenderType; font.family: Config.sysFont; font.pixelSize: Config.size(Config.fontMicro) * infoContainer.currentScale; elide: Text.ElideRight; Layout.fillWidth: true }
                }

                // Load Average
                RowLayout {
                    Layout.fillWidth: true
                    visible: Config.sysInfoShowLoad !== false
                    Text { text: "Load Avg"; color: Config.textMuted; renderType: Config.textRenderType; font.family: Config.sysFont; font.pixelSize: Config.size(Config.fontMicro) * infoContainer.currentScale; Layout.preferredWidth: 84 * infoContainer.currentScale }
                    Text { text: sysInfoWindow.loadAvg; color: Config.textMain; renderType: Config.textRenderType; font.family: Config.sysFont; font.pixelSize: Config.size(Config.fontMicro) * infoContainer.currentScale; elide: Text.ElideRight; Layout.fillWidth: true }
                }

                // Graphics Card
                RowLayout {
                    Layout.fillWidth: true
                    visible: Config.sysInfoShowGpu !== false
                    Text { text: "Graphics"; color: Config.textMuted; renderType: Config.textRenderType; font.family: Config.sysFont; font.pixelSize: Config.size(Config.fontMicro) * infoContainer.currentScale; Layout.preferredWidth: 84 * infoContainer.currentScale }
                    Text { text: sysInfoWindow.gpuModel; color: Config.textMain; renderType: Config.textRenderType; font.family: Config.sysFont; font.pixelSize: Config.size(Config.fontMicro) * infoContainer.currentScale; elide: Text.ElideRight; Layout.fillWidth: true }
                }

                // IPv4 Address
                RowLayout {
                    Layout.fillWidth: true
                    visible: Config.sysInfoShowIp !== false
                    Text { text: "IPv4 Address"; color: Config.textMuted; renderType: Config.textRenderType; font.family: Config.sysFont; font.pixelSize: Config.size(Config.fontMicro) * infoContainer.currentScale; Layout.preferredWidth: 84 * infoContainer.currentScale }
                    Text { text: sysInfoWindow.localIp; color: Config.textMain; renderType: Config.textRenderType; font.family: Config.sysFont; font.pixelSize: Config.size(Config.fontMicro) * infoContainer.currentScale; elide: Text.ElideRight; Layout.fillWidth: true }
                }

                // Default Gateway
                RowLayout {
                    Layout.fillWidth: true
                    visible: Config.sysInfoShowGateway !== false
                    Text { text: "Gateway"; color: Config.textMuted; renderType: Config.textRenderType; font.family: Config.sysFont; font.pixelSize: Config.size(Config.fontMicro) * infoContainer.currentScale; Layout.preferredWidth: 84 * infoContainer.currentScale }
                    Text { text: sysInfoWindow.gatewayIp; color: Config.textMain; renderType: Config.textRenderType; font.family: Config.sysFont; font.pixelSize: Config.size(Config.fontMicro) * infoContainer.currentScale; elide: Text.ElideRight; Layout.fillWidth: true }
                }

                // DNS Resolver
                RowLayout {
                    Layout.fillWidth: true
                    visible: Config.sysInfoShowDns !== false
                    Text { text: "DNS Server"; color: Config.textMuted; renderType: Config.textRenderType; font.family: Config.sysFont; font.pixelSize: Config.size(Config.fontMicro) * infoContainer.currentScale; Layout.preferredWidth: 84 * infoContainer.currentScale }
                    Text { text: sysInfoWindow.dnsServer; color: Config.textMain; renderType: Config.textRenderType; font.family: Config.sysFont; font.pixelSize: Config.size(Config.fontMicro) * infoContainer.currentScale; elide: Text.ElideRight; Layout.fillWidth: true }
                }
            }

            // RESOURCE CAPACITY GAUGES
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6 * infoContainer.currentScale
                visible: (Config.sysInfoShowRam !== false) || (Config.sysInfoShowSwap !== false) || (Config.sysInfoShowDisk !== false) || (Config.sysInfoShowDiskHome !== false)

                // Memory / RAM Bar
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    visible: Config.sysInfoShowRam !== false

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Memory (RAM)"; color: Config.textMuted; renderType: Config.textRenderType; font.family: Config.sysFont; font.pixelSize: Config.size(Config.fontMicro) * infoContainer.currentScale }
                        Item { Layout.fillWidth: true }
                        Text { text: sysInfoWindow.ramText; color: Config.accent; renderType: Config.textRenderType; font.family: Config.sysFont; font.pixelSize: Config.size(Config.fontMicro) * infoContainer.currentScale }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 4 * infoContainer.currentScale
                        radius: height / 2
                        color: Qt.rgba(255, 255, 255, 0.08)

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.width * sysInfoWindow.ramPct
                            radius: height / 2
                            color: Config.accent
                            Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                        }
                    }
                }

                // Swap Space Bar
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    visible: Config.sysInfoShowSwap !== false

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Swap Space"; color: Config.textMuted; renderType: Config.textRenderType; font.family: Config.sysFont; font.pixelSize: Config.size(Config.fontMicro) * infoContainer.currentScale }
                        Item { Layout.fillWidth: true }
                        Text { text: sysInfoWindow.swapText; color: Config.accent; renderType: Config.textRenderType; font.family: Config.sysFont; font.pixelSize: Config.size(Config.fontMicro) * infoContainer.currentScale }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 4 * infoContainer.currentScale
                        radius: height / 2
                        color: Qt.rgba(255, 255, 255, 0.08)

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.width * sysInfoWindow.swapPct
                            radius: height / 2
                            color: Config.accent
                            Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                        }
                    }
                }

                // Root Storage Bar
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    visible: Config.sysInfoShowDisk !== false

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Root Disk (/)"; color: Config.textMuted; renderType: Config.textRenderType; font.family: Config.sysFont; font.pixelSize: Config.size(Config.fontMicro) * infoContainer.currentScale }
                        Item { Layout.fillWidth: true }
                        Text { text: sysInfoWindow.diskRootText; color: Config.accent; renderType: Config.textRenderType; font.family: Config.sysFont; font.pixelSize: Config.size(Config.fontMicro) * infoContainer.currentScale }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 4 * infoContainer.currentScale
                        radius: height / 2
                        color: Qt.rgba(255, 255, 255, 0.08)

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.width * sysInfoWindow.diskRootPct
                            radius: height / 2
                            color: Config.accent
                            Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                        }
                    }
                }

                // Home Storage Bar
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    visible: Config.sysInfoShowDiskHome !== false

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Home Disk (/home)"; color: Config.textMuted; renderType: Config.textRenderType; font.family: Config.sysFont; font.pixelSize: Config.size(Config.fontMicro) * infoContainer.currentScale }
                        Item { Layout.fillWidth: true }
                        Text { text: sysInfoWindow.diskHomeText; color: Config.accent; renderType: Config.textRenderType; font.family: Config.sysFont; font.pixelSize: Config.size(Config.fontMicro) * infoContainer.currentScale }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 4 * infoContainer.currentScale
                        radius: height / 2
                        color: Qt.rgba(255, 255, 255, 0.08)

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.width * sysInfoWindow.diskHomePct
                            radius: height / 2
                            color: Config.accent
                            Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                        }
                    }
                }
            }
        }

        MouseArea {
            id: dragArea
            anchors.fill: parent
            drag.target: infoContainer
            drag.axis: Drag.XAndYAxis
            cursorShape: Qt.PointingHandCursor

            onPositionChanged: {
                if (drag.active) {
                    infoContainer.dragX = infoContainer.x
                    infoContainer.dragY = infoContainer.y
                }
            }

            onWheel: (wheel) => {
                let step = 0.08
                let newScale = infoContainer.currentScale
                if (wheel.angleDelta.y > 0) {
                    newScale = Math.min(3.0, newScale + step)
                } else {
                    newScale = Math.max(0.5, newScale - step)
                }

                infoContainer.currentScale = newScale

                if (sysInfoWindow.screen && Config.saveSysInfoScale) {
                    Config.saveSysInfoScale(sysInfoWindow.screen.name, newScale)
                }
            }
        }
    }
}