import QtQuick
import Qt5Compat.GraphicalEffects
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications as Notifs
import "controlcenter"

Item {
    id: root

    readonly property real cardMargin: Config.cardMargin !== undefined ? Config.cardMargin : 12

    // Derive root dimensions from the master vertical layout
    implicitWidth: mainLayout.implicitWidth + (cardMargin * 2)
    implicitHeight: mainLayout.implicitHeight + (cardMargin * 2)

    // --- State Properties ---
    property bool hasWifiAdapter: false
    property alias hasAdapter: root.hasWifiAdapter

    onHasWifiAdapterChanged: {
        if (hasWifiAdapter) {
            fetchWifiStatusProc.running = false
            fetchWifiStatusProc.running = true
        }
    }

    property bool hasBtAdapter: false
    property bool wifiPowered: false
    property bool wifiScanning: false
    property string activeSsid: ""
    property string expandedSsid: ""
    property string connectingSsid: ""
    property string disconnectingSsid: ""
    property string errorSsid: ""
    property string connectionError: ""
    property var knownNetworks: ({})

    property int currentVolume: shellRoot.audioVolume
    property bool isAudioMuted: shellRoot.audioMuted
    property bool isUserDraggingVol: false
    property int currentBrightness: 100
    property bool hasBacklight: false
    property bool isSettingVolume: false

    readonly property int notifCount: (typeof shellRoot !== "undefined" && shellRoot.activeNotifs !== undefined) 
        ? shellRoot.activeNotifs 
        : ((typeof notifServer !== "undefined" && notifServer.trackedNotifications) ? notifServer.trackedNotifications.values.length : 0)

    readonly property bool isAnyPanelExpanded: (wifiCard && (wifiCard.panelExpanded || wifiCard.shouldExpand)) ||
                                               (btCard && (btCard.panelExpanded || btCard.shouldExpand)) ||
                                               (caffeineCard && caffeineCard.panelExpanded) ||
                                               (sysMonitorCard && sysMonitorCard.panelExpanded)

    ListModel { id: wifiModel }

    function clearAllNotifications() {
        if (typeof notifServer === "undefined" || !notifServer.trackedNotifications) return;
        let notifs = notifServer.trackedNotifications.values;
        if (!notifs) return;
        
        for (let i = notifs.length - 1; i >= 0; i--) {
            if (notifs[i]) notifs[i].dismiss();
        }
        if (typeof shellRoot !== "undefined" && shellRoot.updateNotifCount) {
            Qt.callLater(shellRoot.updateNotifCount);
        }
    }

    Component.onCompleted: {
        detectWifiAdapterProc.running = true
        detectBtAdapterProc.running = true
        fetchWifiStatusProc.running = true
    }

    // MAIN VERTICAL WRAPPER (Top Bento + Bottom Media)
    ColumnLayout {
        id: mainLayout
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: root.cardMargin
        spacing: root.cardMargin / 2
        enabled: !root.isAnyPanelExpanded

        // TOP SECTION: TWO-COLUMN BENTO
        RowLayout {
            id: bentoLayout
            Layout.fillWidth: true
            spacing: root.cardMargin / 2

            // ==========================================
            // LEFT COLUMN: CONTROLS & SLIDERS
            // ==========================================
            ColumnLayout {
                id: leftColLayout
                Layout.preferredWidth: 350
                Layout.fillWidth: false
                Layout.alignment: Qt.AlignTop
                spacing: root.cardMargin / 2

                // COMBINED HEADER & 4 TOGGLES CARD
                Rectangle {
                    id: topControlsCard
                    Layout.fillWidth: true
                    implicitHeight: topControlsLayout.implicitHeight + (root.cardMargin * 2)
                    radius: Config.cornerRadius
                    color: Qt.rgba(255, 255, 255, 0.04)
                    border.width: 1
                    border.color: Qt.rgba(255, 255, 255, 0.1)

                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    Item {
                        anchors.fill: parent
                        clip: true

                        Watermark {
                            icon: Config.getIcon("cc")
                            iconSize: 150
                            seed: 25
                        }
                    }

                    z: ((wifiCard && (wifiCard.panelExpanded || wifiCard.shouldExpand)) || 
                        (btCard && (btCard.panelExpanded || btCard.shouldExpand)) || 
                        (caffeineCard && caffeineCard.panelExpanded)) ? 1000 : 1

                    ColumnLayout {
                        id: topControlsLayout
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: root.cardMargin
                        spacing: root.cardMargin / 2

                        Item {
                            implicitWidth: ccTitleText.implicitWidth
                            implicitHeight: ccTitleText.implicitHeight
                            Layout.fillWidth: true

                            Glow {
                                anchors.fill: ccTitleText
                                source: ccTitleText
                                radius: 8
                                samples: 16
                                color: Config.accent
                                spread: 0.2
                                transparentBorder: true
                                visible: Config.clockShowGlow
                            }

                            Text {
                                id: ccTitleText
                                anchors.fill: parent
                                text: "CONTROL CENTER"
                                color: Config.textMain
                                font.family: Config.sysFont
                                font.pixelSize: Config.size(Config.fontCaption)
                                font.bold: true
                                font.italic: true
                            }
                        }

                        // 2x2 Toggles Grid (Row 1)
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: root.cardMargin / 2
                            z: ((wifiCard && (wifiCard.panelExpanded || wifiCard.shouldExpand)) || (btCard && (btCard.panelExpanded || btCard.shouldExpand))) ? 1000 : 1

                            WifiCard {
                                id: wifiCard
                                Layout.fillWidth: true
                                Layout.preferredWidth: 1
                                hasAdapter: root.hasWifiAdapter
                                controlCenterPanel: root
                                wifiPowered: root.wifiPowered
                                wifiScanning: root.wifiScanning
                                activeSsid: root.activeSsid
                                expandedSsid: root.expandedSsid
                                connectingSsid: root.connectingSsid
                                disconnectingSsid: root.disconnectingSsid
                                errorSsid: root.errorSsid
                                connectionError: root.connectionError
                                knownNetworks: root.knownNetworks
                                wifiModel: wifiModel
                                onTogglePower: power => root.toggleWifiPower(power)
                                onTriggerScan: root.triggerWifiScan()
                                onConnectTo: (ssid, pass, isKnown) => connectWifiProc.connectTo(ssid, pass, isKnown)
                                onDisconnectSsid: ssid => disconnectWifiProc.disconnect(ssid)
                                onForgetSsid: ssid => forgetWifiProc.forget(ssid)
                            }

                            BluetoothCard {
                                id: btCard
                                Layout.fillWidth: true
                                Layout.preferredWidth: 1
                                hasHardware: root.hasBtAdapter
                                controlCenterPanel: root
                                onTogglePower: power => btCard.execTogglePower(power)
                                onTriggerScan: btCard.execTriggerScan()
                            }
                        }

                        // 2x2 Toggles Grid (Row 2)
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: root.cardMargin / 2
                            z: (caffeineCard && caffeineCard.panelExpanded) ? 1000 : 1

                            CaffeineCard {
                                id: caffeineCard
                                Layout.fillWidth: true
                                Layout.preferredWidth: 1
                                controlCenterPanel: root
                            }

                            DndCard {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 1
                            }
                        }
                    }
                }

                // Sliders Card
                SlidersCard {
                    id: slidersCardComponent
                    Layout.fillWidth: true
                    currentBrightness: root.currentBrightness
                    hasBacklight: root.hasBacklight
                    currentVolume: root.currentVolume
                    isAudioMuted: root.isAudioMuted
                    onBrightnessChanged: pct => root.setBrightness(pct)
                    onVolumeChanged: pct => root.setVolume(pct)
                    onIsUserDraggingVolChanged: root.isUserDraggingVol = isUserDraggingVol
                }
            }

            // ==========================================
            // RIGHT COLUMN: SYSTEM MONITOR & NOTIFICATIONS
            // ==========================================
            ColumnLayout {
                id: rightColLayout
                Layout.preferredWidth: 350
                Layout.fillWidth: false
                Layout.alignment: Qt.AlignTop
                spacing: root.cardMargin / 2

                // SYSTEM MONITOR (Top Slot)
                SystemMonitorCard {
                    id: sysMonitorCard
                    Layout.fillWidth: true
                    controlCenterPanel: root
                    z: panelExpanded ? 1000 : 1
                }

                // NOTIFICATION HUB (Full-Height Grounded Container)
                Rectangle {
                    id: notifHubContainer
                    Layout.fillWidth: true
                    Layout.preferredHeight: (leftColLayout.implicitHeight - sysMonitorCard.implicitHeight - (root.cardMargin / 2))
                    Layout.fillHeight: true
                    radius: Config.cornerRadius
                    color: Qt.rgba(255, 255, 255, 0.04)
                    border.width: 1
                    border.color: Qt.rgba(255, 255, 255, 0.1)
                    clip: true

                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    Watermark {
                        icon: Config.getIcon("notifications")
                        iconSize: 160
                        seed: 10
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        // Aligned Header Row
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 28
                            spacing: 8

                            Text {
                                text: root.notifCount > 0 ? "notifications_active" : "notifications"
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: 20
                                color: root.notifCount > 0 ? Config.accent : Config.textMuted
                            }

                            Item {
                                implicitWidth: notifTitle.implicitWidth
                                implicitHeight: notifTitle.implicitHeight
                                Layout.fillWidth: true

                                Text {
                                    id: notifTitle
                                    anchors.fill: parent
                                    text: "NOTIFICATIONS"
                                    color: Config.textMain
                                    font.family: Config.sysFont
                                    font.pixelSize: Config.size(Config.fontCaption)
                                    font.bold: true
                                    font.italic: true
                                }

                                Glow {
                                    anchors.fill: notifTitle
                                    source: notifTitle
                                    radius: 6
                                    samples: 12
                                    color: Config.accent
                                    spread: 0.2
                                    transparentBorder: true
                                    visible: Config.clockShowGlow && root.notifCount > 0
                                }
                            }

                            Rectangle {
                                implicitWidth: clearBtnText.implicitWidth + 14
                                implicitHeight: 22
                                radius: 11
                                visible: root.notifCount > 0
                                color: clearHover.hovered ? Qt.rgba(255, 255, 255, 0.15) : Qt.rgba(255, 255, 255, 0.08)
                                border.width: 1
                                border.color: clearHover.hovered ? Config.accent : Qt.rgba(255, 255, 255, 0.12)
                                Behavior on color { ColorAnimation { duration: 150 } }

                                Text {
                                    id: clearBtnText
                                    anchors.centerIn: parent
                                    text: "CLEAR"
                                    color: clearHover.hovered ? Config.accent : Config.textMuted
                                    font.family: Config.sysFont
                                    font.pixelSize: Config.size(Config.fontMicro)
                                    font.bold: true
                                }

                                TapHandler { onTapped: root.clearAllNotifications() }
                                HoverHandler { id: clearHover; cursorShape: Qt.PointingHandCursor }
                            }
                        }

                        // Scrollable List View
                        ListView {
                            id: notifListView
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: 8
                            boundsBehavior: Flickable.StopAtBounds
                            visible: root.notifCount > 0

                            model: (typeof notifServer !== "undefined" && notifServer.trackedNotifications) 
                                ? notifServer.trackedNotifications.values
                                : []

                            delegate: Rectangle {
                                width: notifListView.width
                                implicitHeight: itemLayout.implicitHeight + 16
                                radius: Config.cornerRadius * 0.5
                                color: cardMouse.hovered ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(0, 0, 0, 0.25)
                                Behavior on color { ColorAnimation { duration: 150 } }

                                ColumnLayout {
                                    id: itemLayout
                                    anchors.top: parent.top
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.margins: 10
                                    spacing: 3

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 6

                                        Text {
                                            text: (modelData && modelData.appName) ? modelData.appName.toUpperCase() : "SYSTEM"
                                            color: Config.accent
                                            font.family: Config.sysFont
                                            font.pixelSize: Config.size(Config.fontMicro)
                                            font.bold: true
                                            font.italic: true
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }
                                    }

                                    Text {
                                        visible: modelData && modelData.summary !== ""
                                        text: (modelData && modelData.summary) ? modelData.summary : ""
                                        color: Config.textMain
                                        font.family: Config.sysFont
                                        font.pixelSize: Config.size(Config.fontCaption)
                                        font.bold: true
                                        Layout.fillWidth: true
                                        wrapMode: Text.Wrap
                                    }

                                    Text {
                                        visible: modelData && modelData.body !== ""
                                        text: (modelData && modelData.body) ? modelData.body : ""
                                        color: Config.textMuted
                                        font.family: Config.sysFont
                                        font.pixelSize: Config.size(Config.fontMicro)
                                        Layout.fillWidth: true
                                        wrapMode: Text.Wrap
                                    }
                                }

                                Rectangle {
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.margins: 6
                                    implicitWidth: 18
                                    implicitHeight: 18
                                    radius: 9
                                    color: closeHover.hovered ? Qt.rgba(255, 255, 255, 0.2) : "transparent"
                                    opacity: cardMouse.hovered ? 1.0 : 0.0
                                    Behavior on opacity { NumberAnimation { duration: 150 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "close"
                                        color: closeHover.hovered ? Config.accent : Config.textMuted
                                        font.family: "Material Symbols Outlined"
                                        font.pixelSize: 13
                                    }

                                    TapHandler {
                                        onTapped: {
                                            if (modelData) modelData.dismiss();
                                        }
                                    }
                                    HoverHandler { id: closeHover; cursorShape: Qt.PointingHandCursor }
                                }

                                HoverHandler { id: cardMouse }
                            }
                        }

                        // Centered Empty State Placeholder
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            visible: root.notifCount === 0

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 8

                                Text {
                                    text: "notifications_off"
                                    font.family: "Material Symbols Outlined"
                                    font.pixelSize: 36
                                    color: Config.textMuted
                                    opacity: 0.35
                                    Layout.alignment: Qt.AlignHCenter
                                }

                                Text {
                                    text: "No notifications"
                                    font.family: Config.sysFont
                                    font.pixelSize: Config.size(Config.fontCaption)
                                    font.bold: true
                                    color: Config.textMuted
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }
                        }
                    }
                }
            }
        }

        // ==========================================
        // BOTTOM: FULL WIDTH GROUNDED MEDIA CARD
        // ==========================================
        MediaCard {
            id: mediaCardComponent
            Layout.fillWidth: true
            controlCenterPanel: root
            onSendCommand: cmd => {
                mediaControlProc.command = cmd
                mediaControlProc.running = true
            }
        }
    }

    Connections {
        target: shellRoot
        function onAudioVolumeChanged() {
            if (!root.isUserDraggingVol && !root.isSettingVolume) {
                root.currentVolume = shellRoot.audioVolume
            }
        }
        function onAudioMutedChanged() {
            root.isAudioMuted = shellRoot.audioMuted
        }
    }

    Process { id: mediaControlProc; running: false }

    Process {
        id: mediaFollower
        command: ["playerctl", "--player=%any,playerctld", "--follow", "--format", '{"title": "{{title}}", "artist": "{{artist}}", "status": "{{status}}", "art": "{{mpris:artUrl}}"}', "metadata"]
        running: Config.showControlCenter
        stdout: SplitParser {
            onRead: (data) => {
                try {
                    let parsed = JSON.parse(data.trim());
                    if (parsed.status === "Stopped" || !parsed.title || parsed.title.trim() === "") {
                        mediaCardComponent.mediaTitle = "Not Playing";
                        mediaCardComponent.mediaArtist = "---"; 
                        mediaCardComponent.mediaStatus = "Stopped";
                        mediaCardComponent.mediaArtUrl = "";
                    } else {
                        mediaCardComponent.mediaTitle = parsed.title;
                        mediaCardComponent.mediaArtist = parsed.artist || "Unknown Artist";
                        mediaCardComponent.mediaStatus = parsed.status;
                        mediaCardComponent.mediaArtUrl = parsed.art || "";
                    }
                } catch(e) {
                    mediaCardComponent.mediaTitle = "Not Playing";
                    mediaCardComponent.mediaArtist = "---";
                    mediaCardComponent.mediaStatus = "Stopped";
                    mediaCardComponent.mediaArtUrl = "";
                }
            }
        }
    }

    Process {
        id: cavaProc
        command: ["fish", "-c", "printf '[general]\\nbars = 32\\nsensitivity = 150\\n[output]\\nmethod = raw\\ndata_format = ascii\\nascii_max_range = 255\\nbar_delimiter = 59\\nframe_delimiter = 10\\n' | cava -p /dev/stdin"]
        running: Config.showControlCenter && mediaCardComponent.mediaStatus === "Playing"
        
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (data) => {
                let clean = data.trim();
                if (!clean) return;
                
                let points = clean.split(';');
                let arr = [];
                for (let i = 0; i < points.length; i++) {
                    if (points[i] !== "") arr.push(parseInt(points[i], 10) || 0);
                }
                if (arr.length > 0) mediaCardComponent.cavaBars = arr;
            }
        }
    }

    Process {
        id: detectWifiAdapterProc
        command: ["fish", "-c", "nmcli -t -f TYPE device | grep -q '^wifi$' && echo 'YES' || echo 'NO'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root.hasWifiAdapter = this.text.trim() === "YES"
            }
        }
    }

    Process {
        id: detectBtAdapterProc
        command: ["fish", "-c", "bluetoothctl list | grep -q 'Controller' && echo 'YES' || echo 'NO'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let res = this.text.trim() === "YES"
                if (root.hasBtAdapter !== res) root.hasBtAdapter = res
            }
        }
    }

    Process {
        id: detectBacklightProc
        command: ["fish", "-c", "brightnessctl --list | grep -q 'backlight' && echo 'YES' || echo 'NO'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.hasBacklight = this.text.trim() === "YES"
                if (root.hasBacklight) fetchBrightnessProc.running = true
            }
        }
    }

    Process {
        id: fetchBrightnessProc
        command: ["fish", "-c", "brightnessctl -m | cut -d',' -f4 | tr -d '%'"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let val = parseInt(this.text.trim())
                if (!isNaN(val)) root.currentBrightness = val
            }
        }
    }

    Process {
        id: setBrightnessProc
        running: false
        function setVal(pct) {
            command = ["fish", "-c", `brightnessctl set ${pct}%`]
            running = true
        }
    }

    Process {
        id: setVolumeProc
        running: false
        function setVal(pct) {
            let floatVal = (pct / 100.0).toFixed(2)
            command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", `${floatVal}`]
            running = true
        }
        onExited: {
            root.isSettingVolume = false
            if (typeof shellRoot !== "undefined") shellRoot.isUserSettingVolume = false
        }
    }

    function setBrightness(pct) {
        root.currentBrightness = pct
        setBrightnessProc.setVal(pct)
    }

    function setVolume(pct) {
        root.isSettingVolume = true
        if (typeof shellRoot !== "undefined") shellRoot.isUserSettingVolume = true
        root.currentVolume = pct
        setVolumeProc.setVal(pct)
    }

    function triggerWifiScan() {
        if (root.hasWifiAdapter && root.wifiPowered && !root.wifiScanning) scanWifiProc.startScan()
    }

    function toggleWifiPower(turnOn) {
        if (!root.hasWifiAdapter) return
        toggleWifiProc.command = ["fish", "-c", turnOn ? "rfkill unblock wifi; nmcli radio wifi on" : "nmcli radio wifi off"]
        toggleWifiProc.running = true
    }

    Process {
        id: toggleWifiProc
        running: false
        onExited: fetchWifiStatusProc.running = true
    }

    Process {
        id: scanWifiProc
        command: ["nmcli", "dev", "wifi", "rescan"]
        running: false
        function startScan() {
            root.wifiScanning = true
            running = true
        }
        onExited: {
            root.wifiScanning = false
            fetchWifiStatusProc.running = true
        }
    }

    Process {
        id: disconnectWifiProc
        running: false
        function disconnect(ssid) {
            root.disconnectingSsid = ssid
            command = ["nmcli", "connection", "down", "id", ssid]
            running = true
        }
        onExited: {
            root.disconnectingSsid = ""
            fetchWifiStatusProc.running = true
        }
    }

    Process {
        id: forgetWifiProc
        running: false
        function forget(ssid) {
            root.errorSsid = ""
            root.connectionError = ""
            let safeSsid = ssid.replace(/'/g, "'\"'\"'")
            command = ["fish", "-c", `
                set uuids (nmcli -t -f UUID,TYPE,NAME connection show | awk -F: -v target='${safeSsid}' '$2 ~ /802-11-wireless|wifi/ && $3 == target {print $1}')
                for u in $uuids
                    nmcli connection delete uuid "$u"
                end
            `]
            running = true
        }
        onExited: {
            root.errorSsid = ""
            root.connectionError = ""
            fetchWifiStatusProc.running = false
            fetchWifiStatusProc.running = true
        }
    }

    Process {
        id: cleanupWifiProc
        running: false
        onExited: {
            fetchWifiStatusProc.running = false
            fetchWifiStatusProc.running = true
        }
    }

    Process {
        id: connectWifiProc
        running: false
        property string activeTargetSsid: ""

        stdout: StdioCollector { id: connectStdout }
        stderr: StdioCollector { id: connectStderr }

        function connectTo(ssidTarget, password, isKnown) {
            activeTargetSsid = ssidTarget
            root.connectingSsid = ssidTarget
            root.errorSsid = ""
            root.connectionError = ""

            let safeSsid = ssidTarget.replace(/'/g, "'\"'\"'")
            let cmd = ""
            if (password && password.trim() !== "") {
                let safePass = password.replace(/'/g, "'\"'\"'")
                cmd = `nmcli dev wifi connect '${safeSsid}' password '${safePass}'`
            } else if (isKnown) {
                cmd = `nmcli connection up id '${safeSsid}'`
            } else {
                cmd = `nmcli dev wifi connect '${safeSsid}'`
            }
            command = ["fish", "-c", cmd]
            running = false
            running = true
        }

        onExited: (exitCode) => {
            let failedSsid = activeTargetSsid
            root.connectingSsid = ""

            if (exitCode !== 0 && failedSsid !== "") {
                root.errorSsid = failedSsid
                root.expandedSsid = failedSsid
                let fullErr = (connectStdout.text + "\n" + connectStderr.text).trim().toLowerCase()
                if (fullErr.includes("not found") || fullErr.includes("no network")) {
                    root.connectionError = "Network Not Found"
                } else {
                    root.connectionError = "Invalid Password"
                }

                let safeSsid = failedSsid.replace(/'/g, "'\"'\"'")
                cleanupWifiProc.command = ["fish", "-c", `
                    set uuids (nmcli -t -f UUID,TYPE,NAME connection show | awk -F: -v target='${safeSsid}' '$2 ~ /802-11-wireless|wifi/ && $3 == target {print $1}')
                    for u in $uuids
                        nmcli connection delete uuid "$u" 2>/dev/null
                    end
                `]
                cleanupWifiProc.running = false
                cleanupWifiProc.running = true
            } else {
                root.errorSsid = ""
                root.connectionError = ""
                fetchWifiStatusProc.running = false
                fetchWifiStatusProc.running = true
            }
        }
    }

    Process {
        id: fetchWifiStatusProc
        command: ["fish", "-c", "nmcli radio wifi; echo '---'; nmcli -t -f ACTIVE,SIGNAL,SECURITY,SSID dev wifi; echo '---'; nmcli -t -f NAME connection show"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let parts = this.text.trim().split("---")
                if (parts.length < 2) return
                root.wifiPowered = parts[0].trim() === "enabled"
                if (!root.wifiPowered || !root.hasWifiAdapter) {
                    wifiModel.clear()
                    return
                }

                let knownMap = {}
                if (parts.length >= 3) {
                    let knownLines = parts[2].trim().split("\n")
                    for (let j = 0; j < knownLines.length; j++) {
                        let name = knownLines[j].trim()
                        if (name) knownMap[name] = true
                    }
                }
                root.knownNetworks = knownMap

                let lines = parts[1].trim().split("\n")
                let uniqueMap = {}
                let activeSsidFound = ""

                for (let i = 0; i < lines.length; i++) {
                    let line = lines[i].trim()
                    if (!line) continue
                    let tokens = line.split(":")
                    if (tokens.length < 4) continue

                    let isActive = tokens[0].trim() === "yes"
                    let signal = parseInt(tokens[1].trim()) || 0
                    let sec = tokens[2].trim()
                    let ssid = tokens.slice(3).join(":").trim()
                    if (!ssid) continue

                    if (isActive) activeSsidFound = ssid
                    let isSecure = sec !== "--" && sec !== ""

                    if (!uniqueMap[ssid]) {
                        uniqueMap[ssid] = { ssid: ssid, signalStrength: signal, connected: isActive, isSecure: isSecure }
                    } else {
                        if (isActive) uniqueMap[ssid].connected = true
                        if (signal > uniqueMap[ssid].signalStrength) uniqueMap[ssid].signalStrength = signal
                    }
                }

                root.activeSsid = activeSsidFound
                let newResults = Object.values(uniqueMap).sort((a, b) => b.signalStrength - a.signalStrength)

                let existingMap = {}
                for (let idx = 0; idx < wifiModel.count; idx++) existingMap[wifiModel.get(idx).ssid] = idx
                let freshMap = {}

                for (let k = 0; k < newResults.length; k++) {
                    let item = newResults[k]
                    freshMap[item.ssid] = true
                    if (item.ssid in existingMap) {
                        let tIndex = existingMap[item.ssid]
                        wifiModel.setProperty(tIndex, "connected", item.connected)
                        wifiModel.setProperty(tIndex, "signalStrength", item.signalStrength)
                    } else {
                        wifiModel.append(item)
                    }
                }
                for (let r = wifiModel.count - 1; r >= 0; r--) {
                    if (!freshMap[wifiModel.get(r).ssid]) wifiModel.remove(r)
                }
            }
        }
    }

    Connections {
        target: Config
        function onShowControlCenterChanged() {
            if (Config.showControlCenter) {
                detectWifiAdapterProc.running = false
                detectWifiAdapterProc.running = true
                detectBtAdapterProc.running = false
                detectBtAdapterProc.running = true
                fetchWifiStatusProc.running = false
                fetchWifiStatusProc.running = true
                if (root.hasBacklight) {
                    fetchBrightnessProc.running = false
                    fetchBrightnessProc.running = true
                }
            }
        }
    }

    Timer {
        interval: 3500
        running: Config.showControlCenter
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            fetchWifiStatusProc.running = true
            if (root.hasBacklight) fetchBrightnessProc.running = true
        }
    }
}