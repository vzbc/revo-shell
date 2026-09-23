import QtQuick
import Qt5Compat.GraphicalEffects
import QtQuick.Layouts
import QtQuick.Controls
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "./settings"
import "./widgets"

Item {
    id: settingsRoot

    implicitWidth: 1000
    implicitHeight: 700
    clip: true

    readonly property real cardMargin: Config.cardMargin !== undefined ? Config.cardMargin : 12

    property int activeSection: Config.lastSettingsSection
    property bool isMaximized: false
    property bool visualsExpanded: false
    property bool connectivityExpanded: false
    property bool widgetsExpanded: false

    function expandActiveCategory(sectionId) {
        if ([0, 16, 1, 17, 2, 3, 12].includes(sectionId)) visualsExpanded = true
        else if ([4, 5, 6, 7].includes(sectionId)) connectivityExpanded = true
        else if ([8, 9, 10, 13, 14, 15, 18, 19, 20].includes(sectionId)) widgetsExpanded = true
    }

    function getSectionCategory(sectionId) {
        if ([0, 16, 1, 17, 2, 3, 12].includes(sectionId)) return "VISUALS"
        if ([4, 5, 6, 7].includes(sectionId)) return "CONNECTIVITY"
        if ([8, 9, 10, 13, 15, 18, 19, 20].includes(sectionId)) return "WIDGETS"
        if (sectionId === 11) return "SYSTEM"
        return "GENERAL"
    }

    function getSectionName(sectionId) {
        switch (sectionId) {
            case 0: return "Display"
            case 16: return "Bar"
            case 1: return "Appearance"
            case 17: return "Workspaces"
            case 2: return "Typography"
            case 3: return "Wallpaper"
            case 12: return "Icons"
            case 4: return "Network"
            case 5: return "Wi-Fi"
            case 6: return "Bluetooth"
            case 7: return "Weather"
            case 8: return "Mascot"
            case 9: return "Clock"
            case 19: return "System Info"
            case 10: return "Keyboard"
            case 13: return "System Sounds"
            case 15: return "Lockscreen"
            case 18: return "Screensaver"
            case 20: return "Retro Shader"
            case 11: return "Shell"
            default: return "Settings"
        }
    }

    function getSectionIcon(sectionId) {
        switch (sectionId) {
            case 0: return "aspect_ratio"
            case 16: return "dock"
            case 1: return "palette"
            case 17: return "view_carousel"
            case 2: return "match_case"
            case 3: return "wallpaper"
            case 12: return "account_circle"
            case 4: return "lan"
            case 5: return "wifi"
            case 6: return "bluetooth"
            case 7: return "thermostat"
            case 8: return "smart_toy"
            case 9: return "schedule"
            case 19: return "terminal"
            case 10: return "keyboard"
            case 13: return "volume_up"
            case 15: return "lock"
            case 18: return "tv"
            case 20: return "videogame_asset"
            case 11: return "terminal"
            default: return "settings"
        }
    }

    Component.onCompleted: {
        activeSection = Config.lastSettingsSection
        expandActiveCategory(activeSection)
    }

    Connections {
        target: Config
        function onLastSettingsSectionChanged() {
            if (settingsRoot.activeSection !== Config.lastSettingsSection) {
                settingsRoot.activeSection = Config.lastSettingsSection
                settingsRoot.expandActiveCategory(settingsRoot.activeSection)
            }
        }
    }

    onActiveSectionChanged: {
        if (Config.isLoaded && Config.lastSettingsSection !== activeSection) {
            Config.lastSettingsSection = activeSection
        }
        expandActiveCategory(activeSection)
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: settingsRoot.cardMargin
        spacing: settingsRoot.cardMargin / 2

        // ================= HEADER & BREADCRUMB =================
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            // Title & Glowing Badge
            RowLayout {
                spacing: 10
                Layout.alignment: Qt.AlignVCenter

                Rectangle {
                    implicitWidth: 32
                    implicitHeight: 32
                    radius: 8
                    color: Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.15)
                    border.width: 1
                    border.color: Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.3)

                    Text {
                        anchors.centerIn: parent
                        text: "settings"
                        color: Config.accent
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 18
                    }
                }

                Item {
                    implicitWidth: settingsTitleText.implicitWidth
                    implicitHeight: settingsTitleText.implicitHeight

                    Glow {
                        anchors.fill: settingsTitleText
                        source: settingsTitleText
                        radius: 8
                        samples: 16
                        color: Config.accent
                        spread: 0.2
                        transparentBorder: true
                        visible: Config.clockShowGlow
                    }

                    Text {
                        id: settingsTitleText
                        anchors.fill: parent
                        text: "SETTINGS"
                        color: Config.textMain
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontTitle)
                        font.bold: true
                        font.italic: true
                    }
                }
            }

            // Dynamic Breadcrumb Chip
            Rectangle {
                implicitHeight: 26
                implicitWidth: breadcrumbRow.implicitWidth + 16
                radius: 13
                color: Qt.rgba(255, 255, 255, 0.05)
                border.width: 1
                border.color: Qt.rgba(255, 255, 255, 0.08)
                Layout.alignment: Qt.AlignVCenter

                RowLayout {
                    id: breadcrumbRow
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: settingsRoot.getSectionCategory(settingsRoot.activeSection)
                        color: Config.textMuted
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontCaption)
                        font.bold: true
                    }

                    Text {
                        text: "chevron_right"
                        color: Config.textMuted
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 14
                    }

                    Text {
                        text: settingsRoot.getSectionName(settingsRoot.activeSection)
                        color: Config.accent
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontCaption)
                        font.bold: true
                    }
                }
            }

            Item { Layout.fillWidth: true }

            // Close Button
            Rectangle {
                implicitWidth: 32
                implicitHeight: 32
                radius: 16
                color: closeHover.hovered ? Qt.rgba(255, 255, 255, 0.12) : Qt.rgba(255, 255, 255, 0.04)
                border.width: 1
                border.color: closeHover.hovered ? Qt.rgba(255, 255, 255, 0.2) : Qt.rgba(255, 255, 255, 0.06)

                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: "close"
                    color: closeHover.hovered ? Config.textMain : Config.textMuted
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 18
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Config.showSettings = false
                        if (mascotSettingsLoader.item) mascotSettingsLoader.item.showBrowser = false
                    }
                }
                HoverHandler { id: closeHover }
            }
        }

        // ================= TWO-COLUMN MASTER / DETAIL =================
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: settingsRoot.cardMargin / 2

            // ================= LEFT SIDEBAR =================
            Rectangle {
                Layout.preferredWidth: 260
                Layout.maximumWidth: 260
                Layout.fillHeight: true
                color: Qt.rgba(255, 255, 255, 0.03)
                radius: (Config.surfaceRadius || 18) * 0.75
                border.width: 1
                border.color: Qt.rgba(255, 255, 255, 0.06)
                clip: true

                Flickable {
                    id: navFlickable
                    anchors.fill: parent
                    anchors.margins: 10
                    contentHeight: leftNavColumn.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    ScrollBar.vertical: ScrollBar {
                        id: navScrollBar
                        parent: navFlickable.parent
                        anchors.top: parent.top
                        anchors.topMargin: 6
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 6
                        anchors.right: parent.right
                        anchors.rightMargin: 4
                        width: 4
                        policy: ScrollBar.AsNeeded
                        
                        contentItem: Rectangle {
                            implicitWidth: 4
                            radius: 2
                            color: navScrollBar.pressed ? Config.accent : Qt.rgba(255, 255, 255, 0.2)
                        }
                    }

                    ColumnLayout {
                        id: leftNavColumn
                        width: parent.width - 8
                        spacing: 8

                        // ---------------- CATEGORY 1: VISUALS ----------------
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 34
                            radius: 8
                            color: visualsCatHover.hovered ? Qt.rgba(255, 255, 255, 0.06) : "transparent"

                            Behavior on color { ColorAnimation { duration: 150 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 8

                                Text {
                                    text: "palette"
                                    color: settingsRoot.visualsExpanded ? Config.accent : Config.textMuted
                                    font.family: "Material Symbols Outlined"
                                    font.pixelSize: 16
                                }

                                Text {
                                    text: "VISUALS"
                                    color: settingsRoot.visualsExpanded ? Config.textMain : Config.textMuted
                                    font.family: Config.sysFont
                                    font.pixelSize: Config.size(Config.fontCaption)
                                    font.bold: true
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: settingsRoot.visualsExpanded ? "expand_more" : "chevron_right"
                                    color: Config.textMuted
                                    font.family: "Material Symbols Outlined"
                                    font.pixelSize: 18
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: settingsRoot.visualsExpanded = !settingsRoot.visualsExpanded
                            }
                            HoverHandler { id: visualsCatHover }
                        }

                        ColumnLayout {
                            visible: settingsRoot.visualsExpanded
                            Layout.fillWidth: true
                            Layout.leftMargin: 4
                            spacing: 3

                            Repeater {
                                model: [
                                    { id: 0,  name: "Display",    icon: "aspect_ratio" },
                                    { id: 16, name: "Bar",        icon: "sliders" },
                                    { id: 1,  name: "Appearance", icon: "palette" },
                                    { id: 17, name: "Workspaces", icon: "view_carousel" },
                                    { id: 2,  name: "Typography", icon: "match_case" },
                                    { id: 3,  name: "Wallpaper",  icon: "wallpaper" },
                                    { id: 12, name: "Icons",      icon: "account_circle" }
                                ]

                                delegate: Rectangle {
                                    id: navDelegate1
                                    Layout.fillWidth: true
                                    implicitHeight: 36
                                    radius: 8
                                    readonly property bool isSelected: settingsRoot.activeSection === modelData.id
                                    color: navDelegate1.isSelected ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.14) : (navHover1.hovered ? Qt.rgba(255, 255, 255, 0.05) : "transparent")
                                    border.width: navDelegate1.isSelected ? 1 : 0
                                    border.color: navDelegate1.isSelected ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.25) : "transparent"

                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    Behavior on border.color { ColorAnimation { duration: 150 } }

                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 2
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 3
                                        height: 18
                                        radius: 1.5
                                        color: Config.accent
                                        visible: navDelegate1.isSelected
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 8
                                        spacing: 8

                                        Rectangle {
                                            implicitWidth: 24
                                            implicitHeight: 24
                                            radius: 6
                                            color: navDelegate1.isSelected ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.2) : (navHover1.hovered ? Qt.rgba(255, 255, 255, 0.06) : "transparent")

                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData.icon
                                                color: navDelegate1.isSelected ? Config.accent : Config.textMuted
                                                font.family: "Material Symbols Outlined"
                                                font.pixelSize: 15
                                            }
                                        }

                                        Text {
                                            text: modelData.name
                                            color: navDelegate1.isSelected ? Config.accent : Config.textMain
                                            font.family: Config.sysFont
                                            font.pixelSize: Config.size(Config.fontCaption)
                                            font.bold: navDelegate1.isSelected
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: settingsRoot.activeSection = modelData.id
                                    }
                                    HoverHandler { id: navHover1 }
                                }
                            }
                        }

                        // ---------------- CATEGORY 2: CONNECTIVITY ----------------
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 34
                            radius: 8
                            color: connCatHover.hovered ? Qt.rgba(255, 255, 255, 0.06) : "transparent"

                            Behavior on color { ColorAnimation { duration: 150 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 8

                                Text {
                                    text: "wifi_tethering"
                                    color: settingsRoot.connectivityExpanded ? Config.accent : Config.textMuted
                                    font.family: "Material Symbols Outlined"
                                    font.pixelSize: 16
                                }

                                Text {
                                    text: "CONNECTIVITY"
                                    color: settingsRoot.connectivityExpanded ? Config.textMain : Config.textMuted
                                    font.family: Config.sysFont
                                    font.pixelSize: Config.size(Config.fontCaption)
                                    font.bold: true
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: settingsRoot.connectivityExpanded ? "expand_more" : "chevron_right"
                                    color: Config.textMuted
                                    font.family: "Material Symbols Outlined"
                                    font.pixelSize: 18
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: settingsRoot.connectivityExpanded = !settingsRoot.connectivityExpanded
                            }
                            HoverHandler { id: connCatHover }
                        }

                        ColumnLayout {
                            visible: settingsRoot.connectivityExpanded
                            Layout.fillWidth: true
                            Layout.leftMargin: 4
                            spacing: 3

                            Repeater {
                                model: [
                                    { id: 4, name: "Network",   icon: "lan" },
                                    { id: 5, name: "Wi-Fi",     icon: "wifi" },
                                    { id: 6, name: "Bluetooth", icon: "bluetooth" },
                                    { id: 7, name: "Weather",   icon: "thermostat" }
                                ]

                                delegate: Rectangle {
                                    id: navDelegate2
                                    Layout.fillWidth: true
                                    implicitHeight: 36
                                    radius: 8
                                    readonly property bool isSelected: settingsRoot.activeSection === modelData.id
                                    color: navDelegate2.isSelected ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.14) : (navHover2.hovered ? Qt.rgba(255, 255, 255, 0.05) : "transparent")
                                    border.width: navDelegate2.isSelected ? 1 : 0
                                    border.color: navDelegate2.isSelected ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.25) : "transparent"

                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    Behavior on border.color { ColorAnimation { duration: 150 } }

                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 2
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 3
                                        height: 18
                                        radius: 1.5
                                        color: Config.accent
                                        visible: navDelegate2.isSelected
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 8
                                        spacing: 8

                                        Rectangle {
                                            implicitWidth: 24
                                            implicitHeight: 24
                                            radius: 6
                                            color: navDelegate2.isSelected ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.2) : (navHover2.hovered ? Qt.rgba(255, 255, 255, 0.06) : "transparent")

                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData.icon
                                                color: navDelegate2.isSelected ? Config.accent : Config.textMuted
                                                font.family: "Material Symbols Outlined"
                                                font.pixelSize: 15
                                            }
                                        }

                                        Text {
                                            text: modelData.name
                                            color: navDelegate2.isSelected ? Config.accent : Config.textMain
                                            font.family: Config.sysFont
                                            font.pixelSize: Config.size(Config.fontCaption)
                                            font.bold: navDelegate2.isSelected
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: settingsRoot.activeSection = modelData.id
                                    }
                                    HoverHandler { id: navHover2 }
                                }
                            }
                        }

                        // ---------------- CATEGORY 3: WIDGETS ----------------
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 34
                            radius: 8
                            color: widgetsCatHover.hovered ? Qt.rgba(255, 255, 255, 0.06) : "transparent"

                            Behavior on color { ColorAnimation { duration: 150 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 8

                                Text {
                                    text: "widgets"
                                    color: settingsRoot.widgetsExpanded ? Config.accent : Config.textMuted
                                    font.family: "Material Symbols Outlined"
                                    font.pixelSize: 16
                                }

                                Text {
                                    text: "WIDGETS"
                                    color: settingsRoot.widgetsExpanded ? Config.textMain : Config.textMuted
                                    font.family: Config.sysFont
                                    font.pixelSize: Config.size(Config.fontCaption)
                                    font.bold: true
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: settingsRoot.widgetsExpanded ? "expand_more" : "chevron_right"
                                    color: Config.textMuted
                                    font.family: "Material Symbols Outlined"
                                    font.pixelSize: 18
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: settingsRoot.widgetsExpanded = !settingsRoot.widgetsExpanded
                            }
                            HoverHandler { id: widgetsCatHover }
                        }

                        ColumnLayout {
                            visible: settingsRoot.widgetsExpanded
                            Layout.fillWidth: true
                            Layout.leftMargin: 4
                            spacing: 3

                            Repeater {
                                model: [
                                    { id: 8,  name: "Mascot",       icon: "smart_toy" },
                                    { id: 9,  name: "Clock",        icon: "schedule" },
                                    { id: 19, name: "System Info",  icon: "terminal" },
                                    { id: 10, name: "Keyboard",     icon: "keyboard" },
                                    { id: 13, name: "Sounds",       icon: "volume_up" },
                                    { id: 15, name: "Lockscreen",   icon: "lock" },
                                    { id: 18, name: "Screensaver",  icon: "tv" },
                                    { id: 20, name: "Retro Shader", icon: "videogame_asset" }
                                ]

                                delegate: Rectangle {
                                    id: navDelegate3
                                    Layout.fillWidth: true
                                    implicitHeight: 36
                                    radius: 8
                                    readonly property bool isSelected: settingsRoot.activeSection === modelData.id
                                    color: navDelegate3.isSelected ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.14) : (navHover3.hovered ? Qt.rgba(255, 255, 255, 0.05) : "transparent")
                                    border.width: navDelegate3.isSelected ? 1 : 0
                                    border.color: navDelegate3.isSelected ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.25) : "transparent"

                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    Behavior on border.color { ColorAnimation { duration: 150 } }

                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 2
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 3
                                        height: 18
                                        radius: 1.5
                                        color: Config.accent
                                        visible: navDelegate3.isSelected
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 8
                                        spacing: 8

                                        Rectangle {
                                            implicitWidth: 24
                                            implicitHeight: 24
                                            radius: 6
                                            color: navDelegate3.isSelected ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.2) : (navHover3.hovered ? Qt.rgba(255, 255, 255, 0.06) : "transparent")

                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData.icon
                                                color: navDelegate3.isSelected ? Config.accent : Config.textMuted
                                                font.family: "Material Symbols Outlined"
                                                font.pixelSize: 15
                                            }
                                        }

                                        Text {
                                            text: modelData.name
                                            color: navDelegate3.isSelected ? Config.accent : Config.textMain
                                            font.family: Config.sysFont
                                            font.pixelSize: Config.size(Config.fontCaption)
                                            font.bold: navDelegate3.isSelected
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: settingsRoot.activeSection = modelData.id
                                    }
                                    HoverHandler { id: navHover3 }
                                }
                            }
                        }

                        // Divider before Shell
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 1
                            color: Qt.rgba(255, 255, 255, 0.06)
                            Layout.topMargin: 4
                            Layout.bottomMargin: 4
                        }

                        // ---------------- CATEGORY 4: SHELL & SYSTEM ----------------
                        Rectangle {
                            id: shellBtn
                            Layout.fillWidth: true
                            implicitHeight: 36
                            radius: 8
                            readonly property bool isSelected: settingsRoot.activeSection === 11
                            color: shellBtn.isSelected ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.14) : (shellNavHover.hovered ? Qt.rgba(255, 255, 255, 0.05) : "transparent")
                            border.width: shellBtn.isSelected ? 1 : 0
                            border.color: shellBtn.isSelected ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.25) : "transparent"

                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            Rectangle {
                                anchors.left: parent.left
                                anchors.leftMargin: 2
                                anchors.verticalCenter: parent.verticalCenter
                                width: 3
                                height: 18
                                radius: 1.5
                                color: Config.accent
                                visible: shellBtn.isSelected
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 8
                                spacing: 8

                                Rectangle {
                                    implicitWidth: 24
                                    implicitHeight: 24
                                    radius: 6
                                    color: shellBtn.isSelected ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.2) : (shellNavHover.hovered ? Qt.rgba(255, 255, 255, 0.06) : "transparent")

                                    Text {
                                        anchors.centerIn: parent
                                        text: "terminal"
                                        color: shellBtn.isSelected ? Config.accent : Config.textMuted
                                        font.family: "Material Symbols Outlined"
                                        font.pixelSize: 15
                                    }
                                }

                                Text {
                                    text: "Shell & System"
                                    color: shellBtn.isSelected ? Config.accent : Config.textMain
                                    font.family: Config.sysFont
                                    font.pixelSize: Config.size(Config.fontCaption)
                                    font.bold: shellBtn.isSelected
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: settingsRoot.activeSection = 11
                            }
                            HoverHandler { id: shellNavHover }
                        }
                    }
                }
            }

            // ================= RIGHT CONTENT CONTAINER =================
            Rectangle {
                id: rightPaneRoot
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Qt.rgba(255, 255, 255, 0.03)
                radius: (Config.surfaceRadius || 18) * 0.75
                border.width: 1
                border.color: Qt.rgba(255, 255, 255, 0.06)
                clip: true

                property var currentFlickable: null
                readonly property bool canScrollDown: currentFlickable && (currentFlickable.contentHeight > (currentFlickable.height + 24)) && !currentFlickable.atYEnd && (currentFlickable.contentY < (currentFlickable.contentHeight - currentFlickable.height - 16))

                function findFlickable(item) {
                    if (!item) return null
                    if (item.contentHeight !== undefined && item.contentY !== undefined && item.height !== undefined) {
                        return item
                    }
                    if (item.children) {
                        for (let i = 0; i < item.children.length; i++) {
                            let child = item.children[i]
                            if (child && child.contentHeight !== undefined && child.contentY !== undefined && child.height !== undefined) {
                                return child
                            }
                        }
                    }
                    return null
                }

                function refreshActiveFlickable() {
                    for (let i = 0; i < contentPane.children.length; i++) {
                        let ch = contentPane.children[i]
                        if (ch && ch.active && ch.item) {
                            let f = findFlickable(ch.item)
                            if (f) {
                                currentFlickable = f
                                return
                            }
                        }
                    }
                    currentFlickable = null
                }

                Timer {
                    id: flickableSyncTimer
                    interval: 120
                    running: true
                    repeat: true
                    onTriggered: rightPaneRoot.refreshActiveFlickable()
                }

                Watermark {
                    icon: Config.getIcon("settings")
                    iconSize: 180
                    baseRotation: 12
                    seed: 16
                }

                Item {
                    id: contentPane
                    anchors.fill: parent
                    anchors.margins: settingsRoot.cardMargin

                    Loader { anchors.fill: parent; active: settingsRoot.activeSection === 0; visible: active; sourceComponent: DisplaySettings {} }
                    Loader { anchors.fill: parent; active: settingsRoot.activeSection === 16; visible: active; sourceComponent: BarSettings {} }
                    Loader { anchors.fill: parent; active: settingsRoot.activeSection === 1; visible: active; sourceComponent: AppearanceSettings {} }
                    Loader { anchors.fill: parent; active: settingsRoot.activeSection === 17; visible: active; sourceComponent: WorkspaceSettings {} }
                    Loader { anchors.fill: parent; active: settingsRoot.activeSection === 2; visible: active; sourceComponent: TypographySettings {} }
                    Loader { anchors.fill: parent; active: settingsRoot.activeSection === 3; visible: active; sourceComponent: WallpaperSettings {} }
                    Loader { anchors.fill: parent; active: settingsRoot.activeSection === 4; visible: active; sourceComponent: NetworkSettings {} }
                    Loader { anchors.fill: parent; active: settingsRoot.activeSection === 5; visible: active; sourceComponent: WifiSettings {} }
                    Loader { anchors.fill: parent; active: settingsRoot.activeSection === 6; visible: active; sourceComponent: BluetoothSettings {} }
                    Loader { anchors.fill: parent; active: settingsRoot.activeSection === 7; visible: active; sourceComponent: WeatherSettings {} }

                    Loader { id: mascotSettingsLoader; anchors.fill: parent; active: settingsRoot.activeSection === 8; visible: active; sourceComponent: MascotSettings {} }
                    Loader { anchors.fill: parent; active: settingsRoot.activeSection === 9; visible: active; sourceComponent: ClockSettings {} }
                    Loader { anchors.fill: parent; active: settingsRoot.activeSection === 19; visible: active; sourceComponent: SysInfoSettings {} }
                    Loader { anchors.fill: parent; active: settingsRoot.activeSection === 10; visible: active; sourceComponent: KeyboardSettings {} }
                    Loader { anchors.fill: parent; active: settingsRoot.activeSection === 20; visible: active; sourceComponent: ShaderSettings {} }

                    // Shell View (Section 11)
                    Loader {
                        anchors.fill: parent
                        active: settingsRoot.activeSection === 11
                        visible: active
                        sourceComponent: Item {
                            id: shellView
                            anchors.fill: parent

                            property string statusText: "Ready"
                            property bool isBusy: false

                            readonly property string repoDir: Qt.resolvedUrl(".").toString().replace(/^file:\/\//, "")

                            Process {
                                id: gitChecker
                                running: false

                                stdout: StdioCollector { id: checkOutput }
                                stderr: StdioCollector { id: checkError }

                                onExited: (code) => {
                                    if (code === 0) {
                                        let output = checkOutput.text
                                        if (output.includes("behind")) {
                                            shellView.statusText = "Updates available! Downloading..."
                                            gitPuller.command = ["fish", "-c", "cd '" + shellView.repoDir + "'; and git fetch origin main; and git reset --hard origin/main"]
                                            gitPuller.running = true
                                        } else {
                                            shellView.isBusy = false
                                            shellView.statusText = "Your shell is fully up to date."
                                        }
                                    } else {
                                        shellView.isBusy = false
                                        let err = checkError.text.trim()
                                        shellView.statusText = err.length > 0 ? err : "Error checking upstream repository."
                                    }
                                }
                            }

                            Process {
                                id: gitPuller
                                running: false

                                stderr: StdioCollector { id: pullError }

                                onExited: (code) => {
                                    shellView.isBusy = false
                                    if (code === 0) {
                                        shellView.statusText = "Updated successfully! Reloading..."
                                        Quickshell.execDetached(["fish", "-c", "killall quickshell; and quickshell"])
                                    } else {
                                        let err = pullError.text.trim()
                                        shellView.statusText = err.length > 0 ? err : "Failed to apply updates."
                                    }
                                }
                            }

                            ColumnLayout {
                                anchors.fill: parent
                                spacing: settingsRoot.cardMargin

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 12

                                    Rectangle {
                                        implicitWidth: 44
                                        implicitHeight: 44
                                        radius: 10
                                        color: Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.15)
                                        border.width: 1
                                        border.color: Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.3)

                                        Text {
                                            anchors.centerIn: parent
                                            text: "terminal"
                                            color: Config.accent
                                            font.family: "Material Symbols Outlined"
                                            font.pixelSize: 24
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        Text {
                                            text: "SYNOPTIK SHELL"
                                            color: Config.textMain
                                            font.family: Config.sysFont
                                            font.pixelSize: Config.size(Config.fontSubhead)
                                            font.bold: true
                                        }

                                        Text {
                                            text: "Modular, hardware-accelerated desktop shell for Hyprland"
                                            color: Config.textMuted
                                            font.family: Config.sysFont
                                            font.pixelSize: Config.size(Config.fontCaption)
                                        }
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    implicitHeight: 60
                                    radius: Config.cornerRadius / 2
                                    color: Qt.rgba(255, 255, 255, 0.04)
                                    border.width: 1
                                    border.color: gitHubHover.hovered ? Config.accent : Qt.rgba(255, 255, 255, 0.08)

                                    Behavior on border.color { ColorAnimation { duration: 150 } }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 14
                                        anchors.rightMargin: 14
                                        spacing: 12

                                        Rectangle {
                                            implicitWidth: 32
                                            implicitHeight: 32
                                            radius: 8
                                            color: Qt.rgba(255, 255, 255, 0.06)

                                            Text {
                                                anchors.centerIn: parent
                                                text: "code"
                                                color: Config.accent
                                                font.family: "Material Symbols Outlined"
                                                font.pixelSize: 18
                                            }
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 1

                                            Text {
                                                text: "GitHub Repository"
                                                color: Config.textMain
                                                font.family: Config.sysFont
                                                font.pixelSize: Config.size(Config.fontBody)
                                                font.bold: true
                                            }

                                            Text {
                                                text: "github.com/natepayn3/Synoptik"
                                                color: Config.textMuted
                                                font.family: Config.sysFont
                                                font.pixelSize: Config.size(Config.fontCaption)
                                            }
                                        }

                                        Text {
                                            text: "open_in_new"
                                            color: gitHubHover.hovered ? Config.accent : Config.textMuted
                                            font.family: "Material Symbols Outlined"
                                            font.pixelSize: 18
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Quickshell.execDetached(["xdg-open", "https://github.com/natepayn3/Synoptik"])
                                    }
                                    HoverHandler { id: gitHubHover }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    implicitHeight: Math.max(68, statusRow.implicitHeight + 20)
                                    radius: Config.cornerRadius / 2
                                    color: Qt.rgba(255, 255, 255, 0.04)
                                    border.width: 1
                                    border.color: Qt.rgba(255, 255, 255, 0.08)

                                    RowLayout {
                                        id: statusRow
                                        anchors.fill: parent
                                        anchors.leftMargin: 14
                                        anchors.rightMargin: 14
                                        anchors.topMargin: 10
                                        anchors.bottomMargin: 10
                                        spacing: 12

                                        Rectangle {
                                            implicitWidth: 32
                                            implicitHeight: 32
                                            radius: 8
                                            color: Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.15)

                                            Text {
                                                anchors.centerIn: parent
                                                text: shellView.isBusy ? "sync" : "system_update"
                                                color: Config.accent
                                                font.family: "Material Symbols Outlined"
                                                font.pixelSize: 18

                                                RotationAnimation on rotation {
                                                    running: shellView.isBusy
                                                    from: 0
                                                    to: 360
                                                    duration: 1000
                                                    loops: Animation.Infinite
                                                }
                                            }
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 2

                                            Text {
                                                text: shellView.isBusy ? "Checking Upstream..." : "Repository Status"
                                                color: Config.textMain
                                                font.family: Config.sysFont
                                                font.pixelSize: Config.size(Config.fontBody)
                                                font.bold: true
                                            }

                                            Text {
                                                text: shellView.statusText
                                                color: Config.textMuted
                                                font.family: Config.sysFont
                                                font.pixelSize: Config.size(Config.fontCaption)
                                                Layout.fillWidth: true
                                                wrapMode: Text.WrapAnywhere
                                            }
                                        }

                                        RowLayout {
                                            spacing: 8
                                            Layout.alignment: Qt.AlignVCenter

                                            Rectangle {
                                                implicitWidth: 110
                                                implicitHeight: 32
                                                radius: Config.cornerRadius / 2
                                                color: reloadBtnHover.hovered ? Qt.rgba(255, 255, 255, 0.12) : Qt.rgba(255, 255, 255, 0.05)
                                                border.color: Qt.rgba(255, 255, 255, 0.15)
                                                border.width: 1

                                                Behavior on color { ColorAnimation { duration: 150 } }

                                                RowLayout {
                                                    anchors.centerIn: parent
                                                    spacing: 4
                                                    Text { text: "restart_alt"; color: Config.textMain; font.family: "Material Symbols Outlined"; font.pixelSize: 14 }
                                                    Text { text: "Reload"; color: Config.textMain; font.family: Config.sysFont; font.pixelSize: Config.size(Config.fontCaption); font.bold: true }
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    enabled: !shellView.isBusy
                                                    onClicked: Quickshell.execDetached(["fish", "-c", "killall qs; and qs -c Synoptik & disown"])
                                                }
                                                HoverHandler { id: reloadBtnHover }
                                            }

                                            Rectangle {
                                                implicitWidth: 120
                                                implicitHeight: 32
                                                radius: Config.cornerRadius / 2
                                                color: updateBtnHover.hovered ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.3) : Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.18)
                                                border.color: Config.accent
                                                border.width: 1

                                                Behavior on color { ColorAnimation { duration: 150 } }

                                                RowLayout {
                                                    anchors.centerIn: parent
                                                    spacing: 4
                                                    Text { text: "sync"; color: Config.accent; font.family: "Material Symbols Outlined"; font.pixelSize: 14 }
                                                    Text { text: shellView.isBusy ? "Updating..." : "Check Updates"; color: Config.accent; font.family: Config.sysFont; font.pixelSize: Config.size(Config.fontCaption); font.bold: true }
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    enabled: !shellView.isBusy
                                                    onClicked: {
                                                        shellView.isBusy = true
                                                        shellView.statusText = "Checking for updates..."
                                                        gitChecker.command = ["fish", "-c", "cd '" + shellView.repoDir + "'; and git remote update; and git status -uno"]
                                                        gitChecker.running = true
                                                    }
                                                }
                                                HoverHandler { id: updateBtnHover }
                                            }
                                        }
                                    }
                                }

                                Item { Layout.fillHeight: true }
                            }
                        }
                    }

                    Loader { anchors.fill: parent; active: settingsRoot.activeSection === 12; visible: active; sourceComponent: IconSettings {} }
                    Loader { anchors.fill: parent; active: settingsRoot.activeSection === 13; visible: active; sourceComponent: SystemSounds {} }
                    Loader { anchors.fill: parent; active: settingsRoot.activeSection === 15; visible: active; sourceComponent: LockscreenSettings {} }
                    Loader { anchors.fill: parent; active: settingsRoot.activeSection === 18; visible: active; sourceComponent: ScreensaverSettings {} }
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 64
                    radius: parent.radius
                    visible: opacity > 0
                    opacity: rightPaneRoot.canScrollDown ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 220 } }
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 0.65; color: Qt.rgba(Config.bgPanel.r, Config.bgPanel.g, Config.bgPanel.b, 0.85) }
                        GradientStop { position: 1.0; color: Qt.rgba(Config.bgPanel.r, Config.bgPanel.g, Config.bgPanel.b, 0.98) }
                    }
                }

                Rectangle {
                    id: scrollCuePill
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 14
                    z: 100
                    implicitWidth: scrollCueRow.implicitWidth + 24
                    implicitHeight: 32
                    radius: 16
                    visible: opacity > 0
                    opacity: rightPaneRoot.canScrollDown ? (scrollCueMouse.containsMouse ? 1.0 : 0.92) : 0.0
                    color: scrollCueMouse.containsMouse ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.25) : Qt.rgba(Config.bgBase.r, Config.bgBase.g, Config.bgBase.b, 0.92)
                    border.width: 1.5
                    border.color: scrollCueMouse.containsMouse ? Config.accent : Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.45)

                    Behavior on opacity { NumberAnimation { duration: 220 } }
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    SequentialAnimation on anchors.bottomMargin {
                        running: rightPaneRoot.canScrollDown
                        loops: Animation.Infinite
                        NumberAnimation { from: 14; to: 18; duration: 700; easing.type: Easing.InOutSine }
                        NumberAnimation { from: 18; to: 14; duration: 700; easing.type: Easing.InOutSine }
                    }

                    RowLayout {
                        id: scrollCueRow
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: "keyboard_double_arrow_down"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 17
                            color: Config.accent
                            verticalAlignment: Text.AlignVCenter
                        }

                        Text {
                            text: "More"
                            font.family: Config.sysFont
                            font.pixelSize: 11
                            font.bold: true
                            font.letterSpacing: 0.5
                            color: Config.textMain
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    MouseArea {
                        id: scrollCueMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (rightPaneRoot.currentFlickable) {
                                let f = rightPaneRoot.currentFlickable
                                let targetY = Math.min(f.contentHeight - f.height, f.contentY + f.height * 0.75)
                                scrollAnim.target = f
                                scrollAnim.to = targetY
                                scrollAnim.restart()
                            }
                        }
                    }
                }

                NumberAnimation {
                    id: scrollAnim
                    property: "contentY"
                    duration: 320
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
}