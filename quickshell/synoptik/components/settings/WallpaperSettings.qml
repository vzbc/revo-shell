import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Widgets
import ".."

Flickable {
    id: root
    Layout.fillWidth: true
    Layout.fillHeight: true
    contentWidth: width
    contentHeight: contentColumn.implicitHeight + 32
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AsNeeded
        active: root.moving || root.flicking
    }

    // Reusable Geometric / Square Toggle Switch Component
    component ToggleSwitch : Rectangle {
        id: sw
        property bool checked: false
        
        implicitWidth: 40
        implicitHeight: 22
        radius: 6
        color: checked ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.2) : Qt.rgba(0, 0, 0, 0.4)
        border.width: sw.checked ? 2 : 1
        border.color: checked ? Config.accent : Qt.rgba(255, 255, 255, 0.15)

        Behavior on color { ColorAnimation { duration: 140 } }
        Behavior on border.color { ColorAnimation { duration: 140 } }

        // Square Thumb / Slider
        Rectangle {
            id: thumb
            x: sw.checked ? (sw.width - width - 3) : 3
            anchors.verticalCenter: parent.verticalCenter
            width: 16
            height: 16
            radius: 4
            color: sw.checked ? Config.accent : Qt.rgba(255, 255, 255, 0.2)
            border.width: 0
            border.color: sw.checked ? Qt.lighter(Config.accent, 1.2) : Qt.rgba(255, 255, 255, 0.25)

            Behavior on x { 
                NumberAnimation { 
                    duration: 160
                    easing.type: Easing.OutCubic 
                } 
            }
            Behavior on color { ColorAnimation { duration: 140 } }
            Behavior on border.color { ColorAnimation { duration: 140 } }
        }
    }

    readonly property real cardMargin: Config.cardMargin !== undefined ? Config.cardMargin : 12

    readonly property var awwwTransitions: [
        { name: "fade",   icon: "blur_on" },
        { name: "wipe",   icon: "cleaning_services" },
        { name: "wave",   icon: "waves" },
        { name: "grow",   icon: "fullscreen" },
        { name: "center", icon: "filter_center_focus" },
        { name: "outer",  icon: "crop_free" },
        { name: "left",   icon: "arrow_back" },
        { name: "right",  icon: "arrow_forward" },
        { name: "top",    icon: "arrow_upward" },
        { name: "bottom", icon: "arrow_downward" },
        { name: "simple", icon: "flash_on" },
        { name: "random", icon: "shuffle" }
    ]

    property string currentWallpaperPath: Config.activeWallpaperPath || ""

    // Unified backend caller routed through Config
    QtObject {
        id: wallpaperBackend

        function applyWallpaper(filePath) {
            if (!filePath || filePath === "") return
            let cleanFilePath = (typeof filePath === "string" ? filePath : filePath.toString()).replace(/^file:\/\//, "")
            Config.applyWallpaperBackend(cleanFilePath, false)
        }

        function shuffleRandom() {
            let list = Config.wallpapers || []
            if (list.length <= 0) return
            let randIdx = Math.floor(Math.random() * list.length)
            let path = list[randIdx]
            if (path) {
                applyWallpaper(path)
                root.currentWallpaperPath = (typeof path === "string" ? path : "").replace(/^file:\/\//, "").trim()
                Config.activeWallpaperPath = root.currentWallpaperPath
            }
        }
    }

    ColumnLayout {
        id: contentColumn
        width: Math.min(root.width - (root.cardMargin * 2), 620)
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: root.cardMargin

        // SECTION HEADER
        Text {
            Layout.fillWidth: true
            text: "WALLPAPER & BACKGROUNDS"
            color: Config.textMain
            font.family: Config.sysFont
            font.pixelSize: Config.size(Config.fontSubhead)
            font.bold: true
        }

        Text {
            text: "Manage active desktop wallpapers, per-monitor outputs, automated background slideshows, and smooth Wayland transitions."
            color: Config.textMuted
            font.family: Config.sysFont
            font.pixelSize: Config.size(Config.fontCaption)
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }

        // ==========================================
        // 1. ACTIVE WALLPAPER & SLIDESHOW CARD
        // ==========================================
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: activeCol.implicitHeight + 28
            radius: Config.cornerRadius
            color: Qt.rgba(255, 255, 255, 0.05)
            border.width: 1
            border.color: Qt.rgba(255, 255, 255, 0.1)

            ColumnLayout {
                id: activeCol
                anchors.fill: parent
                anchors.margins: 14
                spacing: 14

                RowLayout {
                    Layout.fillWidth: true

                    ColumnLayout {
                        spacing: 2
                        Text {
                            text: "ACTIVE WALLPAPER"
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontBody)
                            font.bold: true
                        }
                        Text {
                            text: Config.activeWallpaperPath ? Config.activeWallpaperPath.split('/').pop() : "No wallpaper set"
                            color: Config.textMuted
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontMicro)
                            elide: Text.ElideMiddle
                            Layout.maximumWidth: 320
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Random Shuffle Button
                    Rectangle {
                        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                        implicitWidth: 100
                        implicitHeight: 32
                        radius: 16
                        color: Config.accent

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 5
                            Text {
                                text: "shuffle"
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: 15
                                color: Config.bgBase
                            }
                            Text {
                                text: "Random"
                                font.family: Config.sysFont
                                font.pixelSize: 11
                                font.bold: true
                                color: Config.bgBase
                            }
                        }

                        TapHandler { onTapped: wallpaperBackend.shuffleRandom() }
                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                    }
                }

                // Automatic Slideshow Toggle
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.minimumWidth: 0
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            text: "Automatic Wallpaper Slideshow"
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontBody)
                            font.bold: true
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Cycles randomly through your wallpaper library on a timed interval"
                            color: Config.textMuted
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontCaption)
                            wrapMode: Text.WordWrap
                        }
                    }

                    ToggleSwitch {
                        checked: Config.slideshowActive !== false

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Config.slideshowActive = (Config.slideshowActive === false)
                                if (typeof Config.saveConfig === "function") Config.saveConfig()
                                else if (typeof Config.save === "function") Config.save()
                            }
                        }
                    }
                }

                // Slideshow Interval Stepper
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    opacity: Config.slideshowActive ? 1.0 : 0.4

                    Text {
                        text: "Change every"
                        color: Config.textMuted
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontCaption)
                    }

                    Item { Layout.fillWidth: true }

                    RowLayout {
                        spacing: 4

                        Rectangle {
                            implicitWidth: 26; implicitHeight: 26; radius: 13
                            color: Qt.rgba(255, 255, 255, 0.08)
                            border.width: 1
                            border.color: Qt.rgba(255, 255, 255, 0.1)
                            Text {
                                anchors.centerIn: parent
                                text: "remove"
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: 14
                                color: Config.textMain
                            }
                            TapHandler {
                                onTapped: if (Config.slideshowMinutes > 1) Config.slideshowMinutes--
                            }
                            HoverHandler { cursorShape: Qt.PointingHandCursor }
                        }

                        Rectangle {
                            implicitWidth: 44; implicitHeight: 26; radius: 6
                            color: Qt.rgba(0, 0, 0, 0.4)
                            border.width: 1
                            border.color: Config.accent
                            Text {
                                anchors.centerIn: parent
                                text: Config.slideshowMinutes + "m"
                                color: Config.accent
                                font.family: Config.sysFont
                                font.pixelSize: 11
                                font.bold: true
                            }
                        }

                        Rectangle {
                            implicitWidth: 26; implicitHeight: 26; radius: 13
                            color: Qt.rgba(255, 255, 255, 0.08)
                            border.width: 1
                            border.color: Qt.rgba(255, 255, 255, 0.1)
                            Text {
                                anchors.centerIn: parent
                                text: "add"
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: 14
                                color: Config.textMain
                            }
                            TapHandler {
                                onTapped: Config.slideshowMinutes++
                            }
                            HoverHandler { cursorShape: Qt.PointingHandCursor }
                        }
                    }
                }
            }
        }

        // ==========================================
        // 2. WALLHAVEN ACCOUNT & SYNC CARD
        // ==========================================
        Rectangle {
            id: syncCard
            Layout.fillWidth: true
            implicitHeight: syncCol.implicitHeight + 28
            radius: Config.cornerRadius
            color: Qt.rgba(255, 255, 255, 0.05)
            border.width: 1
            border.color: Qt.rgba(255, 255, 255, 0.1)

            property bool isSyncing: false
            property real syncProgress: 0.0
            property string statusMessage: "Idle"

            Process {
                id: syncProcess
                command: [
                    Quickshell.env("HOME") + "/.config/quickshell/Synoptik/scripts/wallhaven_sync.sh",
                    Config.wallhavenApiKey || "",
                    Config.wallhavenUsername || "",
                    Quickshell.env("HOME") + "/Pictures/Wallpapers"
                ]

                stdout: SplitParser {
                    onRead: data => {
                        let line = data.trim()
                        if (line.startsWith("PROGRESS:")) {
                            let parts = line.split(":")
                            let current = parseInt(parts[1])
                            let total = parseInt(parts[2])
                            if (total > 0) syncCard.syncProgress = current / total
                            syncCard.statusMessage = `Downloading ${current}/${total}...`
                        } else if (line.startsWith("STATUS:")) {
                            syncCard.statusMessage = line.replace("STATUS:", "")
                        }
                    }
                }

                onExited: (exitCode) => {
                    syncCard.isSyncing = false
                    if (exitCode === 0) {
                        syncCard.syncProgress = 1.0
                        syncCard.statusMessage = "Sync complete"
                        if (typeof Config.reloadWallpapers === "function") {
                            Config.reloadWallpapers()
                        }
                    } else {
                        syncCard.statusMessage = "Sync failed"
                    }
                }
            }

            ColumnLayout {
                id: syncCol
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        spacing: 2
                        Text {
                            text: "WALLHAVEN SYNC"
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontBody)
                            font.bold: true
                        }
                        Text {
                            id: syncSubtitle
                            text: 'Sync wallpapers from your <a href="https://wallhaven.cc">wallhaven.cc</a> account into ~/Pictures/Wallpapers'
                            textFormat: Text.StyledText
                            color: Config.textMuted
                            linkColor: Config.accent
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontMicro)

                            onLinkActivated: function(link) {
                                Qt.openUrlExternally(link)
                            }

                            HoverHandler {
                                cursorShape: syncSubtitle.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                            }
                        }
                    }
                }

                // Account Credentials
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 36
                        radius: Config.cornerRadius / 2
                        color: Qt.rgba(0, 0, 0, 0.4)
                        border.width: 1
                        border.color: userField.activeFocus ? Config.accent : (userHover.hovered ? Qt.rgba(255, 255, 255, 0.25) : Qt.rgba(255, 255, 255, 0.1))

                        HoverHandler {
                            id: userHover
                            cursorShape: Qt.IBeamCursor
                        }

                        TextInput {
                            id: userField
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            verticalAlignment: TextInput.AlignVCenter
                            text: Config.wallhavenUsername || ""
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: 11
                            selectByMouse: true

                            Text {
                                text: "Wallhaven Username"
                                visible: !userField.text && !userField.activeFocus
                                color: Config.textMuted
                                font.family: Config.sysFont
                                font.pixelSize: 11
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            onTextChanged: {
                                Config.wallhavenUsername = text
                                if (typeof Config.saveConfig === "function") Config.saveConfig()
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 36
                        radius: Config.cornerRadius / 2
                        color: Qt.rgba(0, 0, 0, 0.4)
                        border.width: 1
                        border.color: keyField.activeFocus ? Config.accent : (keyHover.hovered ? Qt.rgba(255, 255, 255, 0.25) : Qt.rgba(255, 255, 255, 0.1))

                        HoverHandler {
                            id: keyHover
                            cursorShape: Qt.IBeamCursor
                        }

                        TextInput {
                            id: keyField
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            verticalAlignment: TextInput.AlignVCenter
                            echoMode: TextInput.Password
                            text: Config.wallhavenApiKey || ""
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: 11
                            selectByMouse: true

                            Text {
                                text: "Wallhaven API Key"
                                visible: !keyField.text && !keyField.activeFocus
                                color: Config.textMuted
                                font.family: Config.sysFont
                                font.pixelSize: 11
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            onTextChanged: {
                                Config.wallhavenApiKey = text
                                if (typeof Config.saveConfig === "function") Config.saveConfig()
                            }
                        }
                    }
                }

                // Sync Trigger & Progress
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        implicitWidth: 100
                        implicitHeight: 30
                        radius: Config.cornerRadius / 2
                        color: syncCard.isSyncing ? Qt.rgba(255, 255, 255, 0.1) : Config.accent

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 4

                            Text {
                                text: syncCard.isSyncing ? "sync" : "cloud_download"
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: 14
                                color: syncCard.isSyncing ? Config.textMuted : Config.bgBase
                            }

                            Text {
                                text: syncCard.isSyncing ? "Syncing" : "Sync"
                                font.family: Config.sysFont
                                font.pixelSize: 11
                                font.bold: true
                                color: syncCard.isSyncing ? Config.textMuted : Config.bgBase
                            }
                        }

                        TapHandler {
                            enabled: !syncCard.isSyncing
                            onTapped: {
                                syncCard.isSyncing = true
                                syncCard.syncProgress = 0.0
                                syncCard.statusMessage = "Connecting..."
                                syncProcess.running = true
                            }
                        }
                        HoverHandler { cursorShape: syncCard.isSyncing ? Qt.ArrowCursor : Qt.PointingHandCursor }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 6
                        radius: 3
                        color: Qt.rgba(0, 0, 0, 0.4)
                        clip: true

                        Rectangle {
                            width: parent.width * syncCard.syncProgress
                            height: parent.height
                            radius: 3
                            color: Config.accent

                            Behavior on width {
                                NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
                            }
                        }
                    }

                    Text {
                        text: syncCard.statusMessage
                        color: Config.textMuted
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontMicro)
                    }
                }
            }
        }

        // ==========================================
        // 3. WALLPAPER PARALLAX & DEPTH CARD
        // ==========================================
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: parallaxCol.implicitHeight + 28
            radius: Config.cornerRadius
            color: Qt.rgba(255, 255, 255, 0.05)
            border.width: 1
            border.color: Qt.rgba(255, 255, 255, 0.1)

            ColumnLayout {
                id: parallaxCol
                anchors.fill: parent
                anchors.margins: 14
                spacing: 14

                // Header
                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        spacing: 2
                        Text {
                            text: "WALLPAPER PARALLAX & DEPTH"
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontBody)
                            font.bold: true
                        }
                        Text {
                            text: "Dynamic workspace shift & 3D cursor tilt motion effects"
                            color: Config.textMuted
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontMicro)
                        }
                    }
                }

                // 1. Master Toggle Row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.minimumWidth: 0
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            text: "Wallpaper Parallax"
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontBody)
                            font.bold: true
                            wrapMode: Text.WordWrap
                        }
                        Text {
                            Layout.fillWidth: true
                            text: "Enable depth motion and responsive canvas translation (disables transitions)"
                            color: Config.textMuted
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontCaption)
                            wrapMode: Text.WordWrap
                        }
                    }

                    ToggleSwitch {
                        checked: Config.enableWallpaperParallax

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Config.enableWallpaperParallax = !Config.enableWallpaperParallax
                        }
                    }
                }

                // 2. Workspace Switch Parallax Row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    opacity: Config.enableWallpaperParallax ? 1.0 : 0.4

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.minimumWidth: 0
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            text: "Workspace Switch Parallax"
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontBody)
                            font.bold: true
                            wrapMode: Text.WordWrap
                        }
                        Text {
                            Layout.fillWidth: true
                            text: "Smoothly pans wallpaper across workspace transitions (requires Parallax)"
                            color: Config.textMuted
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontCaption)
                            wrapMode: Text.WordWrap
                        }
                    }

                    ToggleSwitch {
                        checked: Config.enableWallpaperParallax && Config.wallpaperWorkspaceParallax

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Config.enableWallpaperParallax ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                if (Config.enableWallpaperParallax) Config.wallpaperWorkspaceParallax = !Config.wallpaperWorkspaceParallax
                            }
                        }
                    }
                }

                // 3. Cursor Motion Parallax Row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    opacity: Config.enableWallpaperParallax ? 1.0 : 0.4

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.minimumWidth: 0
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            text: "Cursor Motion Parallax"
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontBody)
                            font.bold: true
                            wrapMode: Text.WordWrap
                        }
                        Text {
                            Layout.fillWidth: true
                            text: "Floats and tilts wallpaper depth in real-time with mouse (requires Parallax)"
                            color: Config.textMuted
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontCaption)
                            wrapMode: Text.WordWrap
                        }
                    }

                    ToggleSwitch {
                        checked: Config.enableWallpaperParallax && Config.wallpaperCursorParallax

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Config.enableWallpaperParallax ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                if (Config.enableWallpaperParallax) Config.wallpaperCursorParallax = !Config.wallpaperCursorParallax
                            }
                        }
                    }
                }

                // 4. Intensity Stepper Row
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 44
                    radius: Config.cornerRadius / 2
                    opacity: Config.enableWallpaperParallax ? 1.0 : 0.4
                    color: Qt.rgba(0, 0, 0, 0.2)
                    border.width: 1
                    border.color: Qt.rgba(255, 255, 255, 0.08)

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12; anchors.rightMargin: 12
                        spacing: 10

                        Text {
                            text: "Parallax Intensity"
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontCaption)
                            font.bold: true
                        }

                        Item { Layout.fillWidth: true }

                        RowLayout {
                            spacing: 6

                            Repeater {
                                model: [
                                    { label: "0.5x Subtle", val: 0.5 },
                                    { label: "1.0x Balanced", val: 1.0 },
                                    { label: "1.5x Dynamic", val: 1.5 },
                                    { label: "2.0x High", val: 2.0 }
                                ]

                                Rectangle {
                                    readonly property bool isSelected: Math.abs(Config.wallpaperParallaxIntensity - modelData.val) < 0.05
                                    implicitWidth: intText.implicitWidth + 14
                                    implicitHeight: 26
                                    radius: 13
                                    color: isSelected ? Config.accent : ((intHover.hovered && Config.enableWallpaperParallax) ? Qt.rgba(255, 255, 255, 0.12) : Qt.rgba(255, 255, 255, 0.06))
                                    border.width: isSelected ? 0 : 1
                                    border.color: isSelected ? "transparent" : Qt.rgba(255, 255, 255, 0.1)

                                    Text {
                                        id: intText
                                        anchors.centerIn: parent
                                        text: modelData.label
                                        color: isSelected ? Config.bgBase : ((intHover.hovered && Config.enableWallpaperParallax) ? Config.textMain : Config.textMuted)
                                        font.family: Config.sysFont
                                        font.pixelSize: Config.size(Config.fontMicro)
                                        font.bold: isSelected
                                    }

                                    TapHandler { 
                                        enabled: Config.enableWallpaperParallax
                                        onTapped: Config.wallpaperParallaxIntensity = modelData.val 
                                    }
                                    HoverHandler { 
                                        id: intHover
                                        enabled: Config.enableWallpaperParallax
                                        cursorShape: Qt.PointingHandCursor 
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ==========================================
        // 4. TARGET OUTPUT MONITORS CARD
        // ==========================================
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: monCol.implicitHeight + 28
            radius: Config.cornerRadius
            color: Qt.rgba(255, 255, 255, 0.05)
            border.width: 1
            border.color: Qt.rgba(255, 255, 255, 0.1)

            ColumnLayout {
                id: monCol
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true

                    ColumnLayout {
                        spacing: 2
                        Text {
                            text: "TARGET DISPLAYS"
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontBody)
                            font.bold: true
                        }
                        Text {
                            text: "Select monitors to apply wallpapers to (unselected monitors share the global wallpaper)."
                            color: Config.textMuted
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontMicro)
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Repeater {
                        model: Quickshell.screens

                        delegate: Rectangle {
                            id: monBtn
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            implicitHeight: 40
                            radius: Config.cornerRadius / 2

                            readonly property bool isSelected: Config.selectedWallpaperMonitors && Config.selectedWallpaperMonitors.includes(modelData.name)
                            color: isSelected ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.16) : (monHover.containsMouse ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(0, 0, 0, 0.2))
                            border.width: isSelected ? 1.5 : 1
                            border.color: isSelected ? Config.accent : Qt.rgba(255, 255, 255, 0.08)

                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 8

                                Text {
                                    text: "desktop_windows"
                                    font.family: "Material Symbols Outlined"
                                    font.pixelSize: 16
                                    color: monBtn.isSelected ? Config.accent : Config.textMuted
                                }

                                Text {
                                    text: modelData.name
                                    color: monBtn.isSelected ? Config.accent : Config.textMain
                                    font.family: Config.sysFont
                                    font.pixelSize: Config.size(Config.fontCaption)
                                    font.bold: monBtn.isSelected
                                }

                                Rectangle {
                                    implicitWidth: 16; implicitHeight: 16; radius: 8
                                    color: monBtn.isSelected ? Config.accent : Qt.rgba(255, 255, 255, 0.08)
                                    Text {
                                        anchors.centerIn: parent
                                        text: monBtn.isSelected ? "✓" : "+"
                                        font.pixelSize: 9
                                        font.bold: true
                                        color: monBtn.isSelected ? Config.bgBase : Config.textMuted
                                    }
                                }
                            }

                            MouseArea {
                                id: monHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Config.toggleWallpaperMonitor(modelData.name)
                            }
                        }
                    }
                }
            }
        }

        // ==========================================
        // 5. TRANSITION EFFECT CARD
        // ==========================================
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: transCol.implicitHeight + 28
            radius: Config.cornerRadius
            color: Qt.rgba(255, 255, 255, 0.05)
            border.width: 1
            border.color: Qt.rgba(255, 255, 255, 0.1)

            ColumnLayout {
                id: transCol
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                Text {
                    text: "TRANSITIONS"
                    color: Config.textMain
                    font.family: Config.sysFont
                    font.pixelSize: Config.size(Config.fontBody)
                    font.bold: true
                }

                GridLayout {
                    columns: 4
                    rowSpacing: 8
                    columnSpacing: 8
                    Layout.fillWidth: true

                    Repeater {
                        model: root.awwwTransitions

                        delegate: Rectangle {
                            id: transBtn
                            Layout.fillWidth: true
                            implicitHeight: 34
                            radius: Config.cornerRadius / 2
                            readonly property bool isSelected: (Config.wallpaperTransitionType || "fade") === modelData.name
                            color: isSelected ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.16) : (transHover.containsMouse ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(0, 0, 0, 0.2))
                            border.width: isSelected ? 1.5 : 1
                            border.color: isSelected ? Config.accent : Qt.rgba(255, 255, 255, 0.08)

                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    text: modelData.icon
                                    font.family: "Material Symbols Outlined"
                                    font.pixelSize: 14
                                    color: transBtn.isSelected ? Config.accent : Config.textMuted
                                }

                                Text {
                                    text: modelData.name
                                    color: transBtn.isSelected ? Config.accent : Config.textMain
                                    font.family: Config.sysFont
                                    font.pixelSize: 11
                                    font.bold: transBtn.isSelected
                                }
                            }

                            MouseArea {
                                id: transHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Config.wallpaperTransitionType = modelData.name
                                    if (typeof Config.saveSettings === "function") Config.saveSettings()
                                }
                            }
                        }
                    }
                }
            }
        }

        // ==========================================
        // 6. WALLPAPER LIBRARY GALLERY CARD
        // ==========================================
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: Math.max(320, galleryCol.implicitHeight + 28)
            radius: Config.cornerRadius
            color: Qt.rgba(255, 255, 255, 0.05)
            border.width: 1
            border.color: Qt.rgba(255, 255, 255, 0.1)

            ColumnLayout {
                id: galleryCol
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true

                    ColumnLayout {
                        spacing: 2
                        Text {
                            text: "WALLPAPER GALLERY"
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontBody)
                            font.bold: true
                        }
                        Text {
                            text: "~/Pictures/Wallpapers"
                            color: Config.textMuted
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontMicro)
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        implicitWidth: wpCountText.implicitWidth + 16
                        implicitHeight: 24
                        radius: 12
                        color: Qt.rgba(255, 255, 255, 0.08)

                        Text {
                            id: wpCountText
                            anchors.centerIn: parent
                            text: ((Config.wallpapers ? Config.wallpapers.length : 0)) + " Wallpapers"
                            font.family: Config.sysFont
                            font.pixelSize: 11
                            font.bold: true
                            color: Config.textMuted
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: Math.max(260, gridView.contentHeight + 12)
                    color: Qt.rgba(0, 0, 0, 0.3)
                    radius: Config.cornerRadius / 2
                    border.width: 1
                    border.color: Qt.rgba(255, 255, 255, 0.08)
                    clip: true

                    GridView {
                        id: gridView
                        anchors.fill: parent
                        anchors.margins: 6
                        cellWidth: width / 3
                        cellHeight: Math.floor(cellWidth * (9 / 16)) + 8

                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        cacheBuffer: 4000
                        reuseItems: true
                        model: Config.wallpapers

                        delegate: Item {
                            id: delegateItem
                            width: gridView.cellWidth
                            height: gridView.cellHeight

                            readonly property string rawModelPath: "" + (modelData || "")
                            readonly property string cleanPath: rawModelPath.replace(/^file:\/\//, "").trim()
                            readonly property string fileName: cleanPath.split('/').pop()
                            readonly property string baseName: fileName.replace(/\.[^/.]+$/, "")
                            readonly property string fileExt: cleanPath.split('.').pop().toLowerCase()
                            readonly property bool isVideo: fileExt === "mp4" || fileExt === "webm"

                            // Extract raw active target from root or Config
                            readonly property string rawActive: "" + (root.currentWallpaperPath || Config.activeWallpaperPath || "")
                            readonly property string activeClean: rawActive.replace(/^file:\/\//, "").trim()
                            readonly property string activeFileName: activeClean.split('/').pop()

                            // Compare full paths OR matching basenames/filenames
                            readonly property bool isCurrent: {
                                if (!cleanPath || !activeClean) return false
                                if (cleanPath === activeClean) return true
                                if (fileName.length > 0 && activeFileName.length > 0 && fileName === activeFileName) return true
                                return false
                            }

                            readonly property string imageSource: isVideo ? 
                                ("file://" + Quickshell.env("HOME") + "/.cache/wallpaper-thumbs/" + baseName + ".jpg") : 
                                ("file://" + cleanPath)

                            Item {
                                anchors.fill: parent
                                anchors.margins: 4

                                ClippingRectangle {
                                    anchors.fill: parent
                                    radius: Config.cornerRadius / 2
                                    color: Qt.rgba(255, 255, 255, 0.05)

                                    Image {
                                        anchors.fill: parent
                                        source: delegateItem.imageSource
                                        fillMode: Image.PreserveAspectCrop
                                        sourceSize.width: 320
                                        sourceSize.height: 180
                                        asynchronous: true
                                        cache: true
                                    }

                                    Rectangle {
                                        width: 22
                                        height: 22
                                        radius: 11
                                        color: Qt.rgba(0, 0, 0, 0.7)
                                        anchors.bottom: parent.bottom
                                        anchors.left: parent.left
                                        anchors.margins: 6
                                        visible: delegateItem.isVideo

                                        Text {
                                            anchors.centerIn: parent
                                            text: "play_arrow"
                                            font.family: "Material Symbols Outlined"
                                            font.pixelSize: 13
                                            color: "#FFFFFF"
                                        }
                                    }

                                    Rectangle {
                                        width: 22
                                        height: 22
                                        radius: 11
                                        color: Config.accent
                                        anchors.top: parent.top
                                        anchors.right: parent.right
                                        anchors.margins: 6
                                        visible: delegateItem.isCurrent

                                        Text {
                                            anchors.centerIn: parent
                                            text: "✓"
                                            font.pixelSize: 12
                                            font.bold: true
                                            color: Config.bgBase
                                        }
                                    }
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: Config.cornerRadius / 2
                                    color: "transparent"
                                    border.width: delegateItem.isCurrent ? 2.5 : (cardHover.containsMouse ? 1.5 : 0)
                                    border.color: Config.accent
                                }

                                MouseArea {
                                    id: cardHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        wallpaperBackend.applyWallpaper(delegateItem.cleanPath)
                                        root.currentWallpaperPath = delegateItem.cleanPath
                                        Config.activeWallpaperPath = delegateItem.cleanPath
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true; implicitHeight: 20 }
    }
}