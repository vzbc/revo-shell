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

        // Header
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: Math.round(52 * UIScale.value)
            color: Colors.surfaceHigh
            topLeftRadius: UIScale.radiusLg
            topRightRadius: UIScale.radiusLg

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: UIScale.spacingMd
                anchors.rightMargin: UIScale.spacingMd

                Text {
                    text: WifiService.barIcon()
                    font.pixelSize: Math.round(20 * UIScale.value)
                    color: (WifiService.connected || WifiService.onEthernet) ? Colors.accent : Colors.textDim
                    Behavior on color {
                        ColorAnimation {
                            duration: Anim.fast
                        }
                    }
                }

                Text {
                    text: I18n.t("wifi.networkHeader")
                    color: Colors.text
                    font.pixelSize: UIScale.fontLead
                    font.weight: Font.DemiBold
                    leftPadding: UIScale.spacingXs
                    Layout.fillWidth: true
                }

                ToggleSwitch {
                    visible: WifiService.available
                    checked: WifiService.enabled
                    onToggled: WifiService.setEnabled(!WifiService.enabled)
                }
            }
        }

        // Ethernet card
        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: UIScale.spacingMd
            Layout.rightMargin: UIScale.spacingMd
            Layout.topMargin: UIScale.spacingMd
            visible: WifiService.onEthernet
            implicitHeight: Math.round(54 * UIScale.value)
            radius: UIScale.radiusMd
            color: Colors.withAlpha(Colors.accent, 0.09)
            border.color: Colors.withAlpha(Colors.accent, 0.2)
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: UIScale.spacingMd
                anchors.rightMargin: UIScale.spacingMd
                spacing: UIScale.spacingSm

                Text {
                    text: "󰈀"
                    font.pixelSize: Math.round(22 * UIScale.value)
                    color: Colors.accent
                }

                Column {
                    Layout.fillWidth: true
                    spacing: Math.round(2 * UIScale.value)
                    Text {
                        text: I18n.t("wifi.ethernet")
                        color: Colors.text
                        font.pixelSize: UIScale.fontBody
                        font.weight: Font.DemiBold
                    }
                    Text {
                        text: I18n.t("wifi.connected")
                        color: Colors.accent
                        font.pixelSize: UIScale.fontSmall
                    }
                }
            }
        }

        // Connected WiFi card
        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: UIScale.spacingMd
            Layout.rightMargin: UIScale.spacingMd
            Layout.topMargin: UIScale.spacingMd
            Layout.bottomMargin: UIScale.spacingXs
            visible: WifiService.available && WifiService.enabled && WifiService.connected
            implicitHeight: Math.round(60 * UIScale.value)
            radius: UIScale.radiusMd
            color: Colors.withAlpha(Colors.accent, 0.09)
            border.color: Colors.withAlpha(Colors.accent, 0.2)
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: UIScale.spacingMd
                anchors.rightMargin: UIScale.spacingMd
                spacing: UIScale.spacingSm

                Text {
                    text: WifiService.signalIcon(WifiService.signalStrength)
                    font.pixelSize: Math.round(22 * UIScale.value)
                    color: Colors.accent
                }

                Column {
                    Layout.fillWidth: true
                    spacing: Math.round(2 * UIScale.value)
                    Text {
                        text: WifiService.ssid
                        color: Colors.text
                        font.pixelSize: UIScale.fontBody
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                        width: parent.width
                    }
                    Text {
                        text: I18n.t("wifi.connectedWithPercent", [Math.round(WifiService.signalStrength * 100)])
                        color: Colors.accent
                        font.pixelSize: UIScale.fontSmall
                    }
                }

                Rectangle {
                    implicitWidth: discTxt.implicitWidth + UIScale.spacingMd
                    implicitHeight: Math.round(28 * UIScale.value)
                    radius: UIScale.radiusSm
                    color: discHov.hovered ? Colors.withAlpha("#e05c5c", 0.22) : Colors.withAlpha("#e05c5c", 0.1)
                    Behavior on color {
                        ColorAnimation {
                            duration: Anim.fast
                        }
                    }

                    Text {
                        id: discTxt
                        anchors.centerIn: parent
                        text: I18n.t("wifi.disconnect")
                        color: "#e05c5c"
                        font.pixelSize: UIScale.fontSmall
                        font.weight: Font.DemiBold
                    }
                    HoverHandler {
                        id: discHov
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: WifiService.activeNetwork.disconnect()
                    }
                }
            }
        }

        // Body, always fills remaining space to avoid layout displacement
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Empty states
            Text {
                anchors.centerIn: parent
                text: I18n.t("wifi.noAdapterFound")
                color: Colors.muted
                font.pixelSize: UIScale.fontSmall
                visible: !WifiService.available
            }
            Text {
                anchors.centerIn: parent
                text: I18n.t("wifi.off")
                color: Colors.muted
                font.pixelSize: UIScale.fontSmall
                visible: WifiService.available && !WifiService.enabled
            }

            // Section label + network list when enabled
            SectionLabel {
                id: netHeader
                text: I18n.t("wifi.availableNetworksSection")
                leftPadding: UIScale.spacingMd
                anchors.top: parent.top
                anchors.topMargin: UIScale.spacingSm
                anchors.left: parent.left
                anchors.right: parent.right
                visible: WifiService.available && WifiService.enabled
            }

            Flickable {
                anchors.top: netHeader.bottom
                anchors.topMargin: UIScale.spacingXs
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                contentWidth: width
                contentHeight: netCol.implicitHeight
                clip: true
                flickableDirection: Flickable.VerticalFlick
                visible: WifiService.available && WifiService.enabled

                Column {
                    id: netCol
                    width: parent.width

                    Repeater {
                        model: WifiService.networks

                        delegate: Rectangle {
                            id: netRow
                            required property var modelData
                            required property int index

                            readonly property bool isConnected: modelData.connected
                            readonly property bool isPending: pskFooter.pendingNetwork === modelData
                            readonly property bool isChanging: modelData.stateChanging

                            width: parent.width
                            height: Math.round(44 * UIScale.value)
                            color: isConnected ? Colors.withAlpha(Colors.accent, 0.06) : (netHov.hovered ? Colors.withAlpha(Colors.text, 0.04) : "transparent")
                            Behavior on color {
                                ColorAnimation {
                                    duration: Anim.fast
                                }
                            }

                            Connections {
                                target: netRow.modelData
                                function onConnectionFailed(reason) {
                                    pskFooter.handleConnectionFailed(netRow.modelData);
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: UIScale.spacingMd
                                anchors.rightMargin: UIScale.spacingMd
                                spacing: UIScale.spacingSm

                                Text {
                                    text: WifiService.signalIcon(netRow.modelData.signalStrength)
                                    font.pixelSize: Math.round(18 * UIScale.value)
                                    color: netRow.isConnected ? Colors.accent : Colors.textDim
                                    Behavior on color {
                                        ColorAnimation {
                                            duration: Anim.fast
                                        }
                                    }
                                }

                                Text {
                                    text: netRow.modelData.name
                                    color: Colors.text
                                    font.pixelSize: UIScale.fontBody
                                    font.weight: netRow.isConnected ? Font.DemiBold : Font.Normal
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                Text {
                                    visible: netRow.modelData.known && !netRow.isConnected
                                    text: I18n.t("wifi.savedBadge")
                                    color: Colors.withAlpha(Colors.accent, 0.65)
                                    font.pixelSize: UIScale.fontTiny
                                    font.family: "monospace"
                                }

                                Text {
                                    visible: WifiService.needsPsk(netRow.modelData) && !netRow.modelData.known
                                    text: "󰌾"
                                    font.pixelSize: Math.round(11 * UIScale.value)
                                    color: Colors.muted
                                }

                                Rectangle {
                                    visible: !netRow.isChanging
                                    implicitWidth: Math.max(netBtnTxt.implicitWidth + UIScale.spacingMd, Math.round(56 * UIScale.value))
                                    implicitHeight: Math.round(26 * UIScale.value)
                                    radius: UIScale.radiusSm
                                    color: netBtnHov.hovered ? (netRow.isConnected ? Colors.withAlpha("#e05c5c", 0.22) : (netRow.isPending ? Colors.withAlpha(Colors.text, 0.1) : Colors.withAlpha(Colors.accent, 0.22))) : (netRow.isConnected ? Colors.withAlpha("#e05c5c", 0.1) : (netRow.isPending ? Colors.withAlpha(Colors.text, 0.05) : Colors.withAlpha(Colors.accent, 0.12)))
                                    Behavior on color {
                                        ColorAnimation {
                                            duration: Anim.fast
                                        }
                                    }

                                    Text {
                                        id: netBtnTxt
                                        anchors.centerIn: parent
                                        text: netRow.isConnected ? I18n.t("wifi.disconnect") : (netRow.isPending ? I18n.t("common.cancel") : I18n.t("wifi.connect"))
                                        color: netRow.isConnected ? "#e05c5c" : (netRow.isPending ? Colors.textDim : Colors.accent)
                                        font.pixelSize: UIScale.fontSmall
                                        font.weight: Font.DemiBold
                                        Behavior on color {
                                            ColorAnimation {
                                                duration: Anim.fast
                                            }
                                        }
                                    }

                                    HoverHandler {
                                        id: netBtnHov
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (netRow.isPending) {
                                                pskFooter.pendingNetwork = null;
                                                pskFooter.errorMsg = "";
                                            } else {
                                                pskFooter.connectNetwork(netRow.modelData);
                                            }
                                        }
                                    }
                                }

                                Text {
                                    visible: netRow.isChanging
                                    text: "󰑓"
                                    font.pixelSize: Math.round(14 * UIScale.value)
                                    color: Colors.accent
                                    RotationAnimator on rotation {
                                        running: netRow.isChanging
                                        from: 0
                                        to: 360
                                        duration: 800
                                        loops: Animation.Infinite
                                    }
                                }
                            }

                            HoverHandler {
                                id: netHov
                            }
                        }
                    }
                }
            }
        }

        WifiPskFooter {
            id: pskFooter
            Layout.fillWidth: true
            bottomRadius: UIScale.radiusLg
        }
    }
}
