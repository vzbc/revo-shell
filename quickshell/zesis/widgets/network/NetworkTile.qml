pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../"
import "../shared"

Item {
    id: root

    property string expandedHost: ""
    property string authUser: ""
    property string authPass: ""
    property bool authPassVisible: false
    onExpandedHostChanged: {
        authUser = NetworkService.systemUser;
        authPass = "";
        authPassVisible = false;
    }

    // background
    Rectangle {
        anchors.fill: parent
        radius: Math.round(12 * UIScale.value)
        topLeftRadius: 0
        topRightRadius: 0
        color: Colors.bg
        border.color: Colors.outline
        border.width: 1
    }

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: col.implicitHeight
        clip: true
        flickableDirection: Flickable.VerticalFlick

        ColumnLayout {
            id: col
            width: parent.width
            spacing: 0

            Item {
                implicitHeight: UIScale.spacingSm
            }

            WarningBanners {
                id: warnBanners
                Layout.fillWidth: true
                Layout.preferredHeight: warnBanners.implicitHeight
            }

            // CONNECTED section (smbnetfs)
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Math.round(2 * UIScale.value)
                visible: NetworkService.mountBackend === "smbnetfs" && NetworkService.smbnetfsConnected.length > 0

                Text {
                    text: I18n.t("network.connectedHeader")
                    color: Colors.textDim
                    font.pixelSize: UIScale.fontCaption
                    font.letterSpacing: 1.5
                    font.weight: Font.Medium
                    Layout.leftMargin: UIScale.spacingMd + Math.round(4 * UIScale.value)
                }

                Repeater {
                    model: ScriptModel {
                        values: NetworkService.smbnetfsConnected
                    }
                    delegate: Rectangle {
                        id: smbnetfsRowDelegate
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.leftMargin: UIScale.spacingMd
                        Layout.rightMargin: UIScale.spacingMd
                        implicitHeight: Math.round(40 * UIScale.value)
                        radius: UIScale.radiusMd
                        color: Colors.surface

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: UIScale.spacingMd
                            anchors.rightMargin: UIScale.spacingMd
                            spacing: UIScale.spacingSm

                            Rectangle {
                                implicitWidth: Math.round(7 * UIScale.value)
                                implicitHeight: Math.round(7 * UIScale.value)
                                radius: implicitWidth / 2
                                color: Colors.accent
                            }

                            Text {
                                text: smbnetfsRowDelegate.modelData
                                color: Colors.text
                                font.pixelSize: UIScale.fontSmall
                                font.weight: Font.DemiBold
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Rectangle {
                                implicitWidth: disconnectLabel.implicitWidth + UIScale.spacingSm * 2
                                implicitHeight: Math.round(24 * UIScale.value)
                                radius: Math.round(12 * UIScale.value)
                                color: disconnectMa.containsMouse ? Colors.withAlpha(Colors.accent, 0.2) : Colors.withAlpha(Colors.accent, 0.1)
                                Behavior on color {
                                    ColorAnimation {
                                        duration: Anim.fast
                                    }
                                }

                                Text {
                                    id: disconnectLabel
                                    anchors.centerIn: parent
                                    text: I18n.t("network.disconnectAction")
                                    color: Colors.accent
                                    font.pixelSize: UIScale.fontCaption
                                }

                                MouseArea {
                                    id: disconnectMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: NetworkService.disconnectSmbnetfs(smbnetfsRowDelegate.modelData)
                                }
                            }
                        }
                    }
                }

                Item {
                    implicitHeight: Math.round(4 * UIScale.value)
                }
                Divider {
                    Layout.leftMargin: UIScale.spacingMd
                    Layout.rightMargin: UIScale.spacingMd
                    color: Colors.withAlpha(Colors.accent, 0.1)
                }
                Item {
                    implicitHeight: Math.round(4 * UIScale.value)
                }
            }

            // MOUNTED section (mount.cifs)
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Math.round(2 * UIScale.value)
                visible: NetworkService.mountBackend === "mountcifs" && NetworkService.mounts.length > 0

                Text {
                    text: I18n.t("network.mountedHeader")
                    color: Colors.textDim
                    font.pixelSize: UIScale.fontCaption
                    font.letterSpacing: 1.5
                    font.weight: Font.Medium
                    Layout.leftMargin: UIScale.spacingMd + Math.round(4 * UIScale.value)
                }

                Repeater {
                    model: ScriptModel {
                        values: NetworkService.mounts
                    }
                    delegate: Rectangle {
                        id: mountRowDelegate
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.leftMargin: UIScale.spacingMd
                        Layout.rightMargin: UIScale.spacingMd
                        implicitHeight: Math.round(40 * UIScale.value)
                        radius: UIScale.radiusMd
                        color: Colors.surface

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: UIScale.spacingMd
                            anchors.rightMargin: UIScale.spacingMd
                            spacing: UIScale.spacingSm

                            Rectangle {
                                implicitWidth: Math.round(7 * UIScale.value)
                                implicitHeight: Math.round(7 * UIScale.value)
                                radius: implicitWidth / 2
                                color: Colors.accent
                            }

                            Text {
                                text: mountRowDelegate.modelData.displayName
                                color: Colors.text
                                font.pixelSize: UIScale.fontSmall
                                font.weight: Font.DemiBold
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Rectangle {
                                implicitWidth: unmountLabel.implicitWidth + UIScale.spacingSm * 2
                                implicitHeight: Math.round(24 * UIScale.value)
                                radius: Math.round(12 * UIScale.value)
                                color: unmountMa.containsMouse ? Colors.withAlpha(Colors.accent, 0.2) : Colors.withAlpha(Colors.accent, 0.1)
                                Behavior on color {
                                    ColorAnimation {
                                        duration: Anim.fast
                                    }
                                }

                                Text {
                                    id: unmountLabel
                                    anchors.centerIn: parent
                                    text: I18n.t("network.unmountAction")
                                    color: Colors.accent
                                    font.pixelSize: UIScale.fontCaption
                                }

                                MouseArea {
                                    id: unmountMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: NetworkService.unmount(mountRowDelegate.modelData.uri)
                                }
                            }
                        }
                    }
                }

                Item {
                    implicitHeight: Math.round(4 * UIScale.value)
                }
                Divider {
                    Layout.leftMargin: UIScale.spacingMd
                    Layout.rightMargin: UIScale.spacingMd
                    color: Colors.withAlpha(Colors.accent, 0.1)
                }
                Item {
                    implicitHeight: Math.round(4 * UIScale.value)
                }
            }

            // SERVERS header
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: UIScale.spacingMd + Math.round(4 * UIScale.value)
                Layout.rightMargin: UIScale.spacingMd

                Text {
                    text: I18n.t("network.serversHeader")
                    color: Colors.textDim
                    font.pixelSize: UIScale.fontCaption
                    font.letterSpacing: 1.5
                    font.weight: Font.Medium
                    Layout.fillWidth: true
                }

                Rectangle {
                    implicitWidth: Math.round(28 * UIScale.value)
                    implicitHeight: Math.round(28 * UIScale.value)
                    radius: Math.round(14 * UIScale.value)
                    color: scanMa.containsMouse ? Colors.withAlpha(Colors.accent, 0.15) : "transparent"
                    Behavior on color {
                        ColorAnimation {
                            duration: Anim.fast
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: ""
                        font.family: "Material Icons"
                        font.pixelSize: Math.round(16 * UIScale.value)
                        color: NetworkService.scanning ? Colors.muted : (scanMa.containsMouse ? Colors.accent : Colors.textDim)
                        rotation: NetworkService.scanning ? 360 : 0

                        RotationAnimator on rotation {
                            running: NetworkService.scanning
                            from: 0
                            to: 360
                            duration: 1000
                            loops: Animation.Infinite
                        }
                        Behavior on color {
                            ColorAnimation {
                                duration: Anim.fast
                            }
                        }
                    }

                    MouseArea {
                        id: scanMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: !NetworkService.scanning
                        onClicked: NetworkService.scan()
                    }
                }
            }

            Item {
                implicitHeight: Math.round(6 * UIScale.value)
            }

            Text {
                Layout.fillWidth: true
                Layout.leftMargin: UIScale.spacingMd + Math.round(4 * UIScale.value)
                visible: !NetworkService.scanning && NetworkService.servers.length === 0
                text: I18n.t("network.noServersFoundOnNetwork")
                color: Colors.textDim
                font.pixelSize: UIScale.fontCaption
            }

            Text {
                Layout.fillWidth: true
                Layout.leftMargin: UIScale.spacingMd + Math.round(4 * UIScale.value)
                visible: NetworkService.scanning && NetworkService.servers.length === 0
                text: I18n.t("network.scanning")
                color: Colors.textDim
                font.pixelSize: UIScale.fontCaption
            }

            // Server rows
            Repeater {
                model: ScriptModel {
                    values: NetworkService.servers
                }

                delegate: Item {
                    id: serverRow
                    required property var modelData

                    readonly property string hostname: serverRow.modelData.hostname
                    readonly property bool isExpanded: root.expandedHost === serverRow.hostname
                    readonly property var srvState: NetworkService.serverState[serverRow.hostname] ?? {
                        status: "idle",
                        shares: [],
                        error: "",
                        user: ""
                    }

                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.spacingMd
                    Layout.rightMargin: UIScale.spacingMd
                    Layout.bottomMargin: Math.round(4 * UIScale.value)
                    implicitHeight: serverHeader.height + expandArea.height

                    Rectangle {
                        id: serverHeader
                        width: parent.width
                        height: Math.round(44 * UIScale.value)
                        radius: UIScale.radiusMd
                        color: serverRow.isExpanded ? Colors.withAlpha(Colors.accent, 0.15) : (headerMa.containsMouse ? Colors.surfaceHigh : Colors.surface)
                        border.color: serverRow.isExpanded ? Colors.withAlpha(Colors.accent, 0.5) : "transparent"
                        border.width: 1
                        Behavior on color {
                            ColorAnimation {
                                duration: Anim.fast
                            }
                        }
                        Behavior on border.color {
                            ColorAnimation {
                                duration: Anim.fast
                            }
                        }

                        MouseArea {
                            id: headerMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.expandedHost = serverRow.isExpanded ? "" : serverRow.hostname
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: UIScale.spacingMd
                            anchors.rightMargin: UIScale.spacingMd
                            spacing: UIScale.spacingSm

                            Text {
                                text: serverRow.isExpanded ? "▾" : "▸"
                                color: serverRow.isExpanded ? Colors.accent : Colors.textDim
                                font.pixelSize: Math.round(12 * UIScale.value)
                                Behavior on color {
                                    ColorAnimation {
                                        duration: Anim.fast
                                    }
                                }
                            }

                            Text {
                                text: serverRow.modelData.name || serverRow.hostname
                                color: Colors.text
                                font.pixelSize: UIScale.fontSmall
                                font.weight: Font.DemiBold
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Text {
                                visible: serverRow.srvState.status === "listed" && NetworkService.mountBackend !== "mountcifs"
                                text: serverRow.srvState.shares ? I18n.t(serverRow.srvState.shares.length !== 1 ? "network.sharesCountPlural" : "network.sharesCountSingular", [serverRow.srvState.shares.length]) : ""
                                color: Colors.textDim
                                font.pixelSize: UIScale.fontCaption
                            }

                            Rectangle {
                                visible: NetworkService.mountBackend === "mountcifs" && serverRow.srvState.status === "listed"
                                implicitWidth: disconnectCifsLabel.implicitWidth + UIScale.spacingSm * 2
                                implicitHeight: Math.round(24 * UIScale.value)
                                radius: Math.round(12 * UIScale.value)
                                color: disconnectCifsMa.containsMouse ? Colors.withAlpha(Colors.accent, 0.2) : Colors.withAlpha(Colors.accent, 0.1)
                                Behavior on color {
                                    ColorAnimation {
                                        duration: Anim.fast
                                    }
                                }

                                Text {
                                    id: disconnectCifsLabel
                                    anchors.centerIn: parent
                                    text: I18n.t("network.disconnectAction")
                                    color: Colors.accent
                                    font.pixelSize: UIScale.fontCaption
                                }

                                MouseArea {
                                    id: disconnectCifsMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: mouse => {
                                        mouse.accepted = true;
                                        NetworkService.disconnectMountcifs(serverRow.hostname);
                                    }
                                }
                            }

                            Text {
                                visible: serverRow.srvState.status === "listing"
                                text: "..."
                                color: Colors.muted
                                font.pixelSize: UIScale.fontCaption
                            }

                            Text {
                                visible: serverRow.srvState.status === "error"
                                text: "!"
                                color: Colors.accent
                                font.pixelSize: UIScale.fontSmall
                                font.weight: Font.Bold
                            }
                        }
                    }

                    Item {
                        id: expandArea
                        anchors.top: serverHeader.bottom
                        anchors.topMargin: Math.round(2 * UIScale.value)
                        width: parent.width
                        clip: true
                        height: serverRow.isExpanded ? expandInner.implicitHeight + Math.round(4 * UIScale.value) : 0

                        Behavior on height {
                            NumberAnimation {
                                duration: Anim.medium
                                easing.type: Easing.OutCubic
                            }
                        }

                        Column {
                            id: expandInner
                            width: parent.width
                            spacing: Math.round(2 * UIScale.value)

                            ReconnectRow {
                                width: parent.width
                                hostname: serverRow.hostname
                                visible: NetworkService.mountBackend === "smbnetfs" && serverRow.srvState.status !== "listed" && serverRow.srvState.status !== "listing" && NetworkService.smbnetfsSavedHosts.indexOf(serverRow.hostname) >= 0
                            }

                            AuthForm {
                                width: parent.width
                                hostname: serverRow.hostname
                                srvState: serverRow.srvState
                                authUser: root.authUser
                                authPass: root.authPass
                                authPassVisible: root.authPassVisible
                                visible: (serverRow.srvState.status !== "listed" && serverRow.srvState.status !== "listing") && !(NetworkService.mountBackend === "smbnetfs" && NetworkService.smbnetfsSavedHosts.indexOf(serverRow.hostname) >= 0)
                                onAuthUserEdited: text => root.authUser = text
                                onAuthPassEdited: text => root.authPass = text
                                onPassVisibilityToggled: root.authPassVisible = !root.authPassVisible
                                onConnectRequested: {
                                    if (!root.authUser)
                                        return;
                                    if (NetworkService.mountBackend === "smbnetfs")
                                        NetworkService.connectSmbnetfs(serverRow.hostname, root.authUser, root.authPass);
                                    else
                                        NetworkService.listShares(serverRow.hostname, root.authUser, root.authPass);
                                }
                            }

                            Text {
                                width: parent.width
                                visible: serverRow.srvState.status === "listing"
                                text: I18n.t("network.listingShares")
                                color: Colors.textDim
                                font.pixelSize: UIScale.fontCaption
                                leftPadding: UIScale.spacingSm
                                topPadding: Math.round(6 * UIScale.value)
                                bottomPadding: Math.round(6 * UIScale.value)
                            }

                            Rectangle {
                                width: parent.width
                                visible: serverRow.srvState.status === "listed"
                                implicitHeight: shareCol.implicitHeight
                                radius: UIScale.radiusMd
                                color: Colors.surface
                                clip: true

                                Column {
                                    id: shareCol
                                    width: parent.width

                                    Repeater {
                                        model: ScriptModel {
                                            values: serverRow.srvState.shares
                                        }
                                        delegate: ShareRow {
                                            width: parent.width
                                            hostname: serverRow.hostname
                                            authUser: root.authUser
                                            authPass: root.authPass
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Item {
                implicitHeight: UIScale.spacingMd
            }
        }
    }
}
