pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../calendar"
import "../community"
import "../globe3d"
import "../network"
import "../notifications"
import "../sysmon"
import "../nixpurity"
import "../user"
import "../shared"
import "../../"

Item {
    id: root
    focus: true

    Keys.onEscapePressed: HomePanelService.open = false

    property string section: "home"

    property bool _panelOpen: HomePanelService.open
    on_PanelOpenChanged: {
        if (_panelOpen && HomePanelService.requestedSection !== "") {
            root.section = HomePanelService.requestedSection;
            HomePanelService.requestedSection = "";
        }
    }
    property string searchText: ""
    property string _hostname: ""

    function matchesSearch(label) {
        return root.searchText === "" || label.toLowerCase().includes(root.searchText.toLowerCase());
    }
    readonly property bool _devMode: !!Quickshell.env("ZESIS_DEV")

    Process {
        command: ["hostname"]
        running: true
        stdout: SplitParser {
            onRead: data => root._hostname = data.trim()
        }
    }

    readonly property bool panelOpen: HomePanelService.open
    onPanelOpenChanged: if (!panelOpen)
        searchField.text = ""

    property string _reqSec: HomePanelService.requestedSection
    on_ReqSecChanged: {
        if (_reqSec !== "") {
            root.section = _reqSec;
            HomePanelService.requestedSection = "";
        }
    }

    component NavItem: Rectangle {
        id: navItem
        property string navId: ""
        property string navLabel: ""
        property string navIcon: ""
        property bool isNavSelected: false

        implicitHeight: Math.round(38 * UIScale.value)
        radius: UIScale.radiusMd
        color: isNavSelected ? Colors.withAlpha(Colors.accent, 0.15) : (navHover.hovered ? Colors.withAlpha(Colors.text, 0.06) : "transparent")
        Behavior on color {
            ColorAnimation {
                duration: Anim.fast
            }
        }

        Rectangle {
            visible: navItem.isNavSelected
            width: Math.round(3 * UIScale.value)
            radius: Math.round(2 * UIScale.value)
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.topMargin: Math.round(7 * UIScale.value)
            anchors.bottomMargin: Math.round(7 * UIScale.value)
            color: Colors.accent
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: UIScale.radiusMd
            anchors.rightMargin: UIScale.spacingSm
            spacing: UIScale.spacingSm

            Text {
                text: navItem.navIcon
                font.family: "Material Icons"
                font.pixelSize: Math.round(18 * UIScale.value)
                color: navItem.isNavSelected ? Colors.accent : Colors.textDim
                Behavior on color {
                    ColorAnimation {
                        duration: Anim.fast
                    }
                }
            }
            Text {
                text: navItem.navLabel
                color: navItem.isNavSelected ? Colors.text : Colors.textDim
                font.pixelSize: UIScale.fontLead
                font.weight: navItem.isNavSelected ? Font.DemiBold : Font.Normal
                Layout.fillWidth: true
                elide: Text.ElideRight
                Behavior on color {
                    ColorAnimation {
                        duration: Anim.fast
                    }
                }
            }
        }

        HoverHandler {
            id: navHover
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.section = navItem.navId
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Math.round(16 * UIScale.value)
        color: Colors.bg
        border.color: Colors.withAlpha(Colors.outline, 0.6)
        border.width: 1

        MouseArea {
            anchors.fill: parent
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // Sidebar
        Item {
            Layout.preferredWidth: Math.round(220 * UIScale.value)
            Layout.fillHeight: true

            Rectangle {
                anchors.fill: parent
                topLeftRadius: Math.round(16 * UIScale.value)
                bottomLeftRadius: Math.round(16 * UIScale.value)
                color: Colors.withAlpha(Colors.surface, 0.6)

                MouseArea {
                    anchors.fill: parent
                }
            }

            Rectangle {
                id: sidebarDivider
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                width: 1
                color: Colors.withAlpha(Colors.outline, 0.5)
            }

            ColumnLayout {
                anchors.left: parent.left
                anchors.right: sidebarDivider.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: UIScale.spacingMd
                spacing: 0

                // Header
                RowLayout {
                    Layout.fillWidth: true
                    Layout.bottomMargin: UIScale.spacingMd
                    Layout.topMargin: UIScale.spacingXs
                    spacing: UIScale.spacingSm

                    Rectangle {
                        implicitWidth: Math.round(34 * UIScale.value)
                        implicitHeight: Math.round(34 * UIScale.value)
                        radius: UIScale.spacingSm
                        gradient: Gradient {
                            GradientStop {
                                position: 0
                                color: Qt.lighter(Colors.accent, 1.1)
                            }
                            GradientStop {
                                position: 1
                                color: Qt.darker(Colors.accent, 1.4)
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: ""
                            font.family: "Material Icons"
                            font.pixelSize: Math.round(18 * UIScale.value)
                            color: Colors.bg
                        }
                    }

                    Column {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            text: "zesis"
                            color: Colors.text
                            font.pixelSize: UIScale.fontSubhead
                            font.weight: Font.ExtraBold
                        }
                    }

                    Rectangle {
                        implicitWidth: Math.round(30 * UIScale.value)
                        implicitHeight: Math.round(30 * UIScale.value)
                        radius: UIScale.radiusMd
                        color: closeHover.hovered ? Colors.withAlpha(Colors.text, 0.08) : "transparent"
                        Behavior on color {
                            ColorAnimation {
                                duration: Anim.fast
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            font.pixelSize: Math.round(14 * UIScale.value)
                            color: closeHover.hovered ? Colors.text : Colors.textDim
                            Behavior on color {
                                ColorAnimation {
                                    duration: Anim.fast
                                }
                            }
                        }

                        HoverHandler {
                            id: closeHover
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: HomePanelService.open = false
                        }
                    }
                }

                // Search bar
                StyledTextInput {
                    id: searchField
                    Layout.fillWidth: true
                    Layout.bottomMargin: UIScale.radiusMd
                    icon: ""
                    showClearButton: true
                    placeholder: I18n.t("home.searchPlaceholder")
                    onTextChanged: root.searchText = text
                    onEscapePressed: HomePanelService.open = false
                }

                // Scrollable nav list
                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentHeight: navColumn.implicitHeight
                    clip: true
                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                    }

                    ColumnLayout {
                        id: navColumn
                        width: parent.width
                        spacing: 0

                        NavItem {
                            id: navHomeItem
                            navId: "home"
                            navLabel: I18n.t("home.navHome")
                            navIcon: ""
                            isNavSelected: root.section === "home"
                            visible: root.matchesSearch(navLabel)
                            Layout.fillWidth: true
                            Layout.bottomMargin: Math.round(2 * UIScale.value)
                        }

                        Text {
                            text: I18n.t("home.groupApps")
                            color: Colors.muted
                            font.pixelSize: UIScale.fontTiny
                            font.weight: Font.Bold
                            font.letterSpacing: 1.5
                            leftPadding: UIScale.spacingSm
                            Layout.topMargin: UIScale.radiusMd
                            Layout.bottomMargin: UIScale.spacingXs
                            visible: root.matchesSearch(navCommunityItem.navLabel) || root.matchesSearch(navNetworkItem.navLabel) || root.matchesSearch(navSysMonItem.navLabel) || root.matchesSearch(navNotifsItem.navLabel) || root.matchesSearch(navCalendarItem.navLabel) || (NixPurityService.isNixOS && root.matchesSearch(navNixPurityItem.navLabel))
                        }
                        NavItem {
                            id: navCommunityItem
                            navId: "community"
                            navLabel: I18n.t("home.navCommunity")
                            navIcon: ""
                            isNavSelected: root.section === "community"
                            visible: root.matchesSearch(navLabel)
                            Layout.fillWidth: true
                            Layout.bottomMargin: Math.round(2 * UIScale.value)
                        }
                        NavItem {
                            id: navNetworkItem
                            navId: "network"
                            navLabel: I18n.t("home.navNetwork")
                            navIcon: ""
                            isNavSelected: root.section === "network"
                            visible: root.matchesSearch(navLabel)
                            Layout.fillWidth: true
                            Layout.bottomMargin: Math.round(2 * UIScale.value)
                        }
                        NavItem {
                            id: navSysMonItem
                            navId: "sysmon"
                            navLabel: I18n.t("home.navSysMon")
                            navIcon: ""
                            isNavSelected: root.section === "sysmon"
                            visible: root.matchesSearch(navLabel)
                            Layout.fillWidth: true
                            Layout.bottomMargin: Math.round(2 * UIScale.value)
                        }
                        NavItem {
                            id: navNixPurityItem
                            navId: "nixpurity"
                            navLabel: I18n.t("home.navNixPurity")
                            navIcon: "󱄅"
                            isNavSelected: root.section === "nixpurity"
                            visible: NixPurityService.isNixOS && root.matchesSearch(navLabel)
                            Layout.fillWidth: true
                            Layout.bottomMargin: Math.round(2 * UIScale.value)
                        }
                        NavItem {
                            id: navNotifsItem
                            navId: "notifs"
                            navLabel: I18n.t("home.navNotifications")
                            navIcon: ""
                            isNavSelected: root.section === "notifs"
                            visible: root.matchesSearch(navLabel)
                            Layout.fillWidth: true
                            Layout.bottomMargin: Math.round(2 * UIScale.value)
                        }
                        NavItem {
                            id: navCalendarItem
                            navId: "calendar"
                            navLabel: I18n.t("home.navCalendar")
                            navIcon: "󰺻"
                            isNavSelected: root.section === "calendar"
                            visible: root.matchesSearch(navLabel)
                            Layout.fillWidth: true
                            Layout.bottomMargin: Math.round(2 * UIScale.value)
                        }

                        Text {
                            text: I18n.t("home.groupDev")
                            color: Colors.muted
                            font.pixelSize: UIScale.fontTiny
                            font.weight: Font.Bold
                            font.letterSpacing: 1.5
                            leftPadding: UIScale.spacingSm
                            Layout.topMargin: UIScale.radiusMd
                            Layout.bottomMargin: UIScale.spacingXs
                            visible: root._devMode && (root.matchesSearch(navResponsiveTestItem.navLabel) || root.matchesSearch(navAssemblyTestItem.navLabel))
                        }

                        NavItem {
                            id: navResponsiveTestItem
                            navId: "responsivetest"
                            navLabel: I18n.t("home.navResponsiveTest")
                            navIcon: "󰙨"
                            isNavSelected: root.section === "responsivetest"
                            visible: root._devMode && root.matchesSearch(navLabel)
                            Layout.fillWidth: true
                            Layout.bottomMargin: Math.round(2 * UIScale.value)
                        }
                        NavItem {
                            id: navAssemblyTestItem
                            navId: "assemblytest"
                            navLabel: I18n.t("home.navAssemblyTest")
                            navIcon: "󰙨"
                            isNavSelected: root.section === "assemblytest"
                            visible: root._devMode && root.matchesSearch(navLabel)
                            Layout.fillWidth: true
                            Layout.bottomMargin: Math.round(2 * UIScale.value)
                        }
                    } // ColumnLayout navColumn
                } // Flickable

                // Machine footer
                Rectangle {
                    Layout.fillWidth: true
                    Layout.topMargin: UIScale.spacingSm
                    implicitHeight: Math.round(46 * UIScale.value)
                    radius: UIScale.spacingSm
                    color: Colors.withAlpha(Colors.text, 0.03)
                    border.color: Colors.withAlpha(Colors.text, 0.05)
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: UIScale.spacingSm
                        anchors.rightMargin: UIScale.spacingSm
                        spacing: UIScale.spacingSm

                        UserAvatar {
                            size: Math.round(30 * UIScale.value)
                        }

                        Column {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                text: UserService.name !== "" ? UserService.name : root._hostname
                                color: Colors.text
                                font.pixelSize: UIScale.fontSmall
                                font.weight: Font.Bold
                                elide: Text.ElideRight
                                width: parent.width
                            }
                            Text {
                                text: root._hostname
                                color: Colors.textDim
                                font.pixelSize: UIScale.fontTiny
                                font.family: "monospace"
                                elide: Text.ElideRight
                                width: parent.width
                            }
                        }
                    }
                }
            }
        }

        // Content area
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Loader {
                anchors.fill: parent
                active: HomePanelService.open
                sourceComponent: {
                    if (root.section === "home")
                        return dashboardComp;
                    if (root.section === "community")
                        return communityPanelComp;
                    if (root.section === "network")
                        return networkExpandedComp;
                    if (root.section === "sysmon")
                        return sysMonPanelComp;
                    if (root.section === "nixpurity")
                        return nixPurityComp;
                    if (root.section === "notifs")
                        return notifHistComp;
                    if (root.section === "calendar")
                        return calendarPanelComp;
                    if (root.section === "responsivetest")
                        return responsiveTestComp;
                    if (root.section === "assemblytest")
                        return assemblyTestComp;
                    return placeholderComp;
                }
            }

            Component {
                id: dashboardComp
                DashboardPanel {}
            }
            Component {
                id: communityPanelComp
                CommunityPanel {}
            }
            Component {
                id: networkExpandedComp
                NetworkPanel {}
            }
            Component {
                id: sysMonPanelComp
                SysMonPanel {}
            }
            Component {
                id: nixPurityComp
                NixPurity {}
            }
            Component {
                id: notifHistComp
                NotifHistory {}
            }
            Component {
                id: calendarPanelComp
                CalendarPanel {}
            }
            Component {
                id: responsiveTestComp
                ResponsiveTestPanel {}
            }
            Component {
                id: assemblyTestComp
                Globe3DGate {
                    panelSource: "AssemblyTest.qml"
                }
            }

            Component {
                id: placeholderComp
                Item {
                    Text {
                        anchors.centerIn: parent
                        text: I18n.t("home.comingSoon")
                        color: Colors.textDim
                        font.pixelSize: UIScale.fontLead
                    }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        z: 9999
        propagateComposedEvents: true
        onPressed: mouse => {
            root.forceActiveFocus();
            mouse.accepted = false;
        }
    }
}
