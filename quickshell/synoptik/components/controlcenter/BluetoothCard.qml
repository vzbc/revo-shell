import QtQuick
import Qt5Compat.GraphicalEffects
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import ".."

Item {
    id: cardRoot
    
    Layout.fillWidth: true
    Layout.preferredWidth: 1
    Layout.alignment: Qt.AlignTop

    implicitHeight: 64
    Layout.preferredHeight: 64
    z: panelExpanded ? 1000 : 1

    property Item controlCenterPanel: null
    property bool panelExpanded: false

    property bool hasHardware: true
    property bool isPowered: false
    property bool isScanning: false
    property string connectedDeviceName: ""
    property string connectingMac: ""
    property string expandedMac: ""
    property var btDevices: []

    property bool shouldExpand: panelExpanded
    readonly property real cardMargin: Config.cardMargin !== undefined ? Config.cardMargin : 12

    signal togglePower(bool power)
    signal triggerScan()

    ListModel {
        id: btModel
    }

    function getDeviceIcon(name) {
        let n = (name || "").toLowerCase()
        if (n.includes("headset") || n.includes("buds") || n.includes("airpods") || n.includes("wh-") || n.includes("wf-") || n.includes("quietcomfort") || n.includes("bose") || n.includes("sony") || n.includes("audio") || n.includes("ear") || n.includes("freebuds") || n.includes("headphone")) return "headphones"
        if (n.includes("speaker") || n.includes("soundbar") || n.includes("echo") || n.includes("jbl") || n.includes("marshall")) return "speaker"
        if (n.includes("mouse") || n.includes("mx master") || n.includes("trackball") || n.includes("touchpad")) return "mouse"
        if (n.includes("keyboard") || n.includes("keychron") || n.includes("magic keyboard")) return "keyboard"
        if (n.includes("watch") || n.includes("band") || n.includes("garmin") || n.includes("fitbit") || n.includes("galaxy watch")) return "watch"
        if (n.includes("phone") || n.includes("iphone") || n.includes("pixel") || n.includes("galaxy")) return "smartphone"
        if (n.includes("tv") || n.includes("chromecast") || n.includes("appletv")) return "tv"
        if (n.includes("gamepad") || n.includes("controller") || n.includes("dualsense") || n.includes("xbox")) return "sports_esports"
        return "bluetooth"
    }

    onVisibleChanged: {
        if (!visible) panelExpanded = false
    }

    onPanelExpandedChanged: {
        if (panelExpanded && hasHardware && isPowered) {
            execTriggerScan()
        }
    }

    readonly property real collapsedX: {
        let sum = 0
        let p = cardRoot
        while (p && p !== controlCenterPanel) {
            sum += p.x
            p = p.parent
        }
        return sum
    }

    readonly property real collapsedY: {
        let sum = 0
        let p = cardRoot
        while (p && p !== controlCenterPanel) {
            sum += p.y
            p = p.parent
        }
        return sum
    }

    Rectangle {
        id: visualBackground
        parent: controlCenterPanel ? controlCenterPanel : cardRoot.parent
        z: cardRoot.panelExpanded ? 1000 : 100
        clip: true
        
        x: cardRoot.panelExpanded ? cardRoot.cardMargin : cardRoot.collapsedX
        y: cardRoot.panelExpanded ? cardRoot.cardMargin : cardRoot.collapsedY
        width: cardRoot.panelExpanded ? (controlCenterPanel ? (controlCenterPanel.width - (cardRoot.cardMargin * 2)) : 400) : cardRoot.width
        height: cardRoot.panelExpanded ? (controlCenterPanel ? (controlCenterPanel.height - (cardRoot.cardMargin * 2)) : 500) : 64
        
        radius: Config.cornerRadius
        
        color: cardRoot.panelExpanded
            ? Qt.rgba(Config.bgBase.r, Config.bgBase.g, Config.bgBase.b, 1.0)
            : ((cardHover.hovered && cardRoot.hasHardware) ? Qt.rgba(Config.bgBase.r, Config.bgBase.g, Config.bgBase.b, 0.85) : Qt.rgba(0, 0, 0, 0.25))
        border.width: 1
        border.color: cardRoot.panelExpanded ? Qt.rgba(255, 255, 255, 0.1) : "transparent"

        opacity: cardRoot.hasHardware ? 1.0 : 0.4
        enabled: cardRoot.hasHardware

        Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 150 } }
        Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }

        HoverHandler {
            id: cardHover
            enabled: !cardRoot.panelExpanded
        }

        MouseArea {
            anchors.fill: parent
            enabled: cardRoot.panelExpanded
            preventStealing: true
            hoverEnabled: true
            acceptedButtons: Qt.AllButtons
            onPressed: (mouse) => mouse.accepted = true
            onReleased: (mouse) => mouse.accepted = true
            onClicked: (mouse) => mouse.accepted = true
        }

        TapHandler {
            enabled: cardRoot.panelExpanded
            gesturePolicy: TapHandler.WithinBounds
            onTapped: {}
        }

        // --- 1. COLLAPSED CARD HEADER VIEW ---
        Item {
            id: collapsedView
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 64
            visible: opacity > 0
            enabled: !cardRoot.panelExpanded
            opacity: cardRoot.panelExpanded ? 0.0 : 1.0
            Behavior on opacity { NumberAnimation { duration: 150 } }

            Item {
                anchors.fill: parent
                anchors.margins: 10

                RowLayout {
                    anchors.fill: parent
                    spacing: 8

                    Rectangle {
                        implicitWidth: 44
                        implicitHeight: 44
                        radius: Config.cornerRadius / 2
                        color: cardRoot.isPowered && cardRoot.hasHardware 
                            ? (iconHover.hovered ? Qt.lighter(Config.accent, 1.1) : Config.accent)
                            : (iconHover.hovered ? Qt.rgba(255, 255, 255, 0.15) : Qt.rgba(255, 255, 255, 0.08))
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: !cardRoot.hasHardware ? "bluetooth_disabled" : (cardRoot.isPowered ? "bluetooth" : "bluetooth_disabled")
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 22
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                            color: cardRoot.isPowered && cardRoot.hasHardware ? Config.bgBase : Config.textMuted
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: cardRoot.hasHardware ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                if (cardRoot.hasHardware) cardRoot.execTogglePower(!cardRoot.isPowered)
                            }
                        }
                        HoverHandler { id: iconHover }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        clip: true

                        Text {
                            text: "Bluetooth"
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontCaption)
                            font.bold: true
                            color: Config.textMain
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: !cardRoot.hasHardware ? "No Controller" : (!cardRoot.isPowered ? "Off" : (cardRoot.connectedDeviceName !== "" ? cardRoot.connectedDeviceName : "On"))
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontMicro)
                            font.bold: cardRoot.connectedDeviceName !== "" && cardRoot.hasHardware
                            color: cardRoot.connectedDeviceName !== "" && cardRoot.hasHardware ? Config.accent : Config.textMuted
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    Text {
                        text: "chevron_right"
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 20
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                        color: cardHover.hovered ? Config.textMain : Config.textMuted
                        opacity: cardRoot.hasHardware ? 0.7 : 0.2
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.leftMargin: 52
                    cursorShape: cardRoot.hasHardware ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        if (cardRoot.hasHardware) cardRoot.panelExpanded = true
                    }
                }
            }
        }

        // --- 2. EXPANDED FULL CONTROL CENTER PANEL VIEW ---
        Item {
            id: expandedView
            anchors.fill: parent
            anchors.margins: 14
            visible: opacity > 0
            enabled: cardRoot.panelExpanded
            opacity: cardRoot.panelExpanded ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 180 } }

            RowLayout {
                id: btHeaderRow
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 44
                spacing: 10

                Rectangle {
                    implicitWidth: 36
                    implicitHeight: 36
                    radius: 18
                    Layout.alignment: Qt.AlignVCenter
                    color: backHover.hovered ? Qt.rgba(255, 255, 255, 0.15) : Qt.rgba(255, 255, 255, 0.08)
                    border.width: 2
                    border.color: backHover.hovered ? Config.accent : Qt.rgba(255, 255, 255, 0.12)
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: "arrow_back"
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 20
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                        color: backHover.hovered ? Config.accent : Config.textMain
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: cardRoot.panelExpanded = false
                    }
                    HoverHandler { id: backHover }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 0

                    Item {
                        implicitWidth: btExpTitleText.implicitWidth
                        implicitHeight: btExpTitleText.implicitHeight
                        Layout.fillWidth: true

                        Text {
                            id: btExpTitleText
                            text: "BLUETOOTH"
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontTitle)
                            font.bold: true
                            font.italic: true
                            elide: Text.ElideRight
                        }

                        Glow {
                            anchors.fill: btExpTitleText
                            source: btExpTitleText
                            radius: 6
                            samples: 12
                            color: Config.accent
                            spread: 0.2
                            transparentBorder: true
                            visible: Config.clockShowGlow
                        }
                    }

                    Text {
                        text: !cardRoot.hasHardware ? "No Controller Available" : (cardRoot.connectedDeviceName !== "" ? cardRoot.connectedDeviceName : (cardRoot.isPowered ? "Bluetooth Enabled" : "Bluetooth Disabled"))
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontMicro)
                        color: cardRoot.connectedDeviceName !== "" ? Config.accent : Config.textMuted
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                Rectangle {
                    implicitWidth: 36
                    implicitHeight: 36
                    radius: 18
                    Layout.alignment: Qt.AlignVCenter
                    visible: cardRoot.isPowered && cardRoot.hasHardware
                    color: scanHover.hovered ? Qt.rgba(255, 255, 255, 0.15) : Qt.rgba(255, 255, 255, 0.08)
                    border.width: 2
                    border.color: scanHover.hovered ? Config.accent : Qt.rgba(255, 255, 255, 0.12)
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    Text {
                        id: scanIconText
                        anchors.centerIn: parent
                        text: "refresh"
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 18
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                        color: scanHover.hovered ? Config.accent : Config.textMuted

                        RotationAnimator {
                            target: scanIconText
                            from: 0; to: 360; duration: 1000
                            loops: Animation.Infinite
                            running: cardRoot.isScanning
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: cardRoot.execTriggerScan()
                    }
                    HoverHandler { id: scanHover }
                }

                Rectangle {
                    implicitWidth: 36
                    implicitHeight: 36
                    radius: 18
                    Layout.alignment: Qt.AlignVCenter
                    visible: cardRoot.hasHardware
                    color: cardRoot.isPowered 
                        ? (pwrHover.hovered ? Qt.lighter(Config.accent, 1.1) : Config.accent)
                        : (pwrHover.hovered ? Qt.rgba(255, 255, 255, 0.15) : Qt.rgba(255, 255, 255, 0.08))
                    border.width: 2
                    border.color: cardRoot.isPowered
                        ? (pwrHover.hovered ? Qt.lighter(Config.accent, 1.1) : Config.accent)
                        : Qt.rgba(255, 255, 255, 0.12)
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: cardRoot.isPowered ? "bluetooth" : "bluetooth_disabled"
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 18
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                        color: cardRoot.isPowered ? Config.bgBase : Config.textMuted
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: cardRoot.execTogglePower(!cardRoot.isPowered)
                    }
                    HoverHandler { id: pwrHover }
                }
            }

            Rectangle {
                id: btDividerLine
                anchors.top: btHeaderRow.bottom
                anchors.topMargin: 12
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: Qt.rgba(255, 255, 255, 0.08)
            }

            Item {
                anchors.top: btDividerLine.bottom
                anchors.topMargin: 12
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 12
                    visible: cardRoot.hasHardware && cardRoot.isPowered && btModel.count > 0

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: "DEVICES"
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontMicro)
                            font.bold: true
                            color: Config.textMuted
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: cardRoot.isScanning ? "Scanning..." : (btModel.count + " available")
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontMicro)
                            color: cardRoot.isScanning ? Config.accent : Config.textMuted
                        }
                    }

                    ListView {
                        id: fullBtListView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        model: btModel
                        spacing: 6

                        delegate: Rectangle {
                            id: devDelegate
                            property bool isExpanded: cardRoot.expandedMac === model.mac
                            property bool isConnecting: cardRoot.connectingMac === model.mac

                            width: fullBtListView.width
                            implicitHeight: isExpanded ? devDelegateLayout.implicitHeight + 18 : 50
                            radius: Config.cornerRadius * 0.5
                            clip: true

                            color: model.connected 
                                ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.15) 
                                : (devHover.hovered ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(0, 0, 0, 0.2))

                            border.width: model.connected ? 2 : 0
                            border.color: model.connected ? Config.accent : "transparent"

                            Behavior on implicitHeight { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            ColumnLayout {
                                id: devDelegateLayout
                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.topMargin: 9
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 8

                                Item {
                                    Layout.fillWidth: true
                                    implicitHeight: 32

                                    RowLayout {
                                        anchors.fill: parent
                                        Layout.alignment: Qt.AlignVCenter
                                        spacing: 10

                                        Rectangle {
                                            implicitWidth: 32
                                            implicitHeight: 32
                                            radius: 16
                                            Layout.alignment: Qt.AlignVCenter
                                            color: model.connected 
                                                ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.25)
                                                : Qt.rgba(255, 255, 255, 0.06)

                                            Text {
                                                anchors.centerIn: parent
                                                text: cardRoot.getDeviceIcon(model.name)
                                                font.family: "Material Symbols Outlined"
                                                font.pixelSize: 17
                                                verticalAlignment: Text.AlignVCenter
                                                horizontalAlignment: Text.AlignHCenter
                                                color: model.connected ? Config.accent : Config.textMuted
                                            }
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            Layout.alignment: Qt.AlignVCenter
                                            spacing: 2

                                            Text {
                                                text: model.name
                                                color: model.connected ? Config.accent : Config.textMain
                                                font.family: Config.sysFont
                                                font.pixelSize: Config.size(Config.fontCaption)
                                                font.bold: model.connected
                                                verticalAlignment: Text.AlignVCenter
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }

                                            Text {
                                                text: isConnecting ? "Connecting..." : (model.connected ? "Connected" : (model.paired ? "Paired" : "Available"))
                                                color: model.connected ? Config.accent : Config.textMuted
                                                font.family: Config.sysFont
                                                font.pixelSize: Config.size(Config.fontMicro)
                                                verticalAlignment: Text.AlignVCenter
                                                elide: Text.ElideRight
                                                Layout.fillWidth: true
                                            }
                                        }

                                        Text {
                                            text: isExpanded ? "expand_less" : "expand_more"
                                            font.family: "Material Symbols Outlined"
                                            font.pixelSize: 18
                                            verticalAlignment: Text.AlignVCenter
                                            horizontalAlignment: Text.AlignHCenter
                                            color: Config.textMuted
                                            Layout.alignment: Qt.AlignVCenter
                                        }
                                    }

                                    TapHandler {
                                        onTapped: {
                                            cardRoot.expandedMac = (cardRoot.expandedMac === model.mac ? "" : model.mac)
                                        }
                                    }
                                }

                                Item {
                                    id: actionRowContainer
                                    Layout.fillWidth: true
                                    implicitHeight: isExpanded ? actionLayout.implicitHeight : 0
                                    visible: implicitHeight > 0 || opacity > 0
                                    opacity: isExpanded ? 1.0 : 0.0
                                    clip: true

                                    Behavior on implicitHeight { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                    Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                                    RowLayout {
                                        id: actionLayout
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.top: parent.top
                                        spacing: 8

                                        Rectangle {
                                            Layout.fillWidth: true
                                            implicitHeight: 32
                                            radius: 8
                                            color: connBtnMouse.containsMouse 
                                                ? (model.connected ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.2) : Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.85)) 
                                                : (model.connected ? Qt.rgba(255, 255, 255, 0.08) : Config.accent)
                                            border.width: 2
                                            border.color: model.connected ? (connBtnMouse.containsMouse ? Config.accent : Qt.rgba(255, 255, 255, 0.12)) : Config.accent
                                            Behavior on color { ColorAnimation { duration: 150 } }
                                            Behavior on border.color { ColorAnimation { duration: 150 } }

                                            RowLayout {
                                                anchors.centerIn: parent
                                                spacing: 5
                                                Text {
                                                    text: model.connected ? "link_off" : "login"
                                                    font.family: "Material Symbols Outlined"
                                                    font.pixelSize: 14
                                                    verticalAlignment: Text.AlignVCenter
                                                    horizontalAlignment: Text.AlignHCenter
                                                    color: model.connected ? (connBtnMouse.containsMouse ? Config.accent : Config.textMain) : Config.bgBase
                                                    visible: !isConnecting
                                                }
                                                Text {
                                                    text: isConnecting ? "Connecting..." : (model.connected ? "Disconnect" : (model.paired ? "Connect" : "Pair & Connect"))
                                                    color: model.connected ? (connBtnMouse.containsMouse ? Config.accent : Config.textMain) : Config.bgBase
                                                    font.family: Config.sysFont
                                                    font.pixelSize: Config.size(Config.fontMicro)
                                                    font.bold: true
                                                    verticalAlignment: Text.AlignVCenter
                                                }
                                            }

                                            MouseArea {
                                                id: connBtnMouse
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                hoverEnabled: true
                                                onClicked: {
                                                    if (isConnecting || !cardRoot.hasHardware) return
                                                    if (model.connected) cardRoot.reqDisconnectDevice(model.mac)
                                                    else if (model.paired) cardRoot.reqConnectDevice(model.mac)
                                                    else cardRoot.reqPairDevice(model.mac)
                                                }
                                            }
                                        }

                                        Rectangle {
                                            Layout.fillWidth: true
                                            implicitHeight: 32
                                            radius: 8
                                            visible: model.paired || model.connected
                                            color: forgetBtnMouse.containsMouse ? Qt.rgba(255, 255, 255, 0.12) : Qt.rgba(255, 255, 255, 0.06)
                                            border.width: 2
                                            border.color: forgetBtnMouse.containsMouse ? Config.accent : Qt.rgba(255, 255, 255, 0.1)
                                            Behavior on color { ColorAnimation { duration: 150 } }
                                            Behavior on border.color { ColorAnimation { duration: 150 } }

                                            RowLayout {
                                                anchors.centerIn: parent
                                                spacing: 5
                                                Text {
                                                    text: "delete_outline"
                                                    font.family: "Material Symbols Outlined"
                                                    font.pixelSize: 14
                                                    verticalAlignment: Text.AlignVCenter
                                                    horizontalAlignment: Text.AlignHCenter
                                                    color: forgetBtnMouse.containsMouse ? Config.accent : Config.textMuted
                                                }
                                                Text {
                                                    text: "Forget"
                                                    color: forgetBtnMouse.containsMouse ? Config.accent : Config.textMuted
                                                    font.family: Config.sysFont
                                                    font.pixelSize: Config.size(Config.fontMicro)
                                                    font.bold: true
                                                    verticalAlignment: Text.AlignVCenter
                                                }
                                            }

                                            MouseArea {
                                                id: forgetBtnMouse
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                hoverEnabled: true
                                                onClicked: {
                                                    if (!cardRoot.hasHardware) return
                                                    cardRoot.reqRemoveDevice(model.mac)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            HoverHandler { id: devHover }
                        }
                    }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 12
                    visible: cardRoot.hasHardware && cardRoot.isPowered && btModel.count === 0

                    Text {
                        text: "bluetooth_searching"
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 48
                        color: Config.accent
                        opacity: 0.5
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: "No Bluetooth Devices Found"
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontCaption)
                        font.bold: true
                        color: Config.textMain
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: "Ensure your Bluetooth device is turned on and in pairing mode."
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontMicro)
                        color: Config.textMuted
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                        Layout.maximumWidth: 260
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Rectangle {
                        implicitWidth: 150
                        implicitHeight: 34
                        radius: 17
                        color: scanEmptyHover.hovered ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.85) : Config.accent
                        border.width: 2
                        border.color: Config.accent
                        Layout.alignment: Qt.AlignHCenter
                        Behavior on color { ColorAnimation { duration: 150 } }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                text: "refresh"
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: 16
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                                color: Config.bgBase
                            }
                            Text {
                                text: cardRoot.isScanning ? "Scanning..." : "Scan Devices"
                                font.family: Config.sysFont
                                font.pixelSize: Config.size(Config.fontMicro)
                                font.bold: true
                                verticalAlignment: Text.AlignVCenter
                                color: Config.bgBase
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: cardRoot.execTriggerScan()
                        }
                        HoverHandler { id: scanEmptyHover }
                    }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 12
                    visible: cardRoot.hasHardware && !cardRoot.isPowered

                    Text {
                        text: "bluetooth_disabled"
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 48
                        color: Config.textMuted
                        opacity: 0.5
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: "Bluetooth is Disabled"
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontCaption)
                        font.bold: true
                        color: Config.textMain
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: "Turn on Bluetooth to discover and connect to nearby devices."
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontMicro)
                        color: Config.textMuted
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                        Layout.maximumWidth: 260
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Rectangle {
                        implicitWidth: 150
                        implicitHeight: 34
                        radius: 17
                        color: pwrOffHover.hovered ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.85) : Config.accent
                        border.width: 2
                        border.color: Config.accent
                        Layout.alignment: Qt.AlignHCenter
                        Behavior on color { ColorAnimation { duration: 150 } }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                text: "bluetooth"
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: 16
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                                color: Config.bgBase
                            }
                            Text {
                                text: "Turn On Bluetooth"
                                font.family: Config.sysFont
                                font.pixelSize: Config.size(Config.fontMicro)
                                font.bold: true
                                verticalAlignment: Text.AlignVCenter
                                color: Config.bgBase
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: cardRoot.execTogglePower(true)
                        }
                        HoverHandler { id: pwrOffHover }
                    }
                }
            }
        }
    }

    function execTogglePower(turnOn) {
        if (!cardRoot.hasHardware) return
        cardRoot.isPowered = turnOn
        toggleBtProc.command = ["fish", "-c", `bluetoothctl power ${turnOn ? "on" : "off"}`]
        toggleBtProc.running = true
    }

    function execTriggerScan() {
        if (cardRoot.hasHardware && cardRoot.isPowered && !cardRoot.isScanning) {
            scanBtProc.startScan()
        }
    }

    function reqConnectDevice(mac) { if (cardRoot.hasHardware) connectBtProc.connectDevice(mac) }
    function reqDisconnectDevice(mac) { if (cardRoot.hasHardware) disconnectBtProc.disconnect(mac) }
    function reqPairDevice(mac) { if (cardRoot.hasHardware) pairBtProc.pairDevice(mac) }
    function reqRemoveDevice(mac) { if (cardRoot.hasHardware) removeBtProc.removeDevice(mac) }

    Timer {
        interval: 2000
        running: cardRoot.visible && cardRoot.hasHardware && cardRoot.isPowered && (cardHover.hovered || cardRoot.connectedDeviceName !== "" || cardRoot.panelExpanded)
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!fetchBtDevicesProc.running && !toggleBtProc.running) {
                fetchBtDevicesProc.running = true
            }
        }
    }

    Process { id: toggleBtProc; running: false; onExited: fetchBtStatusProc.running = true }
    Process {
        id: scanBtProc; running: false
        function startScan() {
            cardRoot.isScanning = true
            command = ["fish", "-c", "bluetoothctl --timeout 6 scan on"]
            running = true
        }
        onExited: {
            cardRoot.isScanning = false
            fetchBtStatusProc.running = true
        }
    }
    Process {
        id: connectBtProc; running: false
        function connectDevice(mac) {
            cardRoot.connectingMac = mac
            command = ["fish", "-c", `bluetoothctl connect '${mac}'`]
            running = true
        }
        onExited: {
            cardRoot.connectingMac = ""
            fetchBtStatusProc.running = true
        }
    }
    Process {
        id: disconnectBtProc; running: false
        function disconnect(mac) {
            command = ["fish", "-c", `bluetoothctl disconnect '${mac}'`]
            running = true
        }
        onExited: fetchBtStatusProc.running = true
    }
    Process {
        id: pairBtProc; running: false
        function pairDevice(mac) {
            cardRoot.connectingMac = mac
            command = ["fish", "-c", `bluetoothctl pair '${mac}'; bluetoothctl trust '${mac}'; bluetoothctl connect '${mac}'`]
            running = true
        }
        onExited: {
            cardRoot.connectingMac = ""
            fetchBtStatusProc.running = true
        }
    }

    Process {
        id: removeBtProc; running: false
        function removeDevice(mac) {
            command = ["fish", "-c", `bluetoothctl disconnect '${mac}'; bluetoothctl untrust '${mac}'; bluetoothctl remove '${mac}'`]
            running = true
        }
        onExited: fetchBtStatusProc.running = true
    }

    Process {
        id: fetchBtDevicesProc
        command: ["fish", "-c", "for dev in (bluetoothctl devices); set mac (string match -r '([0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}:[0-9A-Fa-f]{2}:[0-9A-Fa-f]{2})' $dev)[1]; if test -n '$mac'; bluetoothctl info $mac; echo '---DEV_END---'; end; end"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let chunks = this.text.trim().split("---DEV_END---")
                let newResults = []
                let seenMacs = {}
                let connectedNames = []

                for (let i = 0; i < chunks.length; i++) {
                    let text = chunks[i].trim()
                    if (!text) continue

                    let macMatch = text.match(/Device ([0-9A-FA-f:]+)/)
                    if (!macMatch) continue
                    let mac = macMatch[1]

                    if (seenMacs[mac]) continue
                    seenMacs[mac] = true

                    let nameMatch = text.match(/Name: (.*)/) || text.match(/Alias: (.*)/)
                    let name = nameMatch ? nameMatch[1].trim() : mac
                    let isConn = text.includes("Connected: yes")

                    if (isConn) {
                        connectedNames.push(name)
                    }

                    newResults.push({
                        mac: mac,
                        name: name,
                        connected: isConn,
                        paired: text.includes("Paired: yes")
                    })
                }

                cardRoot.connectedDeviceName = connectedNames.length > 0 ? connectedNames.join(", ") : ""

                let existingMap = {}
                for (let idx = 0; idx < btModel.count; idx++) {
                    existingMap[btModel.get(idx).mac] = idx
                }

                let freshMap = {}
                let toAppend = []

                for (let k = 0; k < newResults.length; k++) {
                    let item = newResults[k]
                    freshMap[item.mac] = true

                    if (item.mac in existingMap) {
                        let tIndex = existingMap[item.mac]
                        let cur = btModel.get(tIndex)
                        if (cur.name !== item.name) btModel.setProperty(tIndex, "name", item.name)
                        if (cur.connected !== item.connected) btModel.setProperty(tIndex, "connected", item.connected)
                        if (cur.paired !== item.paired) btModel.setProperty(tIndex, "paired", item.paired)
                    } else {
                        toAppend.push(item)
                    }
                }

                for (let a = 0; a < toAppend.length; a++) {
                    btModel.append(toAppend[a])
                }

                for (let r = btModel.count - 1; r >= 0; r--) {
                    if (!freshMap[btModel.get(r).mac]) btModel.remove(r)
                }
            }
        }
    }

    Process {
        id: fetchBtStatusProc
        command: ["fish", "-c", "bluetoothctl show"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (toggleBtProc.running) return

                let text = this.text
                if (!cardRoot.hasHardware || !text || text.includes("No default controller available")) {
                    cardRoot.isPowered = false
                    cardRoot.connectedDeviceName = ""
                    btModel.clear()
                    return
                }

                if (text.includes("Powered: yes")) {
                    cardRoot.isPowered = true
                    fetchBtDevicesProc.running = true
                } else if (text.includes("Powered: no")) {
                    cardRoot.isPowered = false
                    cardRoot.connectedDeviceName = ""
                    btModel.clear()
                }
            }
        }
    }

    Component.onCompleted: fetchBtStatusProc.running = true
}