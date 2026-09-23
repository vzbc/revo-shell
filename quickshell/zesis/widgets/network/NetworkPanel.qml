pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../"
import "../shared"

Item {
    id: root

    property bool showSettings: false
    property string selectedHost: ""
    property string authUser: ""
    property string authPass: ""
    property bool authPassVisible: false

    onSelectedHostChanged: {
        authUser = NetworkService.systemUser;
        authPass = "";
        authPassVisible = false;
    }

    readonly property var selectedSrvState: NetworkService.serverState[root.selectedHost] ?? {
        status: "idle",
        shares: [],
        error: "",
        user: ""
    }

    readonly property bool anyConnected: (NetworkService.mountBackend === "smbnetfs" && NetworkService.smbnetfsConnected.length > 0) || (NetworkService.mountBackend === "mountcifs" && NetworkService.mounts.length > 0)

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Header
        PanelHeader {
            Layout.fillWidth: true
            breadcrumb: I18n.t("network.breadcrumb")
            title: I18n.t("network.title")

            rightActions: Component {
                RowLayout {
                    spacing: UIScale.spacingSm

                    // Settings toggle button
                    Rectangle {
                        implicitHeight: Math.round(34 * UIScale.value)
                        implicitWidth: Math.round(34 * UIScale.value)
                        radius: UIScale.radiusMd
                        color: root.showSettings ? Colors.withAlpha(Colors.accent, 0.18) : (settingsMa.containsMouse ? Colors.withAlpha(Colors.text, 0.08) : Colors.withAlpha(Colors.text, 0.05))
                        border.color: root.showSettings ? Colors.withAlpha(Colors.accent, 0.35) : Colors.withAlpha(Colors.text, 0.08)
                        border.width: 1
                        Behavior on color {
                            ColorAnimation {
                                duration: Anim.fast
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: ""
                            font.family: "Material Icons"
                            font.pixelSize: Math.round(16 * UIScale.value)
                            color: root.showSettings ? Colors.accent : Colors.textDim
                        }

                        MouseArea {
                            id: settingsMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.showSettings = !root.showSettings
                        }
                    }

                    // Rescan button
                    Rectangle {
                        implicitHeight: Math.round(34 * UIScale.value)
                        implicitWidth: rescanInner.implicitWidth + Math.round(24 * UIScale.value)
                        radius: UIScale.radiusMd
                        color: rescanMa.containsMouse ? Colors.withAlpha(Colors.text, 0.08) : Colors.withAlpha(Colors.text, 0.05)
                        border.color: Colors.withAlpha(Colors.text, 0.08)
                        border.width: 1
                        Behavior on color {
                            ColorAnimation {
                                duration: Anim.fast
                            }
                        }

                        Row {
                            id: rescanInner
                            anchors.centerIn: parent
                            spacing: Math.round(7 * UIScale.value)

                            Text {
                                text: ""
                                font.family: "Material Icons"
                                font.pixelSize: Math.round(15 * UIScale.value)
                                color: Colors.textDim
                                anchors.verticalCenter: parent.verticalCenter

                                RotationAnimator on rotation {
                                    running: NetworkService.scanning
                                    from: 0
                                    to: 360
                                    duration: 1000
                                    loops: Animation.Infinite
                                }
                            }
                            Text {
                                text: I18n.t("network.rescan")
                                color: Colors.textDim
                                font.pixelSize: UIScale.fontBody
                                font.weight: Font.DemiBold
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: rescanMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            enabled: !NetworkService.scanning
                            onClicked: NetworkService.scan()
                        }
                    }

                    // Connected status pill
                    Rectangle {
                        visible: root.anyConnected
                        implicitHeight: Math.round(34 * UIScale.value)
                        implicitWidth: connPillInner.implicitWidth + Math.round(24 * UIScale.value)
                        radius: UIScale.radiusMd
                        color: Colors.withAlpha(Colors.accent, 0.14)
                        border.color: Colors.withAlpha(Colors.accent, 0.3)
                        border.width: 1

                        Row {
                            id: connPillInner
                            anchors.centerIn: parent
                            spacing: UIScale.spacingSm

                            Rectangle {
                                width: UIScale.spacingSm
                                height: UIScale.spacingSm
                                radius: width / 2
                                color: Colors.accent
                                anchors.verticalCenter: parent.verticalCenter

                                SequentialAnimation on opacity {
                                    loops: Animation.Infinite
                                    NumberAnimation {
                                        to: 0.55
                                        duration: 1200
                                        easing.type: Easing.InOutSine
                                    }
                                    NumberAnimation {
                                        to: 1.0
                                        duration: 1200
                                        easing.type: Easing.InOutSine
                                    }
                                }
                            }
                            Text {
                                text: I18n.t("network.connected")
                                color: Colors.accent
                                font.pixelSize: UIScale.fontBody
                                font.weight: Font.Bold
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }
            }
        }

        // Settings panel
        Flickable {
            visible: root.showSettings
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: settingsCol.implicitHeight + UIScale.panelPad
            clip: true
            flickableDirection: Flickable.VerticalFlick

            ColumnLayout {
                id: settingsCol
                width: parent.width
                spacing: UIScale.spacingMd

                Item {
                    implicitHeight: UIScale.spacingSm
                }

                Text {
                    text: I18n.t("network.mountBackendLabel")
                    color: Colors.text
                    font.pixelSize: UIScale.fontBody
                    font.bold: true
                    Layout.leftMargin: UIScale.panelPad
                }

                OptionRow {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                    model: ["mount.cifs", "smbnetfs"]
                    currentIndex: NetworkService.mountBackend === "mountcifs" ? 0 : 1
                    onActivated: index => NetworkService.saveBackend(index === 0 ? "mountcifs" : "smbnetfs")
                }

                Text {
                    visible: NetworkService.mountBackend === "smbnetfs" && !NetworkService.smbnetfsAvailable
                    text: I18n.t("network.smbnetfsNotInstalled")
                    color: Colors.accent
                    font.pixelSize: UIScale.fontCaption
                    Layout.leftMargin: UIScale.panelPad
                }
                Text {
                    visible: NetworkService.mountBackend === "mountcifs" && NetworkService.mountCifsPath === ""
                    text: I18n.t("network.mountCifsNotInstalled")
                    color: Colors.accent
                    font.pixelSize: UIScale.fontCaption
                    Layout.leftMargin: UIScale.panelPad
                }

                Divider {
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                    visible: NetworkService.mountBackend === "smbnetfs"

                    Text {
                        text: I18n.t("network.persistCredentials")
                        color: Colors.text
                        font.pixelSize: UIScale.fontBody
                        Layout.fillWidth: true
                    }
                    ToggleSwitch {
                        checked: NetworkService.persistCredentials
                        onToggled: NetworkService.savePersistCredentials(!NetworkService.persistCredentials)
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                    visible: NetworkService.mountBackend === "smbnetfs" && NetworkService.persistCredentials && NetworkService.keychainAvailable

                    Text {
                        text: I18n.t("network.useKeyring")
                        color: Colors.text
                        font.pixelSize: UIScale.fontBody
                        Layout.fillWidth: true
                    }
                    ToggleSwitch {
                        checked: NetworkService.useKeyring
                        onToggled: NetworkService.saveUseKeyring(!NetworkService.useKeyring)
                    }
                }

                Text {
                    visible: NetworkService.mountBackend === "smbnetfs" && NetworkService.persistCredentials && (!NetworkService.useKeyring || !NetworkService.keychainAvailable)
                    text: I18n.t("network.plainTextWarning")
                    color: Colors.accent
                    font.pixelSize: UIScale.fontCaption
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                }

                Divider {
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad

                    Text {
                        text: I18n.t("network.showWarnings")
                        color: Colors.text
                        font.pixelSize: UIScale.fontBody
                        Layout.fillWidth: true
                    }
                    ToggleSwitch {
                        checked: NetworkService.showWarnings
                        onToggled: NetworkService.saveShowWarnings(!NetworkService.showWarnings)
                    }
                }

                Item {
                    implicitHeight: UIScale.spacingXs
                }
            }
        }

        // Scrollable body
        Flickable {
            visible: !root.showSettings
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: bodyCol.implicitHeight + UIScale.panelPad
            clip: true
            flickableDirection: Flickable.VerticalFlick

            ColumnLayout {
                id: bodyCol
                width: parent.width
                spacing: UIScale.spacingLg

                Item {
                    implicitHeight: UIScale.spacingXs
                }

                WarningBanners {
                    id: warnBanners
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                    Layout.preferredHeight: warnBanners.implicitHeight
                }

                // Hero card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                    visible: root.selectedSrvState.status === "listed"
                    implicitHeight: Math.round(100 * UIScale.value)
                    radius: Math.round(18 * UIScale.value)
                    border.color: Colors.withAlpha(Colors.accent, 0.22)
                    border.width: 1
                    clip: true

                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop {
                            position: 0
                            color: Colors.withAlpha(Colors.accent, 0.14)
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
                            implicitWidth: Math.round(56 * UIScale.value)
                            implicitHeight: Math.round(56 * UIScale.value)
                            radius: UIScale.radiusLg
                            color: Colors.withAlpha(Colors.accent, 0.14)
                            border.color: Colors.withAlpha(Colors.accent, 0.28)
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: ""
                                font.family: "Material Icons"
                                font.pixelSize: Math.round(24 * UIScale.value)
                                color: Colors.accent
                            }
                        }

                        Column {
                            Layout.fillWidth: true
                            spacing: UIScale.spacingSm

                            Row {
                                spacing: UIScale.spacingSm

                                Text {
                                    text: root.selectedHost
                                    color: Colors.text
                                    font.pixelSize: Math.round(20 * UIScale.value)
                                    font.weight: Font.ExtraBold
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    readonly property string dispName: {
                                        for (var i = 0; i < NetworkService.servers.length; i++) {
                                            if (NetworkService.servers[i].hostname === root.selectedHost)
                                                return NetworkService.servers[i].name || "";
                                        }
                                        return "";
                                    }
                                    visible: dispName !== "" && dispName !== root.selectedHost
                                    text: dispName
                                    color: Colors.withAlpha(Colors.textDim, 0.55)
                                    font.pixelSize: UIScale.fontBody
                                    font.weight: Font.DemiBold
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Row {
                                Rectangle {
                                    height: Math.round(22 * UIScale.value)
                                    width: shareChipTxt.implicitWidth + Math.round(16 * UIScale.value)
                                    radius: UIScale.radiusSm
                                    color: Colors.withAlpha(Colors.accent, 0.12)
                                    border.color: Colors.withAlpha(Colors.accent, 0.22)
                                    border.width: 1

                                    Text {
                                        id: shareChipTxt
                                        anchors.centerIn: parent
                                        text: I18n.t(root.selectedSrvState.shares.length !== 1 ? "network.sharesCountPlural" : "network.sharesCountSingular", [root.selectedSrvState.shares.length])
                                        color: Colors.accent
                                        font.pixelSize: UIScale.fontCaption
                                        font.weight: Font.Bold
                                        font.family: "monospace"
                                    }
                                }
                            }
                        }

                        // EQ bars (decorative) (for now)
                        Item {
                            implicitWidth: Math.round(93 * UIScale.value)
                            implicitHeight: Math.round(38 * UIScale.value)

                            Row {
                                anchors.bottom: parent.bottom
                                spacing: Math.round(3 * UIScale.value)

                                Repeater {
                                    model: [10, 18, 26, 14, 30, 20, 34, 16, 24, 12, 28, 22, 32, 15, 20, 11]
                                    delegate: Item {
                                        id: eqWrap
                                        required property int modelData
                                        required property int index

                                        width: Math.round(3 * UIScale.value)
                                        height: Math.round(38 * UIScale.value)

                                        Rectangle {
                                            width: parent.width
                                            height: Math.round(eqWrap.modelData * 0.28 * UIScale.value)
                                            radius: Math.round(1.5 * UIScale.value)
                                            anchors.bottom: parent.bottom
                                            gradient: Gradient {
                                                GradientStop {
                                                    position: 0
                                                    color: Qt.lighter(Colors.accent, 1.1)
                                                }
                                                GradientStop {
                                                    position: 1
                                                    color: Qt.darker(Colors.accent, 1.25)
                                                }
                                            }

                                            SequentialAnimation on height {
                                                loops: Animation.Infinite
                                                PauseAnimation {
                                                    duration: eqWrap.index * 130
                                                }
                                                NumberAnimation {
                                                    to: Math.round(eqWrap.modelData * UIScale.value)
                                                    duration: 550
                                                    easing.type: Easing.InOutSine
                                                }
                                                NumberAnimation {
                                                    to: Math.round(eqWrap.modelData * 0.28 * UIScale.value)
                                                    duration: 550
                                                    easing.type: Easing.InOutSine
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Disconnect button
                        Rectangle {
                            visible: (NetworkService.mountBackend === "smbnetfs" && NetworkService.smbnetfsConnected.indexOf(root.selectedHost) >= 0) || (NetworkService.mountBackend === "mountcifs" && NetworkService.serverState[root.selectedHost]?.status === "listed")
                            implicitWidth: discBtnRow.implicitWidth + Math.round(28 * UIScale.value)
                            implicitHeight: Math.round(36 * UIScale.value)
                            radius: Math.round(11 * UIScale.value)
                            color: discHero.hovered ? Colors.withAlpha(Colors.text, 0.08) : Colors.withAlpha(Colors.text, 0.05)
                            border.color: Colors.withAlpha(Colors.text, 0.1)
                            border.width: 1
                            Behavior on color {
                                ColorAnimation {
                                    duration: Anim.fast
                                }
                            }

                            Row {
                                id: discBtnRow
                                anchors.centerIn: parent
                                spacing: Math.round(7 * UIScale.value)

                                Text {
                                    text: ""
                                    font.family: "Material Icons"
                                    font.pixelSize: UIScale.fontLead
                                    color: Colors.textDim
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: I18n.t("network.disconnect")
                                    color: Colors.text
                                    font.pixelSize: UIScale.fontBody
                                    font.weight: Font.Bold
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            HoverHandler {
                                id: discHero
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: NetworkService.mountBackend === "smbnetfs" ? NetworkService.disconnectSmbnetfs(root.selectedHost) : NetworkService.disconnectMountcifs(root.selectedHost)
                            }
                        }
                    }
                }

                // Server list + right content
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                    spacing: Math.round(24 * UIScale.value)

                    // LEFT: server list
                    ColumnLayout {
                        Layout.preferredWidth: Math.round(296 * UIScale.value)
                        Layout.maximumWidth: Math.round(296 * UIScale.value)
                        spacing: UIScale.spacingSm

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.bottomMargin: Math.round(2 * UIScale.value)

                            SectionLabel {
                                text: I18n.t("network.discoveredServers")
                                Layout.fillWidth: true
                            }
                            Text {
                                text: NetworkService.servers.length + ""
                                color: Colors.textDim
                                font.pixelSize: UIScale.fontCaption
                                font.family: "monospace"
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: !NetworkService.scanning && NetworkService.servers.length === 0
                            text: I18n.t("network.noServersFound")
                            color: Colors.muted
                            font.pixelSize: UIScale.fontSmall
                            topPadding: UIScale.spacingSm
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: NetworkService.scanning && NetworkService.servers.length === 0
                            text: I18n.t("network.scanning")
                            color: Colors.muted
                            font.pixelSize: UIScale.fontSmall
                            topPadding: UIScale.spacingSm
                        }

                        Repeater {
                            model: ScriptModel {
                                values: NetworkService.servers
                            }
                            delegate: Rectangle {
                                id: srvCard
                                required property var modelData
                                required property int index

                                readonly property string srvHostname: modelData.hostname
                                readonly property string srvName: modelData.name || modelData.hostname
                                readonly property bool isSelected: root.selectedHost === srvCard.srvHostname
                                readonly property bool isSrvConnected: NetworkService.mountBackend === "smbnetfs" ? NetworkService.smbnetfsConnected.indexOf(srvCard.srvHostname) >= 0 : false
                                readonly property var srvState: NetworkService.serverState[srvCard.srvHostname] ?? {
                                    status: "idle",
                                    shares: []
                                }
                                readonly property string srvSubtitle: {
                                    var n = srvCard.srvState.shares.length;
                                    return n > 0 ? srvCard.srvHostname + " · " + I18n.t(n !== 1 ? "network.sharesCountPlural" : "network.sharesCountSingular", [n]) : srvCard.srvHostname;
                                }

                                Layout.fillWidth: true
                                implicitHeight: Math.round(58 * UIScale.value)
                                radius: UIScale.radiusLg
                                border.width: 1
                                border.color: srvCard.isSelected ? Colors.withAlpha(Colors.accent, 0.4) : Colors.withAlpha(Colors.text, 0.07)
                                Behavior on border.color {
                                    ColorAnimation {
                                        duration: Anim.fast
                                    }
                                }
                                color: "transparent"
                                clip: true

                                Rectangle {
                                    anchors.fill: parent
                                    radius: parent.radius
                                    color: Colors.withAlpha(Colors.text, 0.035)
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: parent.radius
                                    opacity: srvCard.isSelected ? 1 : 0
                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: Anim.fast
                                        }
                                    }
                                    gradient: Gradient {
                                        orientation: Gradient.Horizontal
                                        GradientStop {
                                            position: 0
                                            color: Colors.surfaceHigh
                                        }
                                        GradientStop {
                                            position: 1
                                            color: Colors.withAlpha(Colors.surface, 0.3)
                                        }
                                    }
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: parent.radius
                                    color: Colors.withAlpha(Colors.text, 0.06)
                                    opacity: srvCardHover.hovered && !srvCard.isSelected ? 1 : 0
                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: Anim.fast
                                        }
                                    }
                                }

                                Rectangle {
                                    visible: srvCard.isSelected
                                    width: Math.round(3 * UIScale.value)
                                    radius: Math.round(2 * UIScale.value)
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    anchors.topMargin: UIScale.spacingSm
                                    anchors.bottomMargin: UIScale.spacingSm
                                    color: Colors.accent
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: UIScale.spacingMd
                                    anchors.rightMargin: UIScale.radiusMd
                                    spacing: UIScale.radiusMd

                                    Rectangle {
                                        implicitWidth: Math.round(9 * UIScale.value)
                                        implicitHeight: Math.round(9 * UIScale.value)
                                        radius: implicitWidth / 2
                                        color: srvCard.isSrvConnected ? Colors.accent : Colors.withAlpha(Colors.text, 0.25)
                                        Behavior on color {
                                            ColorAnimation {
                                                duration: Anim.fast
                                            }
                                        }
                                    }

                                    Column {
                                        Layout.fillWidth: true
                                        spacing: Math.round(2 * UIScale.value)

                                        Text {
                                            text: srvCard.srvName
                                            color: Colors.text
                                            font.pixelSize: UIScale.fontLead
                                            font.weight: Font.Bold
                                            font.family: "monospace"
                                            elide: Text.ElideRight
                                            width: parent.width
                                        }
                                        Text {
                                            text: srvCard.srvSubtitle
                                            color: Colors.textDim
                                            font.pixelSize: UIScale.fontCaption
                                            elide: Text.ElideRight
                                            width: parent.width
                                        }
                                    }

                                    Text {
                                        text: ""
                                        font.family: "Material Icons"
                                        font.pixelSize: Math.round(16 * UIScale.value)
                                        color: srvCard.isSelected ? Colors.accent : Colors.withAlpha(Colors.text, 0.35)
                                        Behavior on color {
                                            ColorAnimation {
                                                duration: Anim.fast
                                            }
                                        }
                                    }
                                }

                                HoverHandler {
                                    id: srvCardHover
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.selectedHost = srvCard.isSelected ? "" : srvCard.srvHostname
                                }
                            }
                        }

                        // Add server stub
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.topMargin: Math.round(2 * UIScale.value)
                            implicitHeight: Math.round(44 * UIScale.value)
                            radius: Math.round(13 * UIScale.value)
                            color: addHover.hovered ? Colors.withAlpha(Colors.text, 0.04) : "transparent"
                            border.color: Colors.withAlpha(Colors.text, addHover.hovered ? 0.18 : 0.12)
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

                            Row {
                                anchors.centerIn: parent
                                spacing: Math.round(7 * UIScale.value)

                                Text {
                                    text: ""
                                    font.family: "Material Icons"
                                    font.pixelSize: Math.round(15 * UIScale.value)
                                    color: Colors.textDim
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: I18n.t("network.addServer")
                                    color: Colors.textDim
                                    font.pixelSize: UIScale.fontBody
                                    font.weight: Font.DemiBold
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            HoverHandler {
                                id: addHover
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                            }
                        }
                    }

                    // RIGHT: context-dependent content
                    Item {
                        Layout.fillWidth: true
                        implicitHeight: rightPanel.implicitHeight

                        Column {
                            id: rightPanel
                            width: parent.width
                            spacing: UIScale.spacingMd

                            Item {
                                width: parent.width
                                implicitHeight: Math.round(100 * UIScale.value)
                                visible: root.selectedHost === ""

                                Text {
                                    anchors.centerIn: parent
                                    text: I18n.t("network.selectServer")
                                    color: Colors.muted
                                    font.pixelSize: UIScale.fontLead
                                }
                            }

                            Column {
                                visible: root.selectedHost !== ""
                                width: parent.width
                                spacing: UIScale.spacingMd

                                SectionLabel {
                                    visible: root.selectedSrvState.status === "listed"
                                    text: I18n.t("network.sharesOn", [root.selectedHost.split(".")[0].toUpperCase()])
                                }

                                ReconnectRow {
                                    width: parent.width
                                    hostname: root.selectedHost
                                    visible: NetworkService.mountBackend === "smbnetfs" && root.selectedSrvState.status !== "listed" && root.selectedSrvState.status !== "listing" && NetworkService.smbnetfsSavedHosts.indexOf(root.selectedHost) >= 0
                                }

                                AuthForm {
                                    width: parent.width
                                    hostname: root.selectedHost
                                    srvState: root.selectedSrvState
                                    authUser: root.authUser
                                    authPass: root.authPass
                                    authPassVisible: root.authPassVisible
                                    visible: root.selectedSrvState.status !== "listed" && root.selectedSrvState.status !== "listing" && !(NetworkService.mountBackend === "smbnetfs" && NetworkService.smbnetfsSavedHosts.indexOf(root.selectedHost) >= 0)
                                    onAuthUserEdited: text => root.authUser = text
                                    onAuthPassEdited: text => root.authPass = text
                                    onPassVisibilityToggled: root.authPassVisible = !root.authPassVisible
                                    onConnectRequested: {
                                        if (!root.authUser)
                                            return;
                                        if (NetworkService.mountBackend === "smbnetfs")
                                            NetworkService.connectSmbnetfs(root.selectedHost, root.authUser, root.authPass);
                                        else
                                            NetworkService.listShares(root.selectedHost, root.authUser, root.authPass);
                                    }
                                }

                                Text {
                                    visible: root.selectedSrvState.status === "listing"
                                    text: I18n.t("network.listingShares")
                                    color: Colors.textDim
                                    font.pixelSize: UIScale.fontBody
                                }

                                // 2-column share card grid
                                GridLayout {
                                    visible: root.selectedSrvState.status === "listed"
                                    width: parent.width
                                    columns: 2
                                    columnSpacing: UIScale.spacingMd
                                    rowSpacing: UIScale.spacingMd

                                    Repeater {
                                        model: ScriptModel {
                                            values: root.selectedSrvState.shares
                                        }
                                        delegate: Rectangle {
                                            id: shareCard
                                            required property var modelData

                                            readonly property string shareName: modelData.name
                                            readonly property string shareComment: modelData.comment ?? ""
                                            readonly property string shareState: modelData.state ?? "idle"

                                            Layout.fillWidth: true
                                            implicitHeight: shareCardInner.implicitHeight + Math.round(36 * UIScale.value)
                                            radius: UIScale.radiusXl
                                            color: Colors.withAlpha(Colors.text, 0.035)
                                            border.color: Colors.withAlpha(Colors.text, 0.07)
                                            border.width: 1
                                            clip: true

                                            Column {
                                                id: shareCardInner
                                                anchors.top: parent.top
                                                anchors.left: parent.left
                                                anchors.right: parent.right
                                                anchors.margins: Math.round(18 * UIScale.value)
                                                spacing: UIScale.spacingMd

                                                RowLayout {
                                                    width: parent.width
                                                    spacing: UIScale.radiusMd

                                                    Rectangle {
                                                        implicitWidth: Math.round(42 * UIScale.value)
                                                        implicitHeight: Math.round(42 * UIScale.value)
                                                        radius: Math.round(11 * UIScale.value)
                                                        color: Colors.withAlpha(Colors.accent, 0.1)
                                                        border.color: Colors.withAlpha(Colors.accent, 0.2)
                                                        border.width: 1

                                                        Text {
                                                            anchors.centerIn: parent
                                                            text: ""
                                                            font.family: "Material Icons"
                                                            font.pixelSize: Math.round(20 * UIScale.value)
                                                            color: Colors.accent
                                                        }
                                                    }

                                                    Column {
                                                        Layout.fillWidth: true
                                                        Layout.alignment: Qt.AlignVCenter
                                                        spacing: Math.round(2 * UIScale.value)

                                                        Text {
                                                            text: shareCard.shareName
                                                            color: Colors.text
                                                            font.pixelSize: UIScale.fontSubhead
                                                            font.weight: Font.Bold
                                                            font.family: "monospace"
                                                            elide: Text.ElideRight
                                                            width: parent.width
                                                        }
                                                        Text {
                                                            visible: shareCard.shareComment.length > 0
                                                            text: shareCard.shareComment
                                                            color: Colors.textDim
                                                            font.pixelSize: UIScale.fontSmall
                                                            elide: Text.ElideRight
                                                            width: parent.width
                                                        }
                                                    }
                                                }

                                                RowLayout {
                                                    width: parent.width
                                                    spacing: UIScale.spacingSm

                                                    Rectangle {
                                                        Layout.fillWidth: true
                                                        visible: shareCard.shareState === "mounted" || NetworkService.mountBackend === "smbnetfs"
                                                        implicitHeight: Math.round(34 * UIScale.value)
                                                        radius: Math.round(9 * UIScale.value)
                                                        color: openCardHover.hovered ? Colors.withAlpha(Colors.accent, 0.22) : Colors.withAlpha(Colors.accent, 0.14)
                                                        border.color: Colors.withAlpha(Colors.accent, 0.3)
                                                        border.width: 1
                                                        Behavior on color {
                                                            ColorAnimation {
                                                                duration: Anim.fast
                                                            }
                                                        }

                                                        Row {
                                                            anchors.centerIn: parent
                                                            spacing: UIScale.spacingXs

                                                            Text {
                                                                text: ""
                                                                font.family: "Material Icons"
                                                                font.pixelSize: UIScale.fontBody
                                                                color: Colors.accent
                                                                anchors.verticalCenter: parent.verticalCenter
                                                            }
                                                            Text {
                                                                text: I18n.t("network.open")
                                                                color: Colors.accent
                                                                font.pixelSize: UIScale.fontSmall
                                                                font.weight: Font.Bold
                                                                anchors.verticalCenter: parent.verticalCenter
                                                            }
                                                        }

                                                        HoverHandler {
                                                            id: openCardHover
                                                        }
                                                        MouseArea {
                                                            anchors.fill: parent
                                                            cursorShape: Qt.PointingHandCursor
                                                            onClicked: NetworkService.openPath(NetworkService.mountUri(root.selectedHost, shareCard.shareName))
                                                        }
                                                    }

                                                    Rectangle {
                                                        Layout.fillWidth: true
                                                        visible: shareCard.shareState === "idle" && NetworkService.mountBackend !== "smbnetfs"
                                                        implicitHeight: Math.round(34 * UIScale.value)
                                                        radius: Math.round(9 * UIScale.value)
                                                        color: mountCardHover.hovered ? Colors.withAlpha(Colors.accent, 0.22) : Colors.withAlpha(Colors.accent, 0.14)
                                                        border.color: Colors.withAlpha(Colors.accent, 0.3)
                                                        border.width: 1
                                                        Behavior on color {
                                                            ColorAnimation {
                                                                duration: Anim.fast
                                                            }
                                                        }

                                                        Text {
                                                            anchors.centerIn: parent
                                                            text: I18n.t("network.mount")
                                                            color: Colors.accent
                                                            font.pixelSize: UIScale.fontSmall
                                                            font.weight: Font.Bold
                                                        }

                                                        HoverHandler {
                                                            id: mountCardHover
                                                        }
                                                        MouseArea {
                                                            anchors.fill: parent
                                                            cursorShape: Qt.PointingHandCursor
                                                            onClicked: NetworkService.mount(root.selectedHost, shareCard.shareName, root.authUser, root.authPass)
                                                        }
                                                    }

                                                    Rectangle {
                                                        visible: shareCard.shareState === "mounted" && NetworkService.mountBackend !== "smbnetfs"
                                                        implicitWidth: unmountTxt.implicitWidth + Math.round(18 * UIScale.value)
                                                        implicitHeight: Math.round(34 * UIScale.value)
                                                        radius: Math.round(9 * UIScale.value)
                                                        color: unmountHover.hovered ? Colors.withAlpha(Colors.text, 0.08) : Colors.withAlpha(Colors.text, 0.04)
                                                        border.color: Colors.withAlpha(Colors.text, 0.08)
                                                        border.width: 1
                                                        Behavior on color {
                                                            ColorAnimation {
                                                                duration: Anim.fast
                                                            }
                                                        }

                                                        Text {
                                                            id: unmountTxt
                                                            anchors.centerIn: parent
                                                            text: I18n.t("network.unmount")
                                                            color: Colors.textDim
                                                            font.pixelSize: UIScale.fontSmall
                                                            font.weight: Font.DemiBold
                                                        }

                                                        HoverHandler {
                                                            id: unmountHover
                                                        }
                                                        MouseArea {
                                                            anchors.fill: parent
                                                            cursorShape: Qt.PointingHandCursor
                                                            onClicked: {
                                                                var uri = NetworkService.mountUri(root.selectedHost, shareCard.shareName);
                                                                if (uri)
                                                                    NetworkService.unmount(uri);
                                                            }
                                                        }
                                                    }

                                                    Rectangle {
                                                        Layout.fillWidth: true
                                                        visible: shareCard.shareState === "error"
                                                        implicitHeight: Math.round(34 * UIScale.value)
                                                        radius: Math.round(9 * UIScale.value)
                                                        color: retryHover.hovered ? Colors.withAlpha(Colors.accent, 0.22) : Colors.withAlpha(Colors.accent, 0.08)
                                                        border.color: Colors.withAlpha(Colors.accent, 0.2)
                                                        border.width: 1
                                                        Behavior on color {
                                                            ColorAnimation {
                                                                duration: Anim.fast
                                                            }
                                                        }

                                                        Text {
                                                            anchors.centerIn: parent
                                                            text: I18n.t("network.retry")
                                                            color: Colors.accent
                                                            font.pixelSize: UIScale.fontSmall
                                                            font.weight: Font.Bold
                                                        }

                                                        HoverHandler {
                                                            id: retryHover
                                                        }
                                                        MouseArea {
                                                            anchors.fill: parent
                                                            cursorShape: Qt.PointingHandCursor
                                                            onClicked: NetworkService.mount(root.selectedHost, shareCard.shareName, root.authUser, root.authPass)
                                                        }
                                                    }

                                                    Text {
                                                        visible: shareCard.shareState === "mounting"
                                                        text: I18n.t("network.mounting")
                                                        color: Colors.muted
                                                        font.pixelSize: UIScale.fontSmall
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Item {
                    implicitHeight: UIScale.spacingXs
                }
            }
        }
    }
}
