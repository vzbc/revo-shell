import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import ".."

Item {
    id: root

    property bool hasPolledOnce: false
    property bool hasAdapter: true
    property bool wifiPowered: true
    property bool wifiScanning: false
    property string activeSsid: ""
    property string expandedSsid: ""
    property string connectingSsid: ""
    property string disconnectingSsid: ""
    property string errorSsid: ""
    property string connectionError: ""
    property var savedSsids: ([])

    readonly property real cardMargin: Config.cardMargin !== undefined ? Config.cardMargin : 12

    ListModel { id: wifiModel }

    Component.onCompleted: {
        fetchWifiStatusProc.running = false
        fetchWifiStatusProc.running = true
    }

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: parent.width
            spacing: root.cardMargin

            // ==========================================
            // HEADER & DESCRIPTION
            // ==========================================
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    text: "WI-FI CONFIGURATION"
                    color: Config.textMain
                    font.family: Config.sysFont
                    font.pixelSize: Config.size(Config.fontSubhead)
                    font.bold: true
                }

                Text {
                    text: "Manage wireless radio interfaces, scan nearby access points, authenticate with secured networks, and configure saved profiles."
                    color: Config.textMuted
                    font.family: Config.sysFont
                    font.pixelSize: Config.size(Config.fontCaption)
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }
            }

            // ==========================================
            // 1. HERO INTERFACE & STATUS CARD
            // ==========================================
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: heroRow.implicitHeight + 28
                radius: Config.cornerRadius
                color: Qt.rgba(255, 255, 255, 0.05)
                border.width: 2
                border.color: Qt.rgba(255, 255, 255, 0.1)

                RowLayout {
                    id: heroRow
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 14

                    // Hero Status Icon Badge
                    Rectangle {
                        implicitWidth: 44
                        implicitHeight: 44
                        radius: 22
                        Layout.alignment: Qt.AlignVCenter
                        color: (root.wifiPowered && root.hasAdapter)
                            ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.2)
                            : Qt.rgba(255, 255, 255, 0.06)
                        border.width: 2
                        border.color: (root.wifiPowered && root.hasAdapter) ? Config.accent : Qt.rgba(255, 255, 255, 0.15)

                        Behavior on color { ColorAnimation { duration: 200 } }
                        Behavior on border.color { ColorAnimation { duration: 200 } }

                        Text {
                            anchors.centerIn: parent
                            text: !root.hasAdapter ? "signal_wifi_off" : (root.wifiPowered ? (root.activeSsid !== "" ? "wifi" : "wifi_find") : "signal_wifi_off")
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 22
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                            color: (root.wifiPowered && root.hasAdapter) ? Config.accent : Config.textMuted
                        }
                    }

                    // Status Text
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 2

                        RowLayout {
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 8
                            Text {
                                text: "Wireless Radio"
                                font.family: Config.sysFont
                                font.bold: true
                                color: Config.textMain
                                font.pixelSize: Config.size(Config.fontBody)
                                verticalAlignment: Text.AlignVCenter
                            }

                            Rectangle {
                                implicitWidth: statusPillText.implicitWidth + 10
                                implicitHeight: 18
                                radius: 9
                                Layout.alignment: Qt.AlignVCenter
                                color: !root.hasAdapter
                                    ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.2)
                                    : (root.wifiPowered ? (root.activeSsid !== "" ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.2) : Qt.rgba(255, 255, 255, 0.1)) : Qt.rgba(255, 255, 255, 0.08))
                                border.width: 2
                                border.color: !root.hasAdapter
                                    ? Config.accent
                                    : (root.wifiPowered && root.activeSsid !== "" ? Config.accent : Qt.rgba(255, 255, 255, 0.15))

                                Text {
                                    id: statusPillText
                                    anchors.centerIn: parent
                                    text: !root.hasAdapter ? "NO ADAPTER" : (!root.wifiPowered ? "DISABLED" : (root.activeSsid !== "" ? "CONNECTED" : "DISCONNECTED"))
                                    font.family: Config.sysFont
                                    font.pixelSize: 9
                                    font.bold: true
                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: Text.AlignHCenter
                                    color: !root.hasAdapter
                                        ? Config.accent
                                        : (root.wifiPowered && root.activeSsid !== "" ? Config.accent : Config.textMuted)
                                }
                            }
                        }

                        Text {
                            text: !root.hasAdapter
                                ? "No wireless network hardware interface detected"
                                : (!root.wifiPowered
                                    ? "Wi-Fi radio is currently powered off to save power"
                                    : (root.activeSsid !== "" ? ("Connected to " + root.activeSsid) : "Wi-Fi enabled • Scanning for access points"))
                            font.family: Config.sysFont
                            color: (root.wifiPowered && root.activeSsid !== "") ? Config.accent : Config.textMuted
                            font.pixelSize: Config.size(Config.fontCaption)
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    // Spacer to push action buttons to the right
                    Item { Layout.fillWidth: true }

                    // Action Buttons (Rescan & Power Toggle)
                    RowLayout {
                        spacing: 8
                        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                        // RESCAN BUTTON
                        Rectangle {
                            implicitWidth: rescanRow.implicitWidth + 16
                            implicitHeight: 32
                            radius: 16
                            Layout.alignment: Qt.AlignVCenter
                            visible: root.wifiPowered && root.hasAdapter
                            color: rescanHover.hovered ? Qt.rgba(255, 255, 255, 0.12) : Qt.rgba(255, 255, 255, 0.06)
                            border.width: 2
                            border.color: Qt.rgba(255, 255, 255, 0.12)

                            Behavior on color { ColorAnimation { duration: 150 } }

                            RowLayout {
                                id: rescanRow
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    id: scanIconText
                                    text: "refresh"
                                    font.family: "Material Symbols Outlined"
                                    font.pixelSize: 16
                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: Text.AlignHCenter
                                    color: rescanHover.hovered ? Config.accent : Config.textMain

                                    NumberAnimation on rotation {
                                        from: 0; to: 360; duration: 1000; loops: Animation.Infinite
                                        running: root.wifiScanning
                                    }
                                }

                                Text {
                                    text: root.wifiScanning ? "Scanning..." : "Rescan"
                                    font.family: Config.sysFont
                                    font.pixelSize: 11
                                    font.bold: true
                                    verticalAlignment: Text.AlignVCenter
                                    color: rescanHover.hovered ? Config.accent : Config.textMain
                                }
                            }

                            TapHandler { onTapped: root.triggerScan() }
                            HoverHandler { id: rescanHover; cursorShape: Qt.PointingHandCursor }
                        }

                        // POWER TOGGLE BUTTON
                        Rectangle {
                            id: pwrBtn
                            implicitWidth: pwrRow.implicitWidth + 18
                            implicitHeight: 32
                            radius: 16
                            Layout.alignment: Qt.AlignVCenter
                            enabled: root.hasAdapter
                            color: (root.wifiPowered && root.hasAdapter)
                                ? (pwrHover.hovered ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.85) : Config.accent)
                                : (pwrHover.hovered ? Qt.rgba(255, 255, 255, 0.15) : Qt.rgba(255, 255, 255, 0.08))

                            Behavior on color { ColorAnimation { duration: 180 } }

                            RowLayout {
                                id: pwrRow
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    text: root.wifiPowered ? "power_settings_new" : "power_off"
                                    font.family: "Material Symbols Outlined"
                                    font.pixelSize: 16
                                    verticalAlignment: Text.AlignVCenter
                                    horizontalAlignment: Text.AlignHCenter
                                    color: (root.wifiPowered && root.hasAdapter) ? Config.bgBase : Config.textMuted
                                }

                                Text {
                                    text: root.wifiPowered ? "ON" : "OFF"
                                    font.family: Config.sysFont
                                    font.pixelSize: 11
                                    font.bold: true
                                    verticalAlignment: Text.AlignVCenter
                                    color: (root.wifiPowered && root.hasAdapter) ? Config.bgBase : Config.textMuted
                                }
                            }

                            TapHandler {
                                enabled: root.hasAdapter
                                onTapped: {
                                    let nextState = root.wifiPowered ? "off" : "on"
                                    toggleWifiProc.command = ["fish", "-c", "nmcli radio wifi " + nextState]
                                    toggleWifiProc.running = true
                                }
                            }
                            HoverHandler { id: pwrHover; cursorShape: Qt.PointingHandCursor }
                        }
                    }
                }
            }

            // ==========================================
            // 2. DETECTED NETWORKS SECTION
            // ==========================================
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8
                visible: root.hasAdapter && root.wifiPowered

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "AVAILABLE ACCESS POINTS"
                        color: Config.textMuted
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontMicro)
                        font.bold: true
                    }

                    Rectangle {
                        implicitWidth: countText.implicitWidth + 10
                        implicitHeight: 16
                        radius: 8
                        color: Qt.rgba(255, 255, 255, 0.08)

                        Text {
                            id: countText
                            anchors.centerIn: parent
                            text: wifiModel.count.toString()
                            font.family: Config.sysFont
                            font.pixelSize: 9
                            font.bold: true
                            color: Config.textMuted
                        }
                    }

                    Item { Layout.fillWidth: true }
                }

                // NETWORKS LIST VIEW
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Repeater {
                        model: wifiModel

                        delegate: Rectangle {
                            id: netCard
                            required property string ssid
                            required property bool connected
                            required property bool isSecure
                            required property bool isSaved
                            readonly property bool isExpanded: root.expandedSsid === ssid
                            readonly property bool isConnecting: root.connectingSsid === ssid
                            readonly property bool isDisconnecting: root.disconnectingSsid === ssid
                            readonly property bool hasError: root.errorSsid === ssid

                            Layout.fillWidth: true
                            implicitHeight: netCol.implicitHeight + 20
                            radius: Config.cornerRadius * 0.75
                            color: connected
                                ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.12)
                                : (hasError
                                    ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.15)
                                    : (netHover.hovered ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(255, 255, 255, 0.04)))
                            border.width: 2
                            border.color: connected
                                ? Config.accent
                                : (hasError ? Config.accent : (netHover.hovered ? Qt.rgba(255, 255, 255, 0.15) : Qt.rgba(255, 255, 255, 0.08)))
                            clip: true

                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            ColumnLayout {
                                id: netCol
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 8

                                // Main Row
                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignVCenter
                                    spacing: 12

                                    // Signal / Lock Icon Badge
                                    Rectangle {
                                        implicitWidth: 36
                                        implicitHeight: 36
                                        radius: 18
                                        Layout.alignment: Qt.AlignVCenter
                                        color: connected
                                            ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.25)
                                            : Qt.rgba(255, 255, 255, 0.06)

                                        Text {
                                            anchors.centerIn: parent
                                            text: isSecure ? "wifi_password" : "wifi"
                                            font.family: "Material Symbols Outlined"
                                            font.pixelSize: 18
                                            verticalAlignment: Text.AlignVCenter
                                            horizontalAlignment: Text.AlignHCenter
                                            color: connected ? Config.accent : Config.textMain
                                        }
                                    }

                                    // SSID Name & Badges
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        Layout.alignment: Qt.AlignVCenter
                                        spacing: 2

                                        TapHandler {
                                            onTapped: {
                                                root.expandedSsid = (root.expandedSsid === ssid) ? "" : ssid
                                            }
                                        }

                                        RowLayout {
                                            Layout.alignment: Qt.AlignVCenter
                                            spacing: 6

                                            Text {
                                                text: ssid
                                                color: connected ? Config.accent : Config.textMain
                                                font.family: Config.sysFont
                                                font.pixelSize: Config.size(Config.fontBody)
                                                font.bold: true
                                                verticalAlignment: Text.AlignVCenter
                                                elide: Text.ElideRight
                                                Layout.maximumWidth: 300
                                                Layout.alignment: Qt.AlignVCenter
                                            }

                                            // SAVED BADGE
                                            Rectangle {
                                                visible: isSaved && !connected
                                                implicitWidth: savedBadgeText.implicitWidth + 8
                                                implicitHeight: 16
                                                radius: 8
                                                Layout.alignment: Qt.AlignVCenter
                                                color: Qt.rgba(255, 255, 255, 0.1)

                                                Text {
                                                    id: savedBadgeText
                                                    anchors.centerIn: parent
                                                    text: "SAVED"
                                                    font.family: Config.sysFont
                                                    font.pixelSize: 9
                                                    font.bold: true
                                                    verticalAlignment: Text.AlignVCenter
                                                    color: Config.textMuted
                                                }
                                            }

                                            // CONNECTED BADGE
                                            Rectangle {
                                                visible: connected
                                                implicitWidth: connBadgeText.implicitWidth + 8
                                                implicitHeight: 16
                                                radius: 8
                                                Layout.alignment: Qt.AlignVCenter
                                                color: Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.25)
                                                border.width: 2
                                                border.color: Config.accent

                                                Text {
                                                    id: connBadgeText
                                                    anchors.centerIn: parent
                                                    text: "ACTIVE"
                                                    font.family: Config.sysFont
                                                    font.pixelSize: 9
                                                    font.bold: true
                                                    verticalAlignment: Text.AlignVCenter
                                                    color: Config.accent
                                                }
                                            }
                                        }

                                        Text {
                                            text: isSecure ? "WPA/WPA2 Personal" : "Open Access Point (Unsecured)"
                                            color: Config.textMuted
                                            font.family: Config.sysFont
                                            font.pixelSize: Config.size(Config.fontMicro)
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                    }

                                    // Spacer to push quick actions to the right
                                    Item { Layout.fillWidth: true }

                                    // Direct Quick Actions
                                    RowLayout {
                                        spacing: 6
                                        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                                        // Connect Button for Saved Networks
                                        Rectangle {
                                            visible: !connected && isSaved && !isExpanded
                                            implicitWidth: Math.max(connBtnText.implicitWidth + 24, 76)
                                            implicitHeight: 28
                                            radius: 14
                                            Layout.alignment: Qt.AlignVCenter
                                            color: qConnHover.hovered ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.85) : Config.accent

                                            Text {
                                                id: connBtnText
                                                anchors.centerIn: parent
                                                text: isConnecting ? "..." : "Connect"
                                                font.family: Config.sysFont
                                                font.bold: true
                                                font.pixelSize: 11
                                                verticalAlignment: Text.AlignVCenter
                                                color: Config.bgBase
                                            }

                                            TapHandler {
                                                enabled: !isConnecting && !isDisconnecting
                                                onTapped: root.connectWifi(ssid, "")
                                            }
                                            HoverHandler { id: qConnHover; cursorShape: Qt.PointingHandCursor }
                                        }

                                        // Expand Arrow / Join Button
                                        Rectangle {
                                            implicitWidth: 30
                                            implicitHeight: 30
                                            radius: 15
                                            Layout.alignment: Qt.AlignVCenter
                                            color: expHover.hovered ? Qt.rgba(255, 255, 255, 0.12) : Qt.rgba(255, 255, 255, 0.05)

                                            Text {
                                                anchors.centerIn: parent
                                                text: isExpanded ? "expand_less" : "chevron_right"
                                                font.family: "Material Symbols Outlined"
                                                font.pixelSize: 18
                                                verticalAlignment: Text.AlignVCenter
                                                horizontalAlignment: Text.AlignHCenter
                                                color: expHover.hovered ? Config.textMain : Config.textMuted
                                            }

                                            TapHandler {
                                                onTapped: {
                                                    root.expandedSsid = (root.expandedSsid === ssid) ? "" : ssid
                                                }
                                            }
                                            HoverHandler { id: expHover; cursorShape: Qt.PointingHandCursor }
                                        }
                                    }
                                }

                                // EXPANDED ACTION & AUTHENTICATION DRAWER
                                ColumnLayout {
                                    visible: isExpanded
                                    Layout.fillWidth: true
                                    spacing: 8

                                    // ERROR BANNER
                                    Rectangle {
                                        visible: hasError
                                        Layout.fillWidth: true
                                        implicitHeight: errText.implicitHeight + 12
                                        radius: 6
                                        color: Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.2)
                                        border.width: 2
                                        border.color: Config.accent

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.margins: 6
                                            spacing: 6
                                            Text { text: "error"; font.family: "Material Symbols Outlined"; font.pixelSize: 16; verticalAlignment: Text.AlignVCenter; color: Config.accent }
                                            Text { id: errText; text: root.connectionError; font.family: Config.sysFont; font.pixelSize: 11; font.bold: true; verticalAlignment: Text.AlignVCenter; color: Config.accent; Layout.fillWidth: true }
                                        }
                                    }

                                    // PASSWORD INPUT ROW
                                    RowLayout {
                                        visible: !connected && isSecure && (!isSaved || hasError)
                                        Layout.fillWidth: true
                                        spacing: 8

                                        Rectangle {
                                            Layout.fillWidth: true
                                            implicitHeight: 32
                                            radius: 8
                                            color: Qt.rgba(0, 0, 0, 0.35)
                                            border.width: 2
                                            border.color: passInput.activeFocus ? Config.accent : (hasError ? Config.accent : Qt.rgba(255, 255, 255, 0.15))

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.leftMargin: 10
                                                anchors.rightMargin: 6
                                                spacing: 6

                                                Text {
                                                    text: "key"
                                                    font.family: "Material Symbols Outlined"
                                                    font.pixelSize: 15
                                                    verticalAlignment: Text.AlignVCenter
                                                    color: Config.textMuted
                                                }

                                                TextInput {
                                                    id: passInput
                                                    Layout.fillWidth: true
                                                    color: Config.textMain
                                                    font.family: Config.sysFont
                                                    font.pixelSize: 12
                                                    verticalAlignment: Text.AlignVCenter
                                                    echoMode: showPassToggle.showPassword ? TextInput.Normal : TextInput.Password
                                                    enabled: !isConnecting && !isDisconnecting
                                                    selectByMouse: true
                                                    clip: true

                                                    Text {
                                                        anchors.fill: parent
                                                        text: "Enter Wi-Fi network password..."
                                                        color: Qt.rgba(255, 255, 255, 0.3)
                                                        font.family: Config.sysFont
                                                        font.pixelSize: 12
                                                        verticalAlignment: Text.AlignVCenter
                                                        visible: !passInput.text && !passInput.activeFocus
                                                    }

                                                    onAccepted: {
                                                        if (isSecure && passInput.text.trim() === "" && (!isSaved || hasError)) {
                                                             root.errorSsid = ssid
                                                             root.connectionError = "Password Required"
                                                             return
                                                        }
                                                        root.connectWifi(ssid, passInput.text)
                                                    }
                                                    onTextChanged: {
                                                        if (hasError && passInput.activeFocus) {
                                                            root.errorSsid = ""
                                                            root.connectionError = ""
                                                        }
                                                    }
                                                }

                                                // Eye Toggle Button
                                                Rectangle {
                                                    id: showPassToggle
                                                    property bool showPassword: false
                                                    implicitWidth: 24
                                                    implicitHeight: 24
                                                    radius: 12
                                                    color: eyeHover.hovered ? Qt.rgba(255, 255, 255, 0.12) : "transparent"

                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: showPassToggle.showPassword ? "visibility" : "visibility_off"
                                                        font.family: "Material Symbols Outlined"
                                                        font.pixelSize: 15
                                                        verticalAlignment: Text.AlignVCenter
                                                        horizontalAlignment: Text.AlignHCenter
                                                        color: eyeHover.hovered ? Config.textMain : Config.textMuted
                                                    }

                                                    TapHandler { onTapped: showPassToggle.showPassword = !showPassToggle.showPassword }
                                                    HoverHandler { id: eyeHover; cursorShape: Qt.PointingHandCursor }
                                                }
                                            }
                                        }

                                        // JOIN ACTION BUTTON
                                        Rectangle {
                                            implicitWidth: joinLabel.implicitWidth + 20
                                            implicitHeight: 32
                                            radius: 8
                                            color: joinActionHover.hovered ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.85) : Config.accent

                                            Text {
                                                id: joinLabel
                                                anchors.centerIn: parent
                                                text: isConnecting ? "Connecting..." : "Join Network"
                                                font.family: Config.sysFont
                                                font.bold: true
                                                font.pixelSize: 11
                                                verticalAlignment: Text.AlignVCenter
                                                color: Config.bgBase
                                            }

                                            TapHandler {
                                                enabled: !isConnecting && !isDisconnecting
                                                onTapped: {
                                                    if (isSecure && passInput.text.trim() === "" && (!isSaved || hasError)) {
                                                        root.errorSsid = ssid
                                                        root.connectionError = "Password Required"
                                                        return
                                                    }
                                                    root.connectWifi(ssid, passInput.text)
                                                }
                                            }
                                            HoverHandler { id: joinActionHover; cursorShape: Qt.PointingHandCursor }
                                        }
                                    }

                                    // CONTROLS & FORGET ROW
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8

                                        // Disconnect Button
                                        Rectangle {
                                            visible: connected
                                            Layout.fillWidth: true
                                            implicitHeight: 30
                                            radius: 8
                                            color: discActionHover.hovered ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.2) : Qt.rgba(255, 255, 255, 0.08)
                                            border.width: 2
                                            border.color: discActionHover.hovered ? Config.accent : Qt.rgba(255, 255, 255, 0.12)

                                            RowLayout {
                                                anchors.centerIn: parent
                                                spacing: 6
                                                Text { text: "link_off"; font.family: "Material Symbols Outlined"; font.pixelSize: 14; verticalAlignment: Text.AlignVCenter; color: discActionHover.hovered ? Config.accent : Config.textMain }
                                                Text { text: isDisconnecting ? "Disconnecting..." : "Disconnect"; font.family: Config.sysFont; font.bold: true; font.pixelSize: 11; verticalAlignment: Text.AlignVCenter; color: discActionHover.hovered ? Config.accent : Config.textMain }
                                            }

                                            TapHandler {
                                                enabled: !isDisconnecting && !isConnecting
                                                onTapped: root.disconnectWifi(ssid)
                                            }
                                            HoverHandler { id: discActionHover; cursorShape: Qt.PointingHandCursor }
                                        }

                                        // Connect Button for Saved Networks inside drawer
                                        Rectangle {
                                            visible: !connected && isSaved
                                            Layout.fillWidth: true
                                            implicitHeight: 30
                                            radius: 8
                                            color: connActionHover.hovered ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.85) : Config.accent

                                            RowLayout {
                                                anchors.centerIn: parent
                                                spacing: 6
                                                Text { text: "login"; font.family: "Material Symbols Outlined"; font.pixelSize: 14; verticalAlignment: Text.AlignVCenter; color: Config.bgBase }
                                                Text { text: isConnecting ? "Connecting..." : "Connect"; font.family: Config.sysFont; font.bold: true; font.pixelSize: 11; verticalAlignment: Text.AlignVCenter; color: Config.bgBase }
                                            }

                                            TapHandler {
                                                enabled: !isConnecting && !isDisconnecting
                                                onTapped: root.connectWifi(ssid, "")
                                            }
                                            HoverHandler { id: connActionHover; cursorShape: Qt.PointingHandCursor }
                                        }

                                        // Forget Network Profile Button
                                        Rectangle {
                                            visible: isSaved
                                            Layout.fillWidth: true
                                            implicitHeight: 30
                                            radius: 8
                                            color: forgetActionHover.hovered ? Qt.rgba(255, 255, 255, 0.12) : Qt.rgba(255, 255, 255, 0.05)
                                            border.width: 2
                                            border.color: Qt.rgba(255, 255, 255, 0.1)

                                            RowLayout {
                                                anchors.centerIn: parent
                                                spacing: 6
                                                Text { text: "delete_outline"; font.family: "Material Symbols Outlined"; font.pixelSize: 14; verticalAlignment: Text.AlignVCenter; color: forgetActionHover.hovered ? Config.accent : Config.textMuted }
                                                Text { text: "Forget Profile"; font.family: Config.sysFont; font.bold: true; font.pixelSize: 11; verticalAlignment: Text.AlignVCenter; color: forgetActionHover.hovered ? Config.accent : Config.textMuted }
                                            }

                                            TapHandler {
                                                enabled: !isConnecting && !isDisconnecting
                                                onTapped: root.forgetWifi(ssid)
                                            }
                                            HoverHandler { id: forgetActionHover; cursorShape: Qt.PointingHandCursor }
                                        }
                                    }
                                }
                            }
                            HoverHandler { id: netHover; cursorShape: Qt.PointingHandCursor }
                        }
                    }
                }
            }

            // ==========================================
            // 3. EMPTY / DISABLED STATE CARD
            // ==========================================
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 160
                radius: Config.cornerRadius
                color: Qt.rgba(255, 255, 255, 0.03)
                border.width: 2
                border.color: Qt.rgba(255, 255, 255, 0.06)
                visible: root.hasPolledOnce && (!root.hasAdapter || !root.wifiPowered || (wifiModel.count === 0 && !root.wifiScanning))

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 10

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: !root.hasAdapter ? "phonelink_erase" : (!root.wifiPowered ? "wifi_off" : "wifi_find")
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 36
                        color: Config.textMuted
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: !root.hasAdapter
                            ? "No Wi-Fi interface detected"
                            : (!root.wifiPowered ? "Wi-Fi is currently disabled" : "No nearby wireless networks detected")
                        font.family: Config.sysFont
                        font.bold: true
                        font.pixelSize: Config.size(Config.fontBody)
                        color: Config.textMain
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: !root.hasAdapter
                            ? "Check your network adapter hardware or kernel modules"
                            : (!root.wifiPowered ? "Toggle the power switch above to scan for networks" : "Click Rescan to probe for 2.4GHz and 5GHz access points")
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontCaption)
                        color: Config.textMuted
                    }
                }
            }
        }
    }

    // ==========================================
    // BACKEND IPC PROCESSES & TIMERS
    // ==========================================
    Timer {
        interval: 4000; running: root.visible && root.hasAdapter; repeat: true; triggeredOnStart: true
        onTriggered: {
            if (!root.hasActiveInputFocus()) {
                fetchWifiStatusProc.running = false
                fetchWifiStatusProc.running = true
            }
        }
    }

    Timer {
        id: scanTimeoutTimer
        interval: 3500
        repeat: false
        onTriggered: {
            root.wifiScanning = false
            fetchWifiStatusProc.running = false
            fetchWifiStatusProc.running = true
        }
    }

    function hasActiveInputFocus() {
        return root.Window.window && root.Window.window.activeFocusItem && root.Window.window.activeFocusItem instanceof TextInput
    }

    Process {
        id: toggleWifiProc
        running: false
        onExited: {
            fetchWifiStatusProc.running = false
            fetchWifiStatusProc.running = true
        }
    }

    Process {
        id: fetchWifiStatusProc
        command: ["fish", "-c", "nmcli -t -f TYPE device | grep -q '^wifi$' && echo 'YES' || echo 'NO'; echo '---'; nmcli -t -f WIFI g; echo '---'; nmcli -t -f TYPE,NAME connection show --active | awk -F: '$1 ~ /802-11-wireless|wifi/ {print $2; exit}'; echo '---'; nmcli -t -f TYPE,NAME connection show | awk -F: '$1 ~ /802-11-wireless|wifi/ {print $2}'; echo '---'; nmcli -t -f ACTIVE,SSID,SECURITY device wifi"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let parts = this.text.split("---")
                if (parts.length < 5) return
                root.hasAdapter = parts[0].trim() === "YES"
                root.wifiPowered = parts[1].trim().includes("enabled")
                root.hasPolledOnce = true
                
                let activeConnSsid = parts[2].trim()
                let savedList = parts[3].trim().split("\n").map(s => s.trim()).filter(s => s.length > 0)
                root.savedSsids = savedList

                if (root.hasActiveInputFocus()) return

                wifiModel.clear()
                if (!root.wifiPowered || !root.hasAdapter) return

                let lines = parts[4].trim().split("\n")
                let seen = {}, active = activeConnSsid
                
                if (activeConnSsid.length > 0) {
                    wifiModel.append({ ssid: activeConnSsid, connected: true, isSecure: true, isSaved: true })
                    seen[activeConnSsid] = true
                }

                for (let i = 0; i < lines.length; i++) {
                    let fields = lines[i].split(":")
                    if (fields.length < 2) continue
                    let isConn = fields[0].toLowerCase() === "yes" || fields[0].toLowerCase() === "true"
                    let ssidName = fields[1].trim()
                    let sec = fields[2] || ""
                    
                    if (!ssidName) continue
                    if (isConn && !active) active = ssidName

                    let isSavedProfile = savedList.indexOf(ssidName) !== -1

                    if (seen[ssidName]) {
                        if (isConn) {
                            for (let m = 0; m < wifiModel.count; m++) {
                                if (wifiModel.get(m).ssid === ssidName) {
                                    wifiModel.setProperty(m, "connected", true)
                                    wifiModel.setProperty(m, "isSaved", true)
                                    break
                                }
                            }
                        }
                        continue
                    }
                    
                    seen[ssidName] = true
                    wifiModel.append({ 
                        ssid: ssidName, 
                        connected: isConn || (ssidName === activeConnSsid), 
                        isSecure: sec !== "",
                        isSaved: isSavedProfile
                    })
                }
                root.activeSsid = active
            }
        }
    }

    function triggerScan() {
        if (root.wifiScanning || !root.hasAdapter) return
        root.wifiScanning = true
        scanProc.command = ["fish", "-c", "nmcli device wifi rescan"]
        scanProc.running = true
        scanTimeoutTimer.restart()
    }

    Process { 
        id: scanProc
        running: false 
    }
    
    function connectWifi(ssid, password) {
        if (!root.hasAdapter || connProc.running || discProc.running) return
        connProc.activeTargetSsid = ssid
        root.connectingSsid = ssid
        root.errorSsid = ""
        root.connectionError = ""
        
        let escapedSsid = ssid.replace(/'/g, "'\"'\"'")
        let cmd = ""
        if (password.length > 0) {
            let escapedPass = password.replace(/'/g, "'\"'\"'")
            cmd = `nmcli device wifi connect '${escapedSsid}' password '${escapedPass}'`
        } else {
            cmd = `nmcli connection up id '${escapedSsid}' 2>/dev/null || nmcli device wifi connect '${escapedSsid}'`
        }
        
        connProc.command = ["fish", "-c", cmd]
        connProc.running = true
    }
    
    function disconnectWifi(ssid) {
        if (!root.hasAdapter || discProc.running || connProc.running) return
        root.disconnectingSsid = ssid
        root.errorSsid = ""
        root.connectionError = ""
        
        let escapedSsid = ssid.replace(/'/g, "'\"'\"'")
        
        discProc.command = ["fish", "-c", `
            set active_uuid (nmcli -t -f UUID,TYPE,NAME connection show --active | awk -F: -v target='${escapedSsid}' '($2 ~ /802-11-wireless|wifi/) && $3 == target {print $1; exit}')
            
            if test -n "$active_uuid"
                nmcli connection down "$active_uuid"
            else
                set dev (nmcli -t -f DEVICE,TYPE device | awk -F: '$2 ~ /802-11-wireless|wifi/ {print $1; exit}')
                if test -n "$dev"
                    nmcli device disconnect "$dev"
                end
            end
        `]
        discProc.running = true
    }

    function forgetWifi(ssid) {
        if (!root.hasAdapter || forgetProc.running) return
        root.errorSsid = ""
        root.connectionError = ""
        
        let escapedSsid = ssid.replace(/'/g, "'\"'\"'")
        
        forgetProc.command = ["fish", "-c", `
            set uuids (nmcli -t -f UUID,TYPE,NAME connection show | awk -F: -v target='${escapedSsid}' '$2 ~ /802-11-wireless/ && $3 == target {print $1}')
            for u in $uuids
                nmcli connection delete uuid "$u"
            end
        `]
        forgetProc.running = true
    }

    Process { 
        id: discProc
        running: false
        onExited: {
            root.disconnectingSsid = ""
            fetchWifiStatusProc.running = false
            fetchWifiStatusProc.running = true
        }
    }

    Process { 
        id: forgetProc
        running: false
        onExited: {
            root.errorSsid = ""
            root.connectionError = ""
            fetchWifiStatusProc.running = false
            fetchWifiStatusProc.running = true
        }
    }

    Process {
        id: connCleanupProc
        running: false
        onExited: {
            fetchWifiStatusProc.running = false
            fetchWifiStatusProc.running = true
        }
    }

    Process {
        id: connProc
        running: false
        property string activeTargetSsid: ""

        stdout: StdioCollector { id: connStdout }
        stderr: StdioCollector { id: connStderr }

        onExited: (exitCode) => {
            let failedSsid = activeTargetSsid
            root.connectingSsid = ""

            if (exitCode !== 0 && failedSsid !== "") {
                root.errorSsid = failedSsid
                root.expandedSsid = failedSsid
                let fullErr = (connStdout.text + "\n" + connStderr.text).trim().toLowerCase()
                if (fullErr.includes("not found") || fullErr.includes("no network")) {
                    root.connectionError = "Network Not Found"
                } else {
                    root.connectionError = "Invalid Password"
                }

                let safeSsid = failedSsid.replace(/'/g, "'\"'\"'")
                connCleanupProc.command = ["fish", "-c", `
                    set uuids (nmcli -t -f UUID,TYPE,NAME connection show | awk -F: -v target='${safeSsid}' '$2 ~ /802-11-wireless|wifi/ && $3 == target {print $1}')
                    for u in $uuids
                        nmcli connection delete uuid "$u" 2>/dev/null
                    end
                `]
                connCleanupProc.running = true
            } else {
                root.errorSsid = ""
                root.connectionError = ""
                fetchWifiStatusProc.running = false
                fetchWifiStatusProc.running = true
            }
        }
    }
}
