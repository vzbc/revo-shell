import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import "Pages.js" as Pages
import "PagesContent.js" as Content

// Floating Liquid Glass sidebar (macOS 27). Order and grouping follow
// System Settings.app/Contents/Resources/Sidebar124.plist.
Item {
    id: sidebar

    property string selectedId: "general"
    property bool hasBattery: true
    property bool hasMouse: true
    property bool hasTrackpad: false
    property bool signedIn: false
    property string accountName: ""
    property alias searchText: searchInput.text

    signal select(string rowId)
    signal signIn
    signal dragWindow

    readonly property var sections: [
        {
            name: "radio",
            items: [
                { id: "wifi", title: "Wi‑Fi", icon: "sb_wifi" },
                { id: "bluetooth", title: "Bluetooth", icon: "sb_bluetooth" },
                { id: "network", title: "Network", icon: "sb_local-network" },
                { id: "battery", title: "Battery", icon: "sb_battery", needsBattery: true },
                { id: "energy", title: "Energy", icon: "sb_energy", noBattery: true }
            ]
        },
        {
            // "ordered_content": General, then "sortable_content" sorted by name
            name: "main",
            items: [
                { id: "general", title: "General", icon: "sb_gear" },
                { id: "accessibility", title: "Accessibility", icon: "sb_accessibility" },
                { id: "appearance", title: "Appearance", icon: "sb_dark-mode" },
                { id: "siri", title: "Apple Intelligence & Siri", icon: "sb_apple-intelligence" },
                { id: "desktopDock", title: "Desktop & Dock", icon: "sb_desktop" },
                { id: "displays", title: "Displays", icon: "sb_display" },
                { id: "menuBar", title: "Menu Bar", icon: "sb_controlcenter.settings" },
                { id: "spotlight", title: "Spotlight", icon: "sb_spotlight" },
                { id: "wallpaper", title: "Wallpaper", icon: "sb_wallpaper" }
            ]
        },
        {
            name: "focus",
            items: [
                { id: "notifications", title: "Notifications", icon: "sb_notifications" },
                { id: "sound", title: "Sound", icon: "sb_sound" },
                { id: "focus", title: "Focus", icon: "sb_focus" },
                { id: "screenTime", title: "Screen Time", icon: "sb_screen-time" }
            ]
        },
        {
            name: "auth",
            items: [
                { id: "lockScreen", title: "Lock Screen", icon: "sb_lockscreen" },
                { id: "privacySecurity", title: "Privacy & Security", icon: "sb_privacy" },
                { id: "touchIDPassword", title: "Touch ID & Password", icon: "sb_touch-id" },
                { id: "usersGroups", title: "Users & Groups", icon: "sb_group" }
            ]
        },
        {
            name: "service",
            items: [
                { id: "internetAccounts", title: "Internet Accounts", icon: "sb_accounts" },
                { id: "gameCenter", title: "Game Center", icon: "sb_gamecenter" },
                { id: "icloud", title: "iCloud", icon: "sb_icloud" },
                { id: "walletApplePay", title: "Wallet & Apple Pay", icon: "sb_wallet" }
            ]
        },
        {
            name: "input",
            items: [
                { id: "keyboard", title: "Keyboard", icon: "sb_keyboard" },
                { id: "mouse", title: "Mouse", icon: "sb_trackpad", needsMouse: true },
                { id: "trackpad", title: "Trackpad", icon: "sb_trackpad", needsTrackpad: true },
                { id: "printersScanners", title: "Printers & Scanners", icon: "sb_printer" }
            ]
        }
    ]

    // sub-page id prefix -> root pane, so searching "Storage" finds General
    readonly property var prefixRoot: ({
        "gen": "general", "acc": "accessibility", "privacy": "privacySecurity",
        "acct": "appleId", "wifi": "wifi", "sound": "sound", "users": "usersGroups"
    })

    readonly property string query: searchInput.text.trim().toLowerCase()

    function matchesQuery(item) {
        if (query.length === 0)
            return true
        if (item.title.toLowerCase().indexOf(query) >= 0)
            return true
        for (var k in Pages.info) {
            var dot = k.indexOf(".")
            if (dot < 0)
                continue
            if (prefixRoot[k.substring(0, dot)] !== item.id)
                continue
            var t = Pages.info[k].title
            if (t && t.toLowerCase().indexOf(query) >= 0)
                return true
        }
        return false
    }

    function itemVisible(item) {
        if (item.needsBattery && !hasBattery)
            return false
        if (item.noBattery && hasBattery)
            return false
        if (item.needsMouse && !hasMouse)
            return false
        if (item.needsTrackpad && !hasTrackpad)
            return false
        return matchesQuery(item)
    }

    // ---- glass body ------------------------------------------------------
    RectangularShadow {
        anchors.fill: glass
        radius: glass.radius
        blur: 18
        spread: 0
        offset.y: 2
        color: Theme.glassShadow
        visible: !Theme.reduceTransparency
    }

    Rectangle {
        id: glass
        anchors.fill: parent
        radius: Theme.sidebarRadius
        color: Theme.sidebarBg

        // specular rim: bright on top, fading toward the bottom
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            border.width: 1
            border.color: Theme.glassStrokeTop
            layer.enabled: true
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: rimMask
            }
        }
        Item {
            id: rimMask
            anchors.fill: parent
            visible: false
            layer.enabled: true
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 1) }
                    GradientStop { position: 0.35; color: Qt.rgba(1, 1, 1, 0.35) }
                    GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.15) }
                }
            }
        }
    }

    // window drag area behind the traffic lights
    MouseArea {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 40
        onPressed: sidebar.dragWindow()
    }

    // ---- search capsule --------------------------------------------------
    Rectangle {
        id: searchField
        anchors.top: parent.top
        anchors.topMargin: 42
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.right: parent.right
        anchors.rightMargin: 10
        height: 30
        radius: height / 2
        color: Theme.searchBg
        border.width: searchInput.activeFocus ? 2 : 1
        border.color: searchInput.activeFocus ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.55)
                                              : Theme.glassControlStroke

        Canvas {
            id: magnifier
            width: 14
            height: 14
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter

            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()
                ctx.strokeStyle = Theme.stroke
                ctx.lineWidth = 1.5
                ctx.lineCap = "round"
                ctx.beginPath()
                ctx.arc(5.6, 5.6, 4.2, 0, Math.PI * 2)
                ctx.stroke()
                ctx.beginPath()
                ctx.moveTo(8.8, 8.8)
                ctx.lineTo(12.4, 12.4)
                ctx.stroke()
            }

            Component.onCompleted: requestPaint()
            Connections { target: Theme; function onDarkChanged() { magnifier.requestPaint() } }
        }

        TextInput {
            id: searchInput
            anchors.left: magnifier.right
            anchors.leftMargin: 6
            anchors.right: clearBtn.left
            anchors.rightMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            clip: true
            font.family: Theme.fontText
            font.pixelSize: 13
            color: Theme.textPrimary
            selectionColor: Theme.link
            selectByMouse: true
            Keys.onEscapePressed: { text = ""; focus = false }
            Keys.onReturnPressed: {
                // jump to the first match, like macOS
                for (var s = 0; s < sidebar.sections.length; s++)
                    for (var i = 0; i < sidebar.sections[s].items.length; i++) {
                        var it = sidebar.sections[s].items[i]
                        if (sidebar.itemVisible(it)) { sidebar.select(it.id); return }
                    }
            }

            Text {
                visible: !searchInput.text
                text: "Search"
                font.family: Theme.fontText
                font.pixelSize: 13
                color: Theme.placeholder
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Rectangle {
            id: clearBtn
            visible: searchInput.text.length > 0
            width: visible ? 15 : 0
            height: 15
            radius: 7.5
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.textTertiary
            Text {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -0.5
                text: "×"
                font.pixelSize: 12
                font.bold: true
                color: Theme.dark ? "#1E1E1E" : "#FFFFFF"
            }
            MouseArea { anchors.fill: parent; onClicked: searchInput.text = "" }
        }
    }

    Flickable {
        id: flick
        anchors.top: searchField.bottom
        anchors.topMargin: 12
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 6
        contentHeight: contentCol.implicitHeight + 8
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded; width: 6 }

        Column {
            id: contentCol
            width: flick.width

            AppleAccountCell {
                width: parent.width
                visible: sidebar.query.length === 0 || "apple account sign in".indexOf(sidebar.query) >= 0
                signedIn: sidebar.signedIn
                accountName: sidebar.accountName
                selected: sidebar.selectedId === "appleId"
                onClicked: sidebar.signIn()
            }

            Item {
                width: 1
                height: 10
            }

            Repeater {
                model: sidebar.sections

                delegate: Column {
                    id: sectionCol
                    required property var modelData
                    width: contentCol.width

                    readonly property int shown: {
                        var n = 0
                        for (var i = 0; i < modelData.items.length; i++)
                            if (sidebar.itemVisible(modelData.items[i])) n++
                        return n
                    }
                    visible: shown > 0

                    Repeater {
                        model: modelData.items

                        delegate: SidebarRow {
                            required property var modelData
                            width: sectionCol.width
                            rowId: modelData.id
                            title: modelData.title
                            iconFile: modelData.icon
                            show: sidebar.itemVisible(modelData)
                            selected: modelData.id === sidebar.selectedId
                            onClicked: (id) => sidebar.select(id)
                        }
                    }

                    Item {
                        width: 1
                        height: 12
                    }
                }
            }

            Text {
                visible: sidebar.query.length > 0 && contentCol.childrenRect.height < 60
                x: 16
                text: "No Results"
                font.family: Theme.fontText
                font.pixelSize: 13
                color: Theme.textSecondary
            }
        }
    }
}
