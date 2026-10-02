import QtQuick
import QtQuick.Controls

Rectangle {
    id: sidebar

    color: Theme.sidebarBg
    implicitWidth: Theme.sidebarWidth

    property string selectedId: "general"
    property bool hasBattery: true
    property bool signedIn: false
    property string accountName: ""
    property alias searchText: searchInput.text

    signal select(string rowId)
    signal signIn

    readonly property var sections: [
        {
            name: "radio",
            items: [
                { id: "wifi", title: "Wi-Fi", icon: "sb_wifi" },
                { id: "bluetooth", title: "Bluetooth", icon: "sb_bluetooth" },
                { id: "network", title: "Network", icon: "sb_local-network" },
                { id: "battery", title: "Battery", icon: "sb_battery", needsBattery: true },
                { id: "energy", title: "Energy", icon: "sb_energy", noBattery: true }
            ]
        },
        {
            name: "main",
            items: [
                { id: "general", title: "General", icon: "sb_gear" },
                { id: "accessibility", title: "Accessibility", icon: "sb_accessibility" },
                { id: "appearance", title: "Appearance", icon: "sb_dark-mode" },
                { id: "menuBar", title: "Menu Bar", icon: "sb_controlcenter.settings" },
                { id: "siri", title: "Apple Intelligence & Siri", icon: "sb_apple-intelligence" },
                { id: "desktopDock", title: "Desktop & Dock", icon: "sb_desktop" },
                { id: "displays", title: "Displays", icon: "sb_display" },
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
                { id: "trackpad", title: "Trackpad", icon: "sb_trackpad" },
                { id: "printersScanners", title: "Printers & Scanners", icon: "sb_printer" }
            ]
        }
    ]

    function itemVisible(item) {
        if (item.needsBattery && !hasBattery)
            return false
        if (item.noBattery && hasBattery)
            return false
        return true
    }

    // Search field
    Rectangle {
        id: searchField
        anchors.top: parent.top
        anchors.topMargin: 25
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.rightMargin: 12
        height: 22
        radius: 6
        color: Theme.searchBg

        Canvas {
            id: magnifier
            width: 13
            height: 13
            anchors.left: parent.left
            anchors.leftMargin: 7
            anchors.verticalCenter: parent.verticalCenter

            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()
                ctx.strokeStyle = Theme.stroke
                ctx.lineWidth = 1.3
                ctx.beginPath()
                ctx.arc(5.2, 5.2, 3.7, 0, Math.PI * 2)
                ctx.stroke()
                ctx.beginPath()
                ctx.moveTo(8.0, 8.0)
                ctx.lineTo(11.4, 11.4)
                ctx.stroke()
            }

            Component.onCompleted: requestPaint()
        }

        TextInput {
            id: searchInput
            anchors.left: magnifier.right
            anchors.leftMargin: 5
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            clip: true
            font.family: Theme.fontText
            font.pixelSize: 13
            color: Theme.textPrimary

            Text {
                visible: !searchInput.text && !searchInput.activeFocus
                text: "Search"
                font.family: Theme.fontText
                font.pixelSize: 13
                color: Theme.placeholder
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    Flickable {
        id: flick
        anchors.top: searchField.bottom
        anchors.topMargin: 25
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        contentHeight: contentCol.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        ScrollBar.vertical: ScrollBar {}

        Column {
            id: contentCol
            width: flick.width

            AppleAccountCell {
                width: parent.width
                signedIn: sidebar.signedIn
                accountName: sidebar.accountName
                selected: sidebar.selectedId === "appleId"
                onClicked: sidebar.signIn()
            }

            Item {
                width: 1
                height: 22
            }

            Repeater {
                model: sidebar.sections

                delegate: Column {
                    id: sectionCol
                    required property var modelData
                    width: contentCol.width

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
                        height: 16
                    }
                }
            }
        }
    }
}
