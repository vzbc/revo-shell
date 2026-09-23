pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../../"
import "../shared"

Item {
    id: root

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        PanelHeader {
            Layout.fillWidth: true
            breadcrumb: I18n.t("wifi.breadcrumb")
            title: I18n.t("wifi.title")
            rightActions: Component {
                ToggleSwitch {
                    visible: WifiService.available
                    checked: WifiService.enabled
                    onToggled: WifiService.setEnabled(!WifiService.enabled)
                }
            }
        }

        Flickable {
            id: flick
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: col.implicitHeight + UIScale.spacingMd
            clip: true
            flickableDirection: Flickable.VerticalFlick

            ColumnLayout {
                id: col
                width: flick.width
                spacing: 0

                Item {
                    implicitHeight: UIScale.spacingMd
                }

                // No adapter empty state
                Text {
                    text: I18n.t("wifi.noAdapterFound")
                    color: Colors.textDim
                    font.pixelSize: UIScale.fontSmall
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                    Layout.topMargin: UIScale.spacingLg
                    visible: !WifiService.available
                }

                // Ethernet card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                    Layout.bottomMargin: UIScale.spacingMd
                    visible: WifiService.onEthernet
                    implicitHeight: Math.round(72 * UIScale.value)
                    radius: Math.round(18 * UIScale.value)
                    border.color: Colors.withAlpha(Colors.accent, 0.22)
                    border.width: 1
                    clip: true

                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop {
                            position: 0
                            color: Colors.withAlpha(Colors.accent, 0.13)
                        }
                        GradientStop {
                            position: 1
                            color: Colors.withAlpha(Colors.text, 0.01)
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Math.round(22 * UIScale.value)
                        anchors.rightMargin: Math.round(22 * UIScale.value)
                        spacing: Math.round(18 * UIScale.value)

                        Rectangle {
                            implicitWidth: Math.round(44 * UIScale.value)
                            implicitHeight: Math.round(44 * UIScale.value)
                            radius: UIScale.radiusLg
                            color: Colors.withAlpha(Colors.accent, 0.14)
                            border.color: Colors.withAlpha(Colors.accent, 0.28)
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "󰈀"
                                font.pixelSize: Math.round(22 * UIScale.value)
                                color: Colors.accent
                            }
                        }

                        Column {
                            Layout.fillWidth: true
                            spacing: Math.round(3 * UIScale.value)
                            Text {
                                text: I18n.t("wifi.ethernet")
                                color: Colors.text
                                font.pixelSize: Math.round(16 * UIScale.value)
                                font.weight: Font.ExtraBold
                            }
                            Text {
                                text: I18n.t("wifi.connected")
                                color: Colors.accent
                                font.pixelSize: UIScale.fontSmall
                            }
                        }
                    }
                }

                // Wi-Fi off notice
                Text {
                    text: I18n.t("wifi.off")
                    color: Colors.textDim
                    font.pixelSize: UIScale.fontSmall
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                    Layout.topMargin: WifiService.onEthernet ? UIScale.spacingMd : UIScale.spacingLg
                    visible: WifiService.available && !WifiService.enabled
                }

                // Connected WiFi hero card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                    Layout.bottomMargin: UIScale.spacingMd
                    visible: WifiService.available && WifiService.enabled && WifiService.connected
                    implicitHeight: Math.round(96 * UIScale.value)
                    radius: Math.round(18 * UIScale.value)
                    border.color: Colors.withAlpha(Colors.accent, 0.22)
                    border.width: 1
                    clip: true

                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop {
                            position: 0
                            color: Colors.withAlpha(Colors.accent, 0.13)
                        }
                        GradientStop {
                            position: 1
                            color: Colors.withAlpha(Colors.text, 0.01)
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Math.round(22 * UIScale.value)
                        anchors.rightMargin: Math.round(22 * UIScale.value)
                        spacing: Math.round(18 * UIScale.value)

                        // Signal icon box
                        Rectangle {
                            implicitWidth: Math.round(56 * UIScale.value)
                            implicitHeight: Math.round(56 * UIScale.value)
                            radius: UIScale.radiusLg
                            color: Colors.withAlpha(Colors.accent, 0.14)
                            border.color: Colors.withAlpha(Colors.accent, 0.28)
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: WifiService.signalIcon(WifiService.signalStrength)
                                font.pixelSize: Math.round(26 * UIScale.value)
                                color: Colors.accent
                            }
                        }

                        // SSID + details
                        Column {
                            Layout.fillWidth: true
                            spacing: UIScale.spacingSm

                            Text {
                                text: WifiService.ssid
                                color: Colors.text
                                font.pixelSize: Math.round(20 * UIScale.value)
                                font.weight: Font.ExtraBold
                                elide: Text.ElideRight
                                width: parent.width
                            }

                            // Signal bars + percentage
                            Row {
                                spacing: UIScale.spacingMd

                                // Bars visual: Item wrapper so anchors.bottom works inside Row
                                Row {
                                    spacing: Math.round(3 * UIScale.value)
                                    height: Math.round(17 * UIScale.value)
                                    anchors.verticalCenter: parent.verticalCenter

                                    Repeater {
                                        model: 4
                                        Item {
                                            id: barWrap
                                            required property int index
                                            width: Math.round(4 * UIScale.value)
                                            height: parent.height

                                            Rectangle {
                                                width: parent.width
                                                height: Math.round((5 + barWrap.index * 4) * UIScale.value)
                                                radius: Math.round(2 * UIScale.value)
                                                anchors.bottom: parent.bottom
                                                color: (Math.floor(WifiService.signalStrength * 4) > barWrap.index) ? Colors.accent : Colors.withAlpha(Colors.text, 0.18)
                                                Behavior on color {
                                                    ColorAnimation {
                                                        duration: Anim.slow
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: Math.round(WifiService.signalStrength * 100) + "%"
                                    color: Colors.textDim
                                    font.pixelSize: UIScale.fontCaption
                                    font.family: "monospace"
                                }

                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    height: Math.round(18 * UIScale.value)
                                    width: secChipTxt.implicitWidth + Math.round(12 * UIScale.value)
                                    radius: UIScale.radiusSm
                                    color: Colors.withAlpha(Colors.accent, 0.1)
                                    border.color: Colors.withAlpha(Colors.accent, 0.2)
                                    border.width: 1
                                    visible: WifiService.activeNetwork !== null && WifiService.needsPsk(WifiService.activeNetwork)

                                    Text {
                                        id: secChipTxt
                                        anchors.centerIn: parent
                                        text: I18n.t("wifi.secured")
                                        color: Colors.accent
                                        font.pixelSize: UIScale.fontTiny
                                        font.weight: Font.Bold
                                        font.family: "monospace"
                                    }
                                }
                            }
                        }

                        // Disconnect button
                        Rectangle {
                            implicitWidth: heroDiscRow.implicitWidth + Math.round(28 * UIScale.value)
                            implicitHeight: Math.round(36 * UIScale.value)
                            radius: Math.round(11 * UIScale.value)
                            color: heroDiscHov.hovered ? Colors.withAlpha(Colors.text, 0.08) : Colors.withAlpha(Colors.text, 0.05)
                            border.color: Colors.withAlpha(Colors.text, 0.1)
                            border.width: 1
                            Behavior on color {
                                ColorAnimation {
                                    duration: Anim.fast
                                }
                            }

                            Row {
                                id: heroDiscRow
                                anchors.centerIn: parent
                                spacing: Math.round(6 * UIScale.value)

                                Text {
                                    text: ""
                                    font.family: "Material Icons"
                                    font.pixelSize: UIScale.fontLead
                                    color: Colors.textDim
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: I18n.t("wifi.disconnect")
                                    color: Colors.text
                                    font.pixelSize: UIScale.fontBody
                                    font.weight: Font.Bold
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            HoverHandler {
                                id: heroDiscHov
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: WifiService.activeNetwork.disconnect()
                            }
                        }
                    }
                }

                // Network list header
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                    Layout.bottomMargin: UIScale.spacingXs
                    visible: WifiService.available && WifiService.enabled

                    SectionLabel {
                        text: I18n.t("wifi.availableNetworksSection")
                        Layout.fillWidth: true
                    }
                    Text {
                        text: WifiService.networks.length + ""
                        color: Colors.muted
                        font.pixelSize: UIScale.fontCaption
                        font.family: "monospace"
                    }
                }

                // Network rows
                Repeater {
                    model: WifiService.available && WifiService.enabled ? WifiService.networks : []

                    delegate: Item {
                        id: netItem
                        required property var modelData
                        required property int index

                        readonly property bool isConnected: modelData.connected
                        readonly property bool isPending: pskFooter.pendingNetwork === modelData
                        readonly property bool isChanging: modelData.stateChanging

                        Layout.fillWidth: true
                        Layout.leftMargin: UIScale.panelPad
                        Layout.rightMargin: UIScale.panelPad
                        Layout.bottomMargin: UIScale.spacingSm
                        implicitHeight: netCard.implicitHeight

                        Connections {
                            target: netItem.modelData
                            function onConnectionFailed(reason) {
                                pskFooter.handleConnectionFailed(netItem.modelData);
                            }
                        }

                        Rectangle {
                            id: netCard
                            anchors.left: parent.left
                            anchors.right: parent.right
                            radius: UIScale.radiusMd
                            color: netItem.isConnected ? Colors.withAlpha(Colors.accent, 0.07) : Colors.surface
                            border.color: netItem.isConnected ? Colors.withAlpha(Colors.accent, 0.25) : Colors.withAlpha(Colors.text, 0.07)
                            border.width: 1
                            implicitHeight: cardInner.implicitHeight + UIScale.spacingMd * 2
                            Behavior on color {
                                ColorAnimation {
                                    duration: Anim.fast
                                }
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: parent.radius
                                color: Colors.withAlpha(Colors.text, 0.025)
                                opacity: cardHov.hovered ? 1 : 0
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: Anim.fast
                                    }
                                }
                            }

                            RowLayout {
                                id: cardInner
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    top: parent.top
                                    margins: UIScale.spacingMd
                                }
                                spacing: UIScale.spacingSm

                                // Signal icon
                                Rectangle {
                                    implicitWidth: Math.round(36 * UIScale.value)
                                    implicitHeight: Math.round(36 * UIScale.value)
                                    radius: UIScale.radiusSm
                                    color: netItem.isConnected ? Colors.withAlpha(Colors.accent, 0.15) : Colors.surfaceHigh
                                    Behavior on color {
                                        ColorAnimation {
                                            duration: Anim.fast
                                        }
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: WifiService.signalIcon(netItem.modelData.signalStrength)
                                        font.pixelSize: Math.round(18 * UIScale.value)
                                        color: netItem.isConnected ? Colors.accent : Colors.textDim
                                        Behavior on color {
                                            ColorAnimation {
                                                duration: Anim.fast
                                            }
                                        }
                                    }
                                }

                                // Name + status
                                Column {
                                    Layout.fillWidth: true
                                    spacing: Math.round(3 * UIScale.value)

                                    Text {
                                        text: netItem.modelData.name
                                        color: Colors.text
                                        font.pixelSize: UIScale.fontBody
                                        font.weight: netItem.isConnected ? Font.DemiBold : Font.Normal
                                        elide: Text.ElideRight
                                        width: parent.width
                                    }

                                    Row {
                                        spacing: Math.round(5 * UIScale.value)

                                        Rectangle {
                                            width: Math.round(6 * UIScale.value)
                                            height: Math.round(6 * UIScale.value)
                                            radius: width / 2
                                            anchors.verticalCenter: parent.verticalCenter
                                            color: netItem.isConnected ? Colors.accent : Colors.withAlpha(Colors.text, 0.18)
                                            Behavior on color {
                                                ColorAnimation {
                                                    duration: Anim.fast
                                                }
                                            }
                                        }

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: {
                                                if (netItem.isConnected)
                                                    return I18n.t("wifi.connectedWithPercent", [Math.round(netItem.modelData.signalStrength * 100)]);
                                                if (netItem.modelData.known)
                                                    return I18n.t("wifi.savedStatus");
                                                if (WifiService.needsPsk(netItem.modelData))
                                                    return I18n.t("wifi.secured");
                                                return I18n.t("wifi.open");
                                            }
                                            color: netItem.isConnected ? Colors.accent : Colors.textDim
                                            font.pixelSize: UIScale.fontSmall
                                            Behavior on color {
                                                ColorAnimation {
                                                    duration: Anim.fast
                                                }
                                            }
                                        }
                                    }
                                }

                                // Action buttons
                                Row {
                                    spacing: Math.round(6 * UIScale.value)

                                    // Forget (known networks only, not currently connected)
                                    Rectangle {
                                        visible: netItem.modelData.known && !netItem.isConnected
                                        implicitWidth: forgetTxt.implicitWidth + Math.round(14 * UIScale.value)
                                        implicitHeight: Math.round(30 * UIScale.value)
                                        radius: UIScale.radiusSm
                                        color: forgetHov.hovered ? Colors.withAlpha("#e05c5c", 0.18) : Colors.withAlpha("#e05c5c", 0.07)
                                        Behavior on color {
                                            ColorAnimation {
                                                duration: Anim.fast
                                            }
                                        }

                                        Text {
                                            id: forgetTxt
                                            anchors.centerIn: parent
                                            text: I18n.t("wifi.forget")
                                            color: forgetHov.hovered ? "#e05c5c" : Colors.withAlpha("#e05c5c", 0.5)
                                            font.pixelSize: UIScale.fontSmall
                                            font.weight: Font.DemiBold
                                            Behavior on color {
                                                ColorAnimation {
                                                    duration: Anim.fast
                                                }
                                            }
                                        }

                                        HoverHandler {
                                            id: forgetHov
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: netItem.modelData.forget()
                                        }
                                    }

                                    // Connect / Disconnect
                                    Rectangle {
                                        visible: !netItem.isChanging
                                        implicitWidth: Math.max(connTxt.implicitWidth + Math.round(16 * UIScale.value), Math.round(42 * UIScale.value))
                                        implicitHeight: Math.round(30 * UIScale.value)
                                        radius: UIScale.radiusSm
                                        color: connHov.hovered ? (netItem.isConnected ? Colors.withAlpha("#e05c5c", 0.22) : (netItem.isPending ? Colors.withAlpha(Colors.text, 0.1) : Colors.withAlpha(Colors.accent, 0.22))) : (netItem.isConnected ? Colors.withAlpha("#e05c5c", 0.1) : (netItem.isPending ? Colors.withAlpha(Colors.text, 0.05) : Colors.withAlpha(Colors.accent, 0.1)))
                                        Behavior on color {
                                            ColorAnimation {
                                                duration: Anim.fast
                                            }
                                        }

                                        Text {
                                            id: connTxt
                                            anchors.centerIn: parent
                                            text: netItem.isConnected ? I18n.t("wifi.disconnect") : (netItem.isPending ? I18n.t("common.cancel") : I18n.t("wifi.connect"))
                                            color: netItem.isConnected ? "#e05c5c" : (netItem.isPending ? Colors.textDim : Colors.accent)
                                            font.pixelSize: UIScale.fontSmall
                                            font.weight: Font.DemiBold
                                            Behavior on color {
                                                ColorAnimation {
                                                    duration: Anim.fast
                                                }
                                            }
                                        }

                                        HoverHandler {
                                            id: connHov
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (netItem.isPending) {
                                                    pskFooter.pendingNetwork = null;
                                                    pskFooter.errorMsg = "";
                                                } else {
                                                    pskFooter.connectNetwork(netItem.modelData);
                                                }
                                            }
                                        }
                                    }

                                    // Spinner
                                    Text {
                                        visible: netItem.isChanging
                                        text: "󰑓"
                                        font.pixelSize: Math.round(14 * UIScale.value)
                                        color: Colors.accent
                                        anchors.verticalCenter: parent.verticalCenter
                                        RotationAnimator on rotation {
                                            running: netItem.isChanging
                                            from: 0
                                            to: 360
                                            duration: 800
                                            loops: Animation.Infinite
                                        }
                                    }
                                }
                            }

                            HoverHandler {
                                id: cardHov
                            }
                        }
                    }
                }

                Item {
                    implicitHeight: UIScale.spacingMd
                }
            }
        }

        WifiPskFooter {
            id: pskFooter
            Layout.fillWidth: true
            sidePadding: UIScale.panelPad
        }
    }
}
