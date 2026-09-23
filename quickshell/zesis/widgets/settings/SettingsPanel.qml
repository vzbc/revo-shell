pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../config"
import "../themeswitcher"
import "../clock"
import "../appswitcher"
import "../workspaceindicator"
import "../display"
import "../bluetooth"
import "../wifi"
import "../sound"
import "../user"
import "../about"
import "../shared"
import "../../"

Item {
    id: root
    focus: true

    Keys.onEscapePressed: SettingsPanelService.open = false

    property string section: "appearance"

    property bool _panelOpen: SettingsPanelService.open
    on_PanelOpenChanged: {
        if (_panelOpen && SettingsPanelService.requestedSection !== "") {
            root.section = SettingsPanelService.requestedSection;
            SettingsPanelService.requestedSection = "";
        }
    }
    property string searchText: ""

    readonly property bool panelOpen: SettingsPanelService.open
    onPanelOpenChanged: if (!panelOpen)
        searchField.text = ""

    function matchesSearch(label) {
        return root.searchText === "" || label.toLowerCase().includes(root.searchText.toLowerCase());
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
                            text: I18n.t("settings_chrome.title")
                            color: Colors.text
                            font.pixelSize: UIScale.fontSubhead
                            font.weight: Font.ExtraBold
                        }
                        Text {
                            text: "zesis"
                            color: Colors.textDim
                            font.pixelSize: UIScale.fontCaption
                            font.family: "monospace"
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
                            onClicked: SettingsPanelService.open = false
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
                    placeholder: I18n.t("settings_chrome.searchPlaceholder")
                    onTextChanged: root.searchText = text
                    onEscapePressed: SettingsPanelService.open = false
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

                        Text {
                            text: I18n.t("settings_chrome.groupAppearance")
                            color: Colors.muted
                            font.pixelSize: UIScale.fontTiny
                            font.weight: Font.Bold
                            font.letterSpacing: 1.5
                            leftPadding: UIScale.spacingSm
                            Layout.bottomMargin: UIScale.spacingXs
                            visible: root.matchesSearch(navAppearanceItem.navLabel) || root.matchesSearch(navWallpaperItem.navLabel)
                        }

                        NavItem {
                            id: navAppearanceItem
                            navId: "appearance"
                            navLabel: I18n.t("settings_chrome.navAppearance")
                            navIcon: "󰘮"
                            isNavSelected: root.section === "appearance"
                            visible: root.matchesSearch(navLabel)
                            Layout.fillWidth: true
                            Layout.bottomMargin: Math.round(2 * UIScale.value)
                        }
                        NavItem {
                            id: navWallpaperItem
                            navId: "wallpaper"
                            navLabel: I18n.t("settings_chrome.navWallpaper")
                            navIcon: ""
                            isNavSelected: root.section === "wallpaper"
                            visible: root.matchesSearch(navLabel)
                            Layout.fillWidth: true
                            Layout.bottomMargin: Math.round(2 * UIScale.value)
                        }

                        Text {
                            text: I18n.t("settings_chrome.groupBarWidgets")
                            color: Colors.muted
                            font.pixelSize: UIScale.fontTiny
                            font.weight: Font.Bold
                            font.letterSpacing: 1.5
                            leftPadding: UIScale.spacingSm
                            Layout.topMargin: UIScale.radiusMd
                            Layout.bottomMargin: UIScale.spacingXs
                            visible: root.matchesSearch(navBarItem.navLabel) || root.matchesSearch(navClockItem.navLabel) || root.matchesSearch(navAppSwitcherItem.navLabel) || root.matchesSearch(navWorkspaceItem.navLabel)
                        }
                        NavItem {
                            id: navBarItem
                            navId: "bar"
                            navLabel: I18n.t("settings_chrome.navBar")
                            navIcon: "󰕪"
                            isNavSelected: root.section === "bar"
                            visible: root.matchesSearch(navLabel)
                            Layout.fillWidth: true
                            Layout.bottomMargin: Math.round(2 * UIScale.value)
                        }
                        NavItem {
                            id: navClockItem
                            navId: "clock"
                            navLabel: I18n.t("settings_chrome.navClock")
                            navIcon: ""
                            isNavSelected: root.section === "clock"
                            visible: root.matchesSearch(navLabel)
                            Layout.fillWidth: true
                            Layout.bottomMargin: Math.round(2 * UIScale.value)
                        }
                        NavItem {
                            id: navAppSwitcherItem
                            navId: "appswitcher"
                            navLabel: I18n.t("settings_chrome.navAppSwitcher")
                            navIcon: ""
                            isNavSelected: root.section === "appswitcher"
                            visible: root.matchesSearch(navLabel)
                            Layout.fillWidth: true
                            Layout.bottomMargin: Math.round(2 * UIScale.value)
                        }
                        NavItem {
                            id: navWorkspaceItem
                            navId: "workspace"
                            navLabel: I18n.t("settings_chrome.navWorkspace")
                            navIcon: ""
                            isNavSelected: root.section === "workspace"
                            visible: root.matchesSearch(navLabel)
                            Layout.fillWidth: true
                            Layout.bottomMargin: Math.round(2 * UIScale.value)
                        }

                        Text {
                            text: I18n.t("settings_chrome.groupDevices")
                            color: Colors.muted
                            font.pixelSize: UIScale.fontTiny
                            font.weight: Font.Bold
                            font.letterSpacing: 1.5
                            leftPadding: UIScale.spacingSm
                            Layout.topMargin: UIScale.radiusMd
                            Layout.bottomMargin: UIScale.spacingXs
                            visible: root.matchesSearch(navDisplayItem.navLabel) || root.matchesSearch(navBluetoothItem.navLabel) || root.matchesSearch(navWifiItem.navLabel) || root.matchesSearch(navSoundItem.navLabel)
                        }
                        NavItem {
                            id: navDisplayItem
                            navId: "display"
                            navLabel: I18n.t("settings_chrome.navDisplay")
                            navIcon: ""
                            isNavSelected: root.section === "display"
                            visible: root.matchesSearch(navLabel)
                            Layout.fillWidth: true
                            Layout.bottomMargin: Math.round(2 * UIScale.value)
                        }
                        NavItem {
                            id: navBluetoothItem
                            navId: "bluetooth"
                            navLabel: I18n.t("settings_chrome.navBluetooth")
                            navIcon: "󰂯"
                            isNavSelected: root.section === "bluetooth"
                            visible: BluetoothService.available && root.matchesSearch(navLabel)
                            Layout.fillWidth: true
                            Layout.bottomMargin: Math.round(2 * UIScale.value)
                        }
                        NavItem {
                            id: navWifiItem
                            navId: "wifi"
                            navLabel: I18n.t("settings_chrome.navWifi")
                            navIcon: "󰤨"
                            isNavSelected: root.section === "wifi"
                            visible: WifiService.available && root.matchesSearch(navLabel)
                            Layout.fillWidth: true
                            Layout.bottomMargin: Math.round(2 * UIScale.value)
                        }
                        NavItem {
                            id: navSoundItem
                            navId: "sound"
                            navLabel: I18n.t("settings_chrome.navSound")
                            navIcon: ""
                            isNavSelected: root.section === "sound"
                            visible: root.matchesSearch(navLabel)
                            Layout.fillWidth: true
                            Layout.bottomMargin: Math.round(2 * UIScale.value)
                        }

                        Text {
                            text: I18n.t("settings_chrome.groupAccount")
                            color: Colors.muted
                            font.pixelSize: UIScale.fontTiny
                            font.weight: Font.Bold
                            font.letterSpacing: 1.5
                            leftPadding: UIScale.spacingSm
                            Layout.topMargin: UIScale.radiusMd
                            Layout.bottomMargin: UIScale.spacingXs
                            visible: root.matchesSearch(navUserItem.navLabel)
                        }
                        NavItem {
                            id: navUserItem
                            navId: "user"
                            navLabel: I18n.t("settings_chrome.navUser")
                            navIcon: ""
                            isNavSelected: root.section === "user"
                            visible: root.matchesSearch(navLabel)
                            Layout.fillWidth: true
                            Layout.bottomMargin: Math.round(2 * UIScale.value)
                        }

                        Text {
                            text: I18n.t("settings_chrome.groupAbout")
                            color: Colors.muted
                            font.pixelSize: UIScale.fontTiny
                            font.weight: Font.Bold
                            font.letterSpacing: 1.5
                            leftPadding: UIScale.spacingSm
                            Layout.topMargin: UIScale.radiusMd
                            Layout.bottomMargin: UIScale.spacingXs
                            visible: root.matchesSearch(navAboutItem.navLabel)
                        }
                        NavItem {
                            id: navAboutItem
                            navId: "about"
                            navLabel: I18n.t("settings_chrome.navAbout")
                            navIcon: ""
                            isNavSelected: root.section === "about"
                            visible: root.matchesSearch(navLabel)
                            Layout.fillWidth: true
                            Layout.bottomMargin: Math.round(2 * UIScale.value)
                        }
                    } // ColumnLayout navColumn
                } // Flickable
            }
        }

        // Content area
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Loader {
                anchors.fill: parent
                active: SettingsPanelService.open
                sourceComponent: {
                    if (root.section === "appearance")
                        return appearancePanelComp;
                    if (root.section === "wallpaper")
                        return wallpaperPanelComp;
                    if (root.section === "bar")
                        return barPanelComp;
                    if (root.section === "clock")
                        return clockPanelComp;
                    if (root.section === "appswitcher")
                        return appSwitcherPanelComp;
                    if (root.section === "workspace")
                        return workspacePanelComp;
                    if (root.section === "display")
                        return displayPanelComp;
                    if (root.section === "bluetooth")
                        return bluetoothPanelComp;
                    if (root.section === "wifi")
                        return wifiPanelComp;
                    if (root.section === "sound")
                        return soundComp;
                    if (root.section === "user")
                        return userPanelComp;
                    if (root.section === "about")
                        return aboutComp;
                    return placeholderComp;
                }
            }

            Component {
                id: appearancePanelComp
                AppearancePanel {}
            }
            Component {
                id: wallpaperPanelComp
                WallpaperPanel {}
            }
            Component {
                id: barPanelComp
                BarPanel {}
            }
            Component {
                id: clockPanelComp
                ClockPanel {}
            }
            Component {
                id: appSwitcherPanelComp
                AppSwitcherPanel {}
            }
            Component {
                id: workspacePanelComp
                WorkspaceIndicatorPanel {}
            }
            Component {
                id: displayPanelComp
                DisplayPanel {}
            }
            Component {
                id: bluetoothPanelComp
                BluetoothPanel {}
            }
            Component {
                id: wifiPanelComp
                WifiPanel {}
            }
            Component {
                id: soundComp
                Sound {}
            }
            Component {
                id: userPanelComp
                UserPanel {}
            }
            Component {
                id: aboutComp
                About {}
            }

            Component {
                id: placeholderComp
                Item {
                    Text {
                        anchors.centerIn: parent
                        text: I18n.t("settings_chrome.comingSoon")
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
