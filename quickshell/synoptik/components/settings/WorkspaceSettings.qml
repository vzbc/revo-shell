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
    contentHeight: contentColumn.implicitHeight + 40
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

    // Interactive Preview State
    property int previewActiveWs: 2
    property bool previewOverviewActive: false
    property bool previewMagicActive: false
    property var previewWorkspaces: [
        { id: 1, name: "Code",    windows: 2, icon: "terminal", appIcon: "utilities-terminal", activeApp: "Ghostty" },
        { id: 2, name: "Web",     windows: 4, icon: "globe",    appIcon: "firefox",            activeApp: "Firefox" },
        { id: 3, name: "Design",  windows: 1, icon: "palette",  appIcon: "inkscape",           activeApp: "Figma" },
        { id: 4, name: "Chat",    windows: 3, icon: "chat",     appIcon: "discord",            activeApp: "Discord" }
    ]

    ColumnLayout {
        id: contentColumn
        // Constrain width strictly to Flickable viewport minus outer margins
        width: Math.min(flickable.width - (flickable.cardMargin * 2), 620)
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: flickable.cardMargin

        // Header Title
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: "WORKSPACE INDICATORS"
                color: Config.textMain
                font.family: Config.sysFont
                font.pixelSize: Config.size(Config.fontSubhead)
                font.bold: true
                wrapMode: Text.WordWrap
            }

            Text {
                Layout.fillWidth: true
                text: "Customize desktop switcher styles, animations, mini window pips, and capsule layouts"
                color: Config.textMuted
                font.family: Config.sysFont
                font.pixelSize: Config.size(Config.fontCaption)
                wrapMode: Text.WordWrap
            }
        }

        // ==========================================
        // 1. LIVE INTERACTIVE PREVIEW
        // ==========================================
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: previewCol.implicitHeight + 28
            radius: Config.cornerRadius
            color: Qt.rgba(255, 255, 255, 0.05)
            border.width: 1
            border.color: Qt.rgba(255, 255, 255, 0.1)

            ColumnLayout {
                id: previewCol
                anchors.fill: parent
                anchors.margins: 14
                spacing: 14

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "LIVE PREVIEW"
                        color: Config.textMuted
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontMicro)
                        font.bold: true
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: "Click icons to test interactions"
                        color: Config.accent
                        font.family: Config.sysFont
                        font.pixelSize: 11
                        font.bold: true
                    }
                }

                // Simulated Bar Container
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 64
                    radius: Config.cornerRadius / 2
                    color: Qt.rgba(0, 0, 0, 0.35)
                    border.width: 1
                    border.color: Qt.rgba(255, 255, 255, 0.08)

                    // Capsule wrapper (if enabled)
                    Rectangle {
                        anchors.centerIn: parent
                        implicitHeight: 40
                        implicitWidth: previewRow.implicitWidth + (Config.workspaceContainerStyle === "plain" ? 0 : 20)
                        radius: (Config.workspaceContainerStyle === "bordered") ? 8 : 20
                        color: Config.workspaceContainerStyle === "capsule" 
                            ? Qt.rgba(255, 255, 255, 0.08) 
                            : (Config.workspaceContainerStyle === "bordered" ? Qt.rgba(0, 0, 0, 0.18) : "transparent")
                        border.width: Config.workspaceContainerStyle === "bordered" ? 1.5 : (Config.workspaceContainerStyle === "capsule" ? 1 : 0)
                        border.color: Config.workspaceContainerStyle === "bordered" ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.5) : Qt.rgba(255, 255, 255, 0.12)

                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        RowLayout {
                            id: previewRow
                            anchors.centerIn: parent
                            spacing: 8

                            // Workspaces Group
                            RowLayout {
                                spacing: 8

                                Repeater {
                                    model: flickable.previewWorkspaces

                                    delegate: Rectangle {
                                        id: previewPillItem
                                        readonly property bool isActive: flickable.previewActiveWs === modelData.id
                                        readonly property string style: Config.workspaceStyle || "pill"

                                        // Width depends on selected style
                                        implicitWidth: {
                                            if (style === "sliding") return isActive ? 32 : 10
                                            if (style === "numeric") return isActive ? 34 : 22
                                            if (style === "app_icons") return isActive ? 44 : 26
                                            if (style === "window_pips") return isActive ? 36 : 24
                                            if (style === "geometric") return isActive ? 32 : 14
                                            return isActive ? 32 : 10 // default pill
                                        }
                                        implicitHeight: {
                                            if (style === "sliding") return isActive ? 12 : 20
                                            if (style === "app_icons" || style === "numeric" || style === "window_pips") return 22
                                            return 12
                                        }
                                        radius: (style === "sliding") ? height / 3 : ((style === "geometric") ? 3 : height / 2)

                                        color: {
                                            if (style === "geometric") {
                                                return isActive 
                                                    ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.35) 
                                                    : (pMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.12) : "transparent")
                                            }
                                            return isActive ? Config.accent : (pMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.18) : "transparent")
                                        }

                                        border.width: (style === "sliding") ? (isActive ? 0 : 3) : (isActive ? (style === "geometric" ? 2 : 0) : 2)
                                        border.color: (style === "sliding")
                                            ? (isActive ? "transparent" : (pMouse.containsMouse ? Config.accent : Qt.rgba(255, 255, 255, 0.3)))
                                            : (isActive 
                                                ? (style === "geometric" ? Config.accent : "transparent") 
                                                : (pMouse.containsMouse ? Config.accent : Qt.rgba(255, 255, 255, 0.3)))

                                        Behavior on implicitWidth { NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                        Behavior on border.color { ColorAnimation { duration: 150 } }

                                        // Glow on active/hovered
                                        Glow {
                                            anchors.fill: parent
                                            source: previewPillItem
                                            radius: (Config.workspaceGlow !== false && (isActive || pMouse.containsMouse)) ? 8 : 0
                                            samples: 16
                                            color: Config.accent
                                            spread: 0.2
                                            transparentBorder: true
                                            visible: Config.workspaceGlow !== false && (isActive || pMouse.containsMouse)
                                            Behavior on radius { NumberAnimation { duration: 150 } }
                                        }

                                        // Content inside the pill (Numbers, Pips, App Icons)
                                        RowLayout {
                                            anchors.centerIn: parent
                                            spacing: 3

                                            // 1. NUMERIC STYLE
                                            Text {
                                                visible: (style === "numeric")
                                                text: modelData.id
                                                font.family: Config.sysFont
                                                font.pixelSize: 10
                                                font.bold: true
                                                color: isActive ? Config.bgBase : Config.textMain
                                            }

                                            // 2. APP ICONS STYLE
                                            Text {
                                                visible: (style === "app_icons")
                                                text: modelData.icon === "terminal" ? "terminal" : (modelData.icon === "globe" ? "language" : (modelData.icon === "palette" ? "brush" : "forum"))
                                                font.family: "Material Symbols Outlined"
                                                font.pixelSize: 13
                                                color: isActive ? Config.bgBase : Config.textMain
                                            }

                                            // 3. WINDOW DENSITY PIPS
                                            Row {
                                                visible: (style === "window_pips")
                                                spacing: 2
                                                Repeater {
                                                    model: Math.min(modelData.windows, 3)
                                                    Rectangle {
                                                        width: 3; height: 3; radius: 1.5
                                                        color: isActive ? Config.bgBase : Config.accent
                                                    }
                                                }
                                            }
                                        }

                                        MouseArea {
                                            id: pMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: flickable.previewActiveWs = modelData.id
                                        }
                                    }
                                }
                            }

                            // Divider
                            Rectangle {
                                implicitWidth: 1
                                implicitHeight: 16
                                color: Qt.rgba(255, 255, 255, 0.15)
                                visible: (Config.workspaceShowAddBtn !== false) || (Config.workspaceShowOverviewBtn !== false) || (Config.workspaceShowSpecial !== false)
                            }

                            // Actions Group
                            RowLayout {
                                spacing: 4

                                // Add Button
                                Rectangle {
                                    implicitWidth: 26; implicitHeight: 26; radius: 13
                                    visible: Config.workspaceShowAddBtn !== false
                                    color: addHover.containsMouse ? Qt.rgba(255, 255, 255, 0.15) : "transparent"

                                    Text {
                                        anchors.centerIn: parent
                                        text: "+"
                                        font.family: Config.sysFont
                                        font.pixelSize: 16
                                        font.bold: true
                                        color: addHover.containsMouse ? Config.accent : Qt.rgba(255, 255, 255, 0.5)
                                    }

                                    MouseArea {
                                        id: addHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (flickable.previewWorkspaces.length < 6) {
                                                let nextId = flickable.previewWorkspaces.length + 1
                                                flickable.previewWorkspaces.push({ id: nextId, name: "New", windows: 1, icon: "terminal", appIcon: "terminal", activeApp: "App" })
                                                flickable.previewActiveWs = nextId
                                            }
                                        }
                                    }
                                }

                                // Overview Button
                                Rectangle {
                                    implicitWidth: 26; implicitHeight: 26; radius: 13
                                    visible: Config.workspaceShowOverviewBtn !== false
                                    color: flickable.previewOverviewActive ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.3) : (ovHover.containsMouse ? Qt.rgba(255, 255, 255, 0.15) : "transparent")
                                    border.width: flickable.previewOverviewActive ? 1 : 0
                                    border.color: Config.accent

                                    Text {
                                        anchors.centerIn: parent
                                        text: Config.getIcon("overview")
                                        font.family: "Material Symbols Outlined"
                                        font.pixelSize: 15
                                        color: (flickable.previewOverviewActive || ovHover.containsMouse) ? Config.accent : Qt.rgba(255, 255, 255, 0.5)
                                    }

                                    MouseArea {
                                        id: ovHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: flickable.previewOverviewActive = !flickable.previewOverviewActive
                                    }
                                }

                                // Special Workspace (Magic)
                                Rectangle {
                                    implicitWidth: 26; implicitHeight: 26; radius: 13
                                    visible: Config.workspaceShowSpecial !== false
                                    color: flickable.previewMagicActive ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.3) : (magicHover.containsMouse ? Qt.rgba(255, 255, 255, 0.15) : "transparent")
                                    border.width: flickable.previewMagicActive ? 1 : 0
                                    border.color: Config.accent

                                    Text {
                                        anchors.centerIn: parent
                                        text: Config.getIcon("magic")
                                        font.family: "Material Symbols Outlined"
                                        font.pixelSize: 15
                                        color: (flickable.previewMagicActive || magicHover.containsMouse) ? Config.accent : Qt.rgba(255, 255, 255, 0.5)
                                    }

                                    MouseArea {
                                        id: magicHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: flickable.previewMagicActive = !flickable.previewMagicActive
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ==========================================
        // 2. INDICATOR VISUAL STYLE
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
                    text: "INDICATOR VISUAL STYLE"
                    color: Config.textMuted
                    font.family: Config.sysFont
                    font.pixelSize: Config.size(Config.fontMicro)
                    font.bold: true
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 3
                    rowSpacing: 10
                    columnSpacing: 10

                    Repeater {
                        model: [
                            { id: "app_icons",   label: "App Micro-Icons",  icon: "apps",          desc: "Running client icons",     preview: "term · web · chat" },
                            { id: "numeric",     label: "Numeric Badges",   icon: "tag",           desc: "Bold index numbers",       preview: "1  [2]  3" },
                            { id: "window_pips", label: "Window Pips",      icon: "more_horiz",    desc: "Density micro-dots",       preview: "• ••• •" },
                            { id: "pill",        label: "Dynamic Pill",     icon: "view_stream",   desc: "Morphing accent capsule", preview: "● ━━ ●" },
                            { id: "sliding",     label: "Morphing Pillar",  icon: "swap_horiz",    desc: "Narrow tall / wide short", preview: "▮  ━━  ▮" },
                            { id: "geometric",   label: "Cyber Geometric",  icon: "diamond",       desc: "Segmented wireframe",      preview: "◇  ◆  ◇" }
                        ]

                        delegate: Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            Layout.minimumWidth: 0
                            implicitHeight: 82
                            radius: Config.cornerRadius / 2

                            readonly property bool isSelected: (Config.workspaceStyle || "pill") === modelData.id

                            color: isSelected 
                                ? Qt.rgba(255, 255, 255, 0.14) 
                                : (styleHover.containsMouse ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(0, 0, 0, 0.2))
                            border.width: isSelected ? 1.5 : 1
                            border.color: isSelected ? Config.accent : Qt.rgba(255, 255, 255, 0.08)

                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 3

                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignHCenter
                                    spacing: 6

                                    Text {
                                        text: modelData.icon
                                        font.family: "Material Symbols Outlined"
                                        font.pixelSize: 18
                                        color: isSelected ? Config.accent : Config.textMuted
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.label
                                        font.family: Config.sysFont
                                        font.pixelSize: Config.size(Config.fontCaption)
                                        font.bold: true
                                        color: isSelected ? Config.accent : Config.textMain
                                        elide: Text.ElideRight
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.desc
                                    font.family: Config.sysFont
                                    font.pixelSize: 10
                                    color: Config.textMuted
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.preview
                                    font.family: Config.sysFont
                                    font.pixelSize: 11
                                    font.bold: true
                                    color: isSelected ? Config.accent : Qt.rgba(255, 255, 255, 0.4)
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                }
                            }

                            MouseArea {
                                id: styleHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Config.workspaceStyle = modelData.id
                            }
                        }
                    }
                }
            }
        }

        // ==========================================
        // 3. CONTAINER & CAPSULE FRAME
        // ==========================================
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: containerCol.implicitHeight + 28
            radius: Config.cornerRadius
            color: Qt.rgba(255, 255, 255, 0.05)
            border.width: 1
            border.color: Qt.rgba(255, 255, 255, 0.1)

            ColumnLayout {
                id: containerCol
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                Text {
                    text: "CONTAINER & CAPSULE FRAME"
                    color: Config.textMuted
                    font.family: Config.sysFont
                    font.pixelSize: Config.size(Config.fontMicro)
                    font.bold: true
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Repeater {
                        model: [
                            { id: "plain",    label: "Frameless Minimal", icon: "border_clear", desc: "No surrounding pill frame" },
                            { id: "capsule",  label: "Frosted Capsule",   icon: "view_stream",  desc: "Rounded glass capsule" },
                            { id: "bordered", label: "Cyber Frame",       icon: "border_style", desc: "Sharp bordered outline" }
                        ]

                        delegate: Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            Layout.minimumWidth: 0
                            implicitHeight: 68
                            radius: Config.cornerRadius / 2

                            readonly property bool isSelected: (Config.workspaceContainerStyle || "plain") === modelData.id

                            color: isSelected 
                                ? Qt.rgba(255, 255, 255, 0.14) 
                                : (cHover.containsMouse ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(0, 0, 0, 0.2))
                            border.width: isSelected ? 1.5 : 1
                            border.color: isSelected ? Config.accent : Qt.rgba(255, 255, 255, 0.08)

                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 3

                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignHCenter
                                    spacing: 6

                                    Text {
                                        text: modelData.icon
                                        font.family: "Material Symbols Outlined"
                                        font.pixelSize: 18
                                        color: isSelected ? Config.accent : Config.textMuted
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.label
                                        font.family: Config.sysFont
                                        font.pixelSize: Config.size(Config.fontCaption)
                                        font.bold: true
                                        color: isSelected ? Config.accent : Config.textMain
                                        elide: Text.ElideRight
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.desc
                                    font.family: Config.sysFont
                                    font.pixelSize: 10
                                    color: Config.textMuted
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                }
                            }

                            MouseArea {
                                id: cHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Config.workspaceContainerStyle = modelData.id
                            }
                        }
                    }
                }
            }
        }

        // ==========================================
        // 4. INTERACTIVITY & MOTION DYNAMICS
        // ==========================================
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: motionCol.implicitHeight + 28
            radius: Config.cornerRadius
            color: Qt.rgba(255, 255, 255, 0.05)
            border.width: 1
            border.color: Qt.rgba(255, 255, 255, 0.1)

            ColumnLayout {
                id: motionCol
                anchors.fill: parent
                anchors.margins: 14
                spacing: 14

                Text {
                    text: "INTERACTION & MOTION EFFECTS"
                    color: Config.textMuted
                    font.family: Config.sysFont
                    font.pixelSize: Config.size(Config.fontMicro)
                    font.bold: true
                }

                // TOGGLE 1: AMBIENT GLOW
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
                            text: "Ambient Indicator Glow"
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontBody)
                            font.bold: true
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Soft accent bloom surrounding active and hovered workspace pills"
                            color: Config.textMuted
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontCaption)
                            wrapMode: Text.WordWrap
                        }
                    }

                    ToggleSwitch {
                        checked: Config.workspaceGlow !== false

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Config.workspaceGlow = (Config.workspaceGlow === false)
                        }
                    }
                }

                // TOGGLE 2: MOUSE WHEEL SCROLL TO SWITCH
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
                            text: "Mouse Wheel Quick-Switch"
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontBody)
                            font.bold: true
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Scroll the mouse wheel over the workspace strip to cycle through desktops"
                            color: Config.textMuted
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontCaption)
                            wrapMode: Text.WordWrap
                        }
                    }

                    ToggleSwitch {
                        checked: Config.workspaceScroll !== false

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Config.workspaceScroll = (Config.workspaceScroll === false)
                        }
                    }
                }

                // TOGGLE 3: HOVER TOOLTIP
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
                            text: "Workspace Hover Tooltips"
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontBody)
                            font.bold: true
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Display floating badge with workspace name, window count, and active application on hover"
                            color: Config.textMuted
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontCaption)
                            wrapMode: Text.WordWrap
                        }
                    }

                    ToggleSwitch {
                        checked: Config.workspaceTooltips !== false

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Config.workspaceTooltips = (Config.workspaceTooltips === false)
                        }
                    }
                }
            }
        }

        // ==========================================
        // 5. ACTION BUTTONS & SCRATCHPADS
        // ==========================================
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: actionsCol.implicitHeight + 28
            radius: Config.cornerRadius
            color: Qt.rgba(255, 255, 255, 0.05)
            border.width: 1
            border.color: Qt.rgba(255, 255, 255, 0.1)

            ColumnLayout {
                id: actionsCol
                anchors.fill: parent
                anchors.margins: 14
                spacing: 14

                Text {
                    text: "ACTION BUTTONS & SPECIAL WORKSPACES"
                    color: Config.textMuted
                    font.family: Config.sysFont
                    font.pixelSize: Config.size(Config.fontMicro)
                    font.bold: true
                }

                // TOGGLE 1: ADD BUTTON (+)
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
                            text: "Show Add Workspace Button (+)"
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontBody)
                            font.bold: true
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Quickly spawn and focus the next available empty workspace"
                            color: Config.textMuted
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontCaption)
                            wrapMode: Text.WordWrap
                        }
                    }

                    ToggleSwitch {
                        checked: Config.workspaceShowAddBtn !== false

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Config.workspaceShowAddBtn = (Config.workspaceShowAddBtn === false)
                        }
                    }
                }

                // TOGGLE 2: OVERVIEW BUTTON
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
                            text: "Show Overview Button"
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontBody)
                            font.bold: true
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Directly trigger the full-screen spatial Workspace Overview popup"
                            color: Config.textMuted
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontCaption)
                            wrapMode: Text.WordWrap
                        }
                    }

                    ToggleSwitch {
                        checked: Config.workspaceShowOverviewBtn !== false

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Config.workspaceShowOverviewBtn = (Config.workspaceShowOverviewBtn === false)
                        }
                    }
                }

                // TOGGLE 3: SPECIAL SCRATCHPADS
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
                            text: "Show Special Workspaces (Scratchpads)"
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontBody)
                            font.bold: true
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Display dedicated shortcut tokens for magic, music, and private scratchpad workspaces when active or occupied"
                            color: Config.textMuted
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontCaption)
                            wrapMode: Text.WordWrap
                        }
                    }

                    ToggleSwitch {
                        checked: Config.workspaceShowSpecial !== false

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Config.workspaceShowSpecial = (Config.workspaceShowSpecial === false)
                        }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true; implicitHeight: 20 }
    }
}