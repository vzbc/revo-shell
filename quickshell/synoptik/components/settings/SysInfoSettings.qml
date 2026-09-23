import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import ".."

Flickable {
    id: flickable
    Layout.fillWidth: true
    Layout.fillHeight: true
    contentWidth: width
    contentHeight: contentColumn.implicitHeight + 32
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AsNeeded
        active: flickable.moving || flickable.flicking
    }

    readonly property real cardMargin: Config.cardMargin !== undefined ? Config.cardMargin : 12

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

    ColumnLayout {
        id: contentColumn
        width: Math.min(flickable.width - (flickable.cardMargin * 2), 620)
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: flickable.cardMargin

        Text {
            Layout.fillWidth: true
            text: "SYSTEM INFO OVERLAY CONFIGURATION"
            color: Config.textMain
            font.family: Config.sysFont
            font.pixelSize: Config.size(Config.fontSubhead)
            font.bold: true
        }

        Text {
            text: "Configure the desktop BGInfo-style telemetry overlay. Toggle individual system identifiers, hardware specs, network routing metrics, and resource bars."
            color: Config.textMuted
            font.family: Config.sysFont
            font.pixelSize: Config.size(Config.fontCaption)
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
        }

        // ==========================================
        // 1. MASTER WIDGET TOGGLE
        // ==========================================
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: masterCol.implicitHeight + 28
            radius: Config.cornerRadius
            color: Qt.rgba(255, 255, 255, 0.05)
            border.width: 1
            border.color: Qt.rgba(255, 255, 255, 0.1)

            ColumnLayout {
                id: masterCol
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

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
                            text: "Enable Desktop System Info Overlay"
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontBody)
                            font.bold: true
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Renders live system telemetry, hardware specifications, and resource bars directly onto your desktop."
                            color: Config.textMuted
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontCaption)
                            wrapMode: Text.WordWrap
                        }
                    }

                    ToggleSwitch {
                        checked: Config.showDesktopSysInfo !== false

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Config.showDesktopSysInfo = (Config.showDesktopSysInfo === false)
                                if (typeof Config.saveConfig === "function") Config.saveConfig()
                                else if (typeof Config.save === "function") Config.save()
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 34
                    radius: Config.cornerRadius / 2
                    color: Qt.rgba(0, 0, 0, 0.25)

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: "mouse"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 15
                            color: Config.accent
                        }

                        Text {
                            text: "Click + Drag anywhere to reposition. Scroll wheel directly on the widget to scale."
                            font.family: Config.sysFont
                            font.pixelSize: 11
                            color: Config.textMuted
                        }
                    }
                }
            }
        }

        // ==========================================
        // 2. TARGET MONITOR SELECTION CARD
        // ==========================================
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: monitorCol.implicitHeight + 28
            radius: Config.cornerRadius
            color: Qt.rgba(255, 255, 255, 0.05)
            border.width: 1
            border.color: Qt.rgba(255, 255, 255, 0.1)

            ColumnLayout {
                id: monitorCol
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                Text {
                    text: "TARGET DISPLAY OUTPUTS"
                    color: Config.textMuted
                    font.family: Config.sysFont
                    font.pixelSize: Config.size(Config.fontMicro)
                    font.bold: true
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Repeater {
                        model: Quickshell.screens

                        delegate: Rectangle {
                            id: monPill
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            implicitHeight: 36
                            radius: Config.cornerRadius / 2

                            readonly property string scrName: (modelData && modelData.name) ? modelData.name : ""
                            readonly property bool isEnabled: Config.isSysInfoEnabledForScreen ? Config.isSysInfoEnabledForScreen(scrName) : true

                            color: isEnabled 
                                ? Config.accent 
                                : (monHover.containsMouse ? Qt.rgba(255, 255, 255, 0.12) : Qt.rgba(0, 0, 0, 0.2))
                            border.width: isEnabled ? 1.5 : 1
                            border.color: isEnabled ? Config.accent : Qt.rgba(255, 255, 255, 0.08)

                            Behavior on color { ColorAnimation { duration: 150 } }

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    text: "desktop_windows"
                                    font.family: "Material Symbols Outlined"
                                    font.pixelSize: 16
                                    color: monPill.isEnabled ? Config.bgBase : Config.accent
                                    verticalAlignment: Text.AlignVCenter
                                }

                                Text {
                                    text: monPill.scrName
                                    font.family: Config.sysFont
                                    font.pixelSize: Config.size(Config.fontCaption)
                                    font.bold: true
                                    color: monPill.isEnabled ? Config.bgBase : Config.textMain
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }

                            MouseArea {
                                id: monHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (Config.toggleSysInfoScreen) {
                                        Config.toggleSysInfoScreen(monPill.scrName)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ==========================================
        // 3. SYSTEM & OS IDENTIFIERS
        // ==========================================
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: osGroupCol.implicitHeight + 28
            radius: Config.cornerRadius
            color: Qt.rgba(255, 255, 255, 0.05)
            border.width: 1
            border.color: Qt.rgba(255, 255, 255, 0.1)

            ColumnLayout {
                id: osGroupCol
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                Text {
                    text: "SYSTEM & OS IDENTIFIERS"
                    color: Config.textMuted
                    font.family: Config.sysFont
                    font.pixelSize: Config.size(Config.fontMicro)
                    font.bold: true
                }

                Repeater {
                    model: [
                        { key: "sysInfoShowHost",     label: "Host & User Header",       desc: "Display username@hostname header badge with accent glow", icon: "badge",              def: true },
                        { key: "sysInfoShowOs",       label: "Operating System Distro",  desc: "Linux distribution release name (e.g. Arch Linux)",      icon: "desktop_windows",    def: true },
                        { key: "sysInfoShowKernel",   label: "Kernel Release",           desc: "Running Linux kernel version (uname -r)",                icon: "memory",             def: true },
                        { key: "sysInfoShowUptime",   label: "System Uptime",            desc: "Elapsed time since last boot cycle",                     icon: "history",            def: true },
                        { key: "sysInfoShowPackages", label: "Installed Packages",       desc: "Total installed pacman package count",                   icon: "inventory_2",        def: true },
                        { key: "sysInfoShowWm",       label: "Compositor / Window Mgr",  desc: "Active Wayland compositor and build tag",                icon: "view_carousel",       def: true }
                    ]

                    delegate: RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        readonly property bool isChecked: Config[modelData.key] !== undefined ? Config[modelData.key] : modelData.def

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            Layout.minimumWidth: 0
                            spacing: 2

                            RowLayout {
                                spacing: 6
                                Text { text: modelData.icon; font.family: "Material Symbols Outlined"; font.pixelSize: 15; color: Config.accent }
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.label
                                    color: Config.textMain
                                    font.family: Config.sysFont
                                    font.pixelSize: Config.size(Config.fontBody)
                                    font.bold: true
                                    wrapMode: Text.WordWrap
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.desc
                                color: Config.textMuted
                                font.family: Config.sysFont
                                font.pixelSize: Config.size(Config.fontCaption)
                                wrapMode: Text.WordWrap
                            }
                        }

                        ToggleSwitch {
                            checked: parent.isChecked

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Config[modelData.key] = !parent.parent.isChecked
                                    if (typeof Config.saveConfig === "function") Config.saveConfig()
                                    else if (typeof Config.save === "function") Config.save()
                                }
                            }
                        }
                    }
                }
            }
        }

        // ==========================================
        // 4. HARDWARE SPECIFICATIONS
        // ==========================================
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: hwGroupCol.implicitHeight + 28
            radius: Config.cornerRadius
            color: Qt.rgba(255, 255, 255, 0.05)
            border.width: 1
            border.color: Qt.rgba(255, 255, 255, 0.1)

            ColumnLayout {
                id: hwGroupCol
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                Text {
                    text: "HARDWARE SPECIFICATIONS"
                    color: Config.textMuted
                    font.family: Config.sysFont
                    font.pixelSize: Config.size(Config.fontMicro)
                    font.bold: true
                }

                Repeater {
                    model: [
                        { key: "sysInfoShowBoard", label: "Motherboard / Machine Model", desc: "DMI hardware product and chassis identifier",  icon: "developer_board", def: true },
                        { key: "sysInfoShowCpu",   label: "Processor Model",             desc: "CPU architecture brand and model identifier",   icon: "memory_alt",      def: true },
                        { key: "sysInfoShowCores", label: "CPU Core & Thread Count",     desc: "Total accessible logical processor threads",    icon: "grid_view",       def: true },
                        { key: "sysInfoShowLoad",  label: "System Load Averages",        desc: "1, 5, and 15-minute system load averages",       icon: "speed",           def: true },
                        { key: "sysInfoShowGpu",   label: "Dedicated Graphics (GPU)",    desc: "PCI display adapter and GPU controller name",   icon: "videogame_asset", def: true }
                    ]

                    delegate: RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        readonly property bool isChecked: Config[modelData.key] !== undefined ? Config[modelData.key] : modelData.def

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            Layout.minimumWidth: 0
                            spacing: 2

                            RowLayout {
                                spacing: 6
                                Text { text: modelData.icon; font.family: "Material Symbols Outlined"; font.pixelSize: 15; color: Config.accent }
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.label
                                    color: Config.textMain
                                    font.family: Config.sysFont
                                    font.pixelSize: Config.size(Config.fontBody)
                                    font.bold: true
                                    wrapMode: Text.WordWrap
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.desc
                                color: Config.textMuted
                                font.family: Config.sysFont
                                font.pixelSize: Config.size(Config.fontCaption)
                                wrapMode: Text.WordWrap
                            }
                        }

                        ToggleSwitch {
                            checked: parent.isChecked

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Config[modelData.key] = !parent.parent.isChecked
                                    if (typeof Config.saveConfig === "function") Config.saveConfig()
                                    else if (typeof Config.save === "function") Config.save()
                                }
                            }
                        }
                    }
                }
            }
        }

        // ==========================================
        // 5. NETWORK & ROUTING METRICS
        // ==========================================
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: netGroupCol.implicitHeight + 28
            radius: Config.cornerRadius
            color: Qt.rgba(255, 255, 255, 0.05)
            border.width: 1
            border.color: Qt.rgba(255, 255, 255, 0.1)

            ColumnLayout {
                id: netGroupCol
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                Text {
                    text: "NETWORK & ROUTING METRICS"
                    color: Config.textMuted
                    font.family: Config.sysFont
                    font.pixelSize: Config.size(Config.fontMicro)
                    font.bold: true
                }

                Repeater {
                    model: [
                        { key: "sysInfoShowIp",      label: "Primary IPv4 Address", desc: "Default routed private interface address", icon: "lan",        def: true },
                        { key: "sysInfoShowGateway", label: "Default Gateway",      desc: "Default upstream gateway router IP",        icon: "router",     def: true },
                        { key: "sysInfoShowDns",     label: "DNS Server",           desc: "Primary name resolution server",            icon: "dns",        def: true }
                    ]

                    delegate: RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        readonly property bool isChecked: Config[modelData.key] !== undefined ? Config[modelData.key] : modelData.def

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            Layout.minimumWidth: 0
                            spacing: 2

                            RowLayout {
                                spacing: 6
                                Text { text: modelData.icon; font.family: "Material Symbols Outlined"; font.pixelSize: 15; color: Config.accent }
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.label
                                    color: Config.textMain
                                    font.family: Config.sysFont
                                    font.pixelSize: Config.size(Config.fontBody)
                                    font.bold: true
                                    wrapMode: Text.WordWrap
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.desc
                                color: Config.textMuted
                                font.family: Config.sysFont
                                font.pixelSize: Config.size(Config.fontCaption)
                                wrapMode: Text.WordWrap
                            }
                        }

                        ToggleSwitch {
                            checked: parent.isChecked

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Config[modelData.key] = !parent.parent.isChecked
                                    if (typeof Config.saveConfig === "function") Config.saveConfig()
                                    else if (typeof Config.save === "function") Config.save()
                                }
                            }
                        }
                    }
                }
            }
        }

        // ==========================================
        // 6. RESOURCE CAPACITY GAUGES
        // ==========================================
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: gaugesGroupCol.implicitHeight + 28
            radius: Config.cornerRadius
            color: Qt.rgba(255, 255, 255, 0.05)
            border.width: 1
            border.color: Qt.rgba(255, 255, 255, 0.1)

            ColumnLayout {
                id: gaugesGroupCol
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                Text {
                    text: "RESOURCE USAGE BARS"
                    color: Config.textMuted
                    font.family: Config.sysFont
                    font.pixelSize: Config.size(Config.fontMicro)
                    font.bold: true
                }

                Repeater {
                    model: [
                        { key: "sysInfoShowRam",      label: "Memory (RAM) Gauge",      desc: "Live physical memory usage and visual capacity bar", icon: "memory",     def: true },
                        { key: "sysInfoShowSwap",     label: "Swap Memory Gauge",       desc: "Swap space allocation and usage bar",                icon: "swap_horiz", def: true },
                        { key: "sysInfoShowDisk",     label: "Root Storage (/) Gauge",  desc: "Root filesystem partition fill level",               icon: "hard_drive", def: true },
                        { key: "sysInfoShowDiskHome", label: "Home Storage (/home) Bar",desc: "User home directory filesystem fill level",         icon: "folder",     def: true }
                    ]

                    delegate: RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        readonly property bool isChecked: Config[modelData.key] !== undefined ? Config[modelData.key] : modelData.def

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            Layout.minimumWidth: 0
                            spacing: 2

                            RowLayout {
                                spacing: 6
                                Text { text: modelData.icon; font.family: "Material Symbols Outlined"; font.pixelSize: 15; color: Config.accent }
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.label
                                    color: Config.textMain
                                    font.family: Config.sysFont
                                    font.pixelSize: Config.size(Config.fontBody)
                                    font.bold: true
                                    wrapMode: Text.WordWrap
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.desc
                                color: Config.textMuted
                                font.family: Config.sysFont
                                font.pixelSize: Config.size(Config.fontCaption)
                                wrapMode: Text.WordWrap
                            }
                        }

                        ToggleSwitch {
                            checked: parent.isChecked

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Config[modelData.key] = !parent.parent.isChecked
                                    if (typeof Config.saveConfig === "function") Config.saveConfig()
                                    else if (typeof Config.save === "function") Config.save()
                                }
                            }
                        }
                    }
                }
            }
        }

        // ==========================================
        // 7. VISUAL STYLING & UPDATE INTERVAL
        // ==========================================
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: styleCol.implicitHeight + 28
            radius: Config.cornerRadius
            color: Qt.rgba(255, 255, 255, 0.05)
            border.width: 1
            border.color: Qt.rgba(255, 255, 255, 0.1)

            ColumnLayout {
                id: styleCol
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                Text {
                    text: "VISUAL STYLING & UPDATE INTERVAL"
                    color: Config.textMuted
                    font.family: Config.sysFont
                    font.pixelSize: Config.size(Config.fontMicro)
                    font.bold: true
                }

                // Card Background Toggle
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
                            text: "Show Card Background"
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontBody)
                            font.bold: true
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Renders a semi-transparent background panel behind the system info widget."
                            color: Config.textMuted
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontCaption)
                            wrapMode: Text.WordWrap
                        }
                    }

                    ToggleSwitch {
                        checked: Config.sysInfoShowBg !== false

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Config.sysInfoShowBg = (Config.sysInfoShowBg === false)
                                if (typeof Config.saveConfig === "function") Config.saveConfig()
                                else if (typeof Config.save === "function") Config.save()
                            }
                        }
                    }
                }

                // Accent Glow Toggle
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
                            text: "Show Accent Glow"
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontBody)
                            font.bold: true
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Applies a colored glow effect using the current accent color to the host header badge."
                            color: Config.textMuted
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontCaption)
                            wrapMode: Text.WordWrap
                        }
                    }

                    ToggleSwitch {
                        checked: Config.sysInfoShowGlow !== false

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Config.sysInfoShowGlow = (Config.sysInfoShowGlow === false)
                                if (typeof Config.saveConfig === "function") Config.saveConfig()
                                else if (typeof Config.save === "function") Config.save()
                            }
                        }
                    }
                }

                // Polling Interval Presets
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    Layout.topMargin: 4

                    Text {
                        text: "Refresh Rate:"
                        color: Config.textMain
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontCaption)
                        font.bold: true
                    }

                    Repeater {
                        model: [
                            { label: "1s (Realtime)", ms: 1000 },
                            { label: "3s (Balanced)", ms: 3000 },
                            { label: "10s (Eco)", ms: 10000 }
                        ]

                        delegate: Rectangle {
                            id: intPill
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            implicitHeight: 30
                            radius: 15

                            readonly property bool isSelected: (Config.sysInfoRefreshInterval || 3000) === modelData.ms
                            color: isSelected ? Config.accent : (intHover.containsMouse ? Qt.rgba(255, 255, 255, 0.12) : Qt.rgba(0, 0, 0, 0.2))

                            Behavior on color { ColorAnimation { duration: 150 } }

                            Text {
                                anchors.centerIn: parent
                                text: modelData.label
                                font.family: Config.sysFont
                                font.pixelSize: 11
                                font.bold: true
                                color: intPill.isSelected ? Config.bgBase : Config.textMain
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            MouseArea {
                                id: intHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Config.sysInfoRefreshInterval = modelData.ms
                                    if (typeof Config.saveConfig === "function") Config.saveConfig()
                                    else if (typeof Config.save === "function") Config.save()
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