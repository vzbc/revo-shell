import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.win

/**
 * Windows 11 style Settings Home page: account banner on top, then
 * quick status cards and a grid of colored category tiles.
 */
Flickable {
    id: root

    signal navigateRequested(string pageName)

    clip: true
    contentWidth: width
    contentHeight: column.implicitHeight + 40

    ScrollBar.vertical: StyledScrollBar { visible: root.contentHeight > root.height }

    ColumnLayout {
        id: column
        width: Math.max(620, root.width - 48)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 28
        spacing: 22

        // ----------------------------------------------------- quick status row
        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            QuickCard {
                Layout.fillWidth: true
                implicitHeight: 64
                iconText: networkIcon
                title: "Network"
                statusText: networkStatusText
                tileColor: "#0078d4"
                onClicked: root.navigateRequested("General")
            }

            QuickCard {
                Layout.fillWidth: true
                implicitHeight: 64
                iconText: "system_update"
                title: "System updates"
                statusText: updateStatusText
                tileColor: "#00809d"
                WinButton {
                    text: "Check"
                    accent: false
                    implicitHeight: 26
                    onClicked: Updates.refresh()
                }
            }
        }

        // --------------------------------------------------------- cards grid
        Flow {
            Layout.fillWidth: true
            spacing: 16

            HomeCard {
                width: parent.width >= 900 ? (parent.width - 16) / 2 : parent.width
                implicitHeight: 148
                tileColor: "#0078d4"
                iconText: "computer"
                title: "Device info"
                subtitle: "See your hardware specifications"

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    HomeSpecRow { iconText: "memory"; text: SystemDetails.ramTotal; valueText: "RAM" }
                    HomeSpecRow { iconText: "developer_board"; text: SystemDetails.cpuModel; valueText: "CPU" }
                    HomeSpecRow { iconText: "videogame_asset"; text: SystemDetails.gpuModel; valueText: "GPU" }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        StyledText {
                            text: "Storage"
                            color: WinTheme.textSecondary
                            font.pixelSize: 11
                        }
                        WinProgressBar {
                            Layout.fillWidth: true
                            value: SystemDetails.diskPercent / 100
                            barColor: SystemDetails.diskPercent > 85 ? WinTheme.danger : WinTheme.accent
                        }
                        StyledText {
                            text: `${SystemDetails.diskUsed} / ${SystemDetails.diskTotal}`
                            color: WinTheme.textSecondary
                            font.pixelSize: 11
                        }
                    }
                }

                onClicked: root.navigateRequested("About")
            }

            HomeCard {
                width: parent.width >= 900 ? (parent.width - 16) / 2 : parent.width
                implicitHeight: 148
                tileColor: "#8e6cf2"
                iconText: "palette"
                title: "Personalization"
                subtitle: "Background, colors and interface"

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        StyledText {
                            text: "Theme mode"
                            color: WinTheme.textSecondary
                            font.pixelSize: 12
                        }
                        Item { Layout.fillWidth: true }
                        StyledText {
                            text: "Dark"
                            color: WinTheme.text
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        StyledText {
                            text: "Wallpaper"
                            color: WinTheme.textSecondary
                            font.pixelSize: 12
                        }
                        Item { Layout.fillWidth: true }
                        StyledText {
                            text: "Custom"
                            color: WinTheme.text
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }
                    }
                }

                onClicked: root.navigateRequested("Background")
            }

            HomeCard {
                width: parent.width >= 900 ? (parent.width - 16) / 2 : parent.width
                implicitHeight: 148
                tileColor: "#00809d"
                iconText: "recommend"
                title: "Recommended settings"
                subtitle: "Suggested based on your setup"

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        StyledText {
                            text: "Transparency effects"
                            color: WinTheme.text
                            font.pixelSize: 12
                            Layout.fillWidth: true
                        }
                        WinSwitch {
                            checked: Config.options.appearance.transparency.enable
                            onToggled: v => { Config.options.appearance.transparency.enable = v }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        StyledText {
                            text: "Ambient wallpaper tint"
                            color: WinTheme.text
                            font.pixelSize: 12
                            Layout.fillWidth: true
                        }
                        WinSwitch {
                            checked: Config.options.appearance.extraBackgroundTint
                            onToggled: v => { Config.options.appearance.extraBackgroundTint = v }
                        }
                    }
                }

                onClicked: root.navigateRequested("General")
            }

            HomeCard {
                width: parent.width >= 900 ? (parent.width - 16) / 2 : parent.width
                implicitHeight: 148
                tileColor: "#0078d4"
                iconText: "bluetooth"
                title: "Bluetooth"
                subtitle: "Manage paired devices"

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        StyledText {
                            text: BluetoothStatus.enabled ? "Bluetooth is on" : "Bluetooth is off"
                            color: WinTheme.text
                            font.pixelSize: 12
                            Layout.fillWidth: true
                        }
                        WinSwitch {
                            checked: BluetoothStatus.enabled
                            onToggled: v => {
                                Quickshell.execDetached(["bash", "-c", `bluetoothctl power ${v ? "on" : "off"}`])
                            }
                        }
                    }
                    StyledText {
                        visible: BluetoothStatus.enabled
                        text: BluetoothStatus.activeDeviceCount > 0
                            ? `${BluetoothStatus.activeDeviceCount} connected device(s)`
                            : "No connected devices"
                        color: WinTheme.textSecondary
                        font.pixelSize: 11
                    }
                    StyledText {
                        visible: BluetoothStatus.enabled && BluetoothStatus.pairedButNotConnectedDevices.length > 0
                        text: `${BluetoothStatus.pairedButNotConnectedDevices.length} paired device(s) not connected`
                        color: WinTheme.textSecondary
                        font.pixelSize: 11
                    }
                }
            }
        }

        Item { Layout.preferredHeight: 10 }
    }

    readonly property string networkStatusText: {
        if (Network.ethernet)
            return `Ethernet — ${Network.networkName || "connected"}`
        if (Network.wifi && Network.wifiStatus === "connected")
            return `Connected — ${Network.networkName || (Network.active?.ssid ?? "Wi-Fi")}`
        if (Network.wifiStatus === "connecting")
            return "Connecting..."
        if (Network.wifiStatus === "disabled")
            return "Wi-Fi is off"
        return "Not connected"
    }
    readonly property string networkIcon: Network.ethernet ? "lan" : Network.wifi ? "wifi" : "wifi_off"

    readonly property string updateStatusText: {
        if (Updates.checking) return "Checking for updates..."
        if (!Updates.available) return "Update check unavailable"
        if (Updates.count > 0) return `${Updates.count} update(s) available`
        return "You're up to date"
    }

    component QuickCard: WinCard {
        property string iconText: ""
        property string title: ""
        property string statusText: ""
        property color tileColor: WinTheme.accent
        property bool hasTrailing: trailingSlot.children.length > 0
        default property alias trailingData: trailingSlot.data

        hoverable: true
        implicitHeight: 64

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 12

            Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                radius: 6
                color: tileColor
                MaterialSymbol {
                    anchors.centerIn: parent
                    text: iconText
                    iconSize: 20
                    color: "#ffffff"
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                StyledText {
                    text: title
                    color: WinTheme.text
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                }
                StyledText {
                    text: statusText
                    color: WinTheme.textSecondary
                    font.pixelSize: 11
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            Item {
                id: trailingSlot
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: trailingSlot.childrenRect.width
                implicitHeight: trailingSlot.childrenRect.height
            }

            MaterialSymbol {
                visible: !hasTrailing
                text: "chevron_right"
                iconSize: 18
                color: WinTheme.textTertiary
            }
        }
    }

    component HomeCard: WinCard {
        property string iconText: ""
        property string title: ""
        property string subtitle: ""
        property color tileColor: WinTheme.accent
        default property alias contentData: cardContent.data

        clickable: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Rectangle {
                    Layout.preferredWidth: 38
                    Layout.preferredHeight: 38
                    radius: 8
                    color: tileColor
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: iconText
                        iconSize: 22
                        color: "#ffffff"
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    StyledText {
                        text: title
                        color: WinTheme.text
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                    }
                    StyledText {
                        text: subtitle
                        color: WinTheme.textSecondary
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }
                }

                MaterialSymbol {
                    text: "chevron_right"
                    iconSize: 18
                    color: WinTheme.textTertiary
                }
            }

            ColumnLayout {
                id: cardContent
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 6
            }
        }
    }

    component HomeSpecRow: RowLayout {
        property string iconText: ""
        property string text: ""
        property string valueText: ""

        spacing: 10
        Layout.fillWidth: true

        MaterialSymbol {
            text: iconText
            iconSize: 16
            color: WinTheme.textSecondary
        }
        StyledText {
            Layout.fillWidth: true
            text: text
            elide: Text.ElideRight
            color: WinTheme.textSecondary
            font.pixelSize: 12
        }
        StyledText {
            text: valueText
            color: WinTheme.textSecondary
            font.pixelSize: 11
        }
    }
}
