//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Qt5Compat.GraphicalEffects
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions as CF
import qs.modules.win

/**
 * Windows 11 style Settings for illogical-impulse.
 */
ApplicationWindow {
    id: root
    property string firstRunFilePath: CF.FileUtils.trimFileProtocol(`${Directories.state}/user/first_run.txt`)
    property string firstRunFileContent: "This file is just here to confirm you've been greeted :>"
    property real contentPadding: 0
    property bool showNextTime: false

    property var pages: [
        { name: "Home", icon: "home", component: "modules/settings/Home.qml" },
        { name: "Quick", icon: "bolt", component: "modules/settings/QuickConfig.qml" },
        { name: "General", icon: "tune", component: "modules/settings/GeneralConfig.qml" },
        { name: "Bar", icon: "view_sidebar", component: "modules/settings/BarConfig.qml" },
        { name: "Background", icon: "wallpaper", component: "modules/settings/BackgroundConfig.qml" },
        { name: "Interface", icon: "dashboard_customize", component: "modules/settings/InterfaceConfig.qml" },
        { name: "Services", icon: "extension", component: "modules/settings/ServicesConfig.qml" },
        { name: "Advanced", icon: "engineering", component: "modules/settings/AdvancedConfig.qml" },
        { name: "About", icon: "info", component: "modules/settings/About.qml" }
    ]
    property int currentPage: 0
    property string searchText: ""
    property bool maximized: false

    visible: true
    onClosing: Qt.quit()
    title: "Settings"

    Component.onCompleted: {
        MaterialThemeLoader.reapplyTheme()
        WinTheme.apply()
        Config.readWriteDelay = 0
    }

    minimumWidth: 900
    minimumHeight: 600
    width: 1180
    height: 780
    color: WinTheme.bg


    function pageIndex(name) {
        return root.pages.findIndex(p => p.name === name)
    }
    function openPage(name) {
        const idx = root.pageIndex(name)
        if (idx >= 0) root.currentPage = idx
    }

    // ------------------------------------------------------------- titlebar
    Rectangle {
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        height: 44
        color: WinTheme.bgAlt
        z: 2

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 4
            spacing: 8

            WinTitleBarButton {
                visible: root.currentPage !== 0
                iconText: "arrow_back"
                onClicked: root.currentPage = 0
            }

            StyledText {
                text: "Settings"
                color: WinTheme.text
                font.pixelSize: 14
                font.weight: Font.DemiBold
            }

            Item { Layout.fillWidth: true }

            WinTitleBarButton {
                iconText: "minimize"
                onClicked: root.showMinimized()
            }
            WinTitleBarButton {
                iconText: root.maximized ? "crop_square" : "fullscreen"
                onClicked: {
                    root.maximized ? root.showNormal() : root.showMaximized()
                    root.maximized = !root.maximized
                }
            }
            WinTitleBarButton {
                iconText: "close"
                close: true
                onClicked: root.close()
            }
        }
    }

    // --------------------------------------------------------------- content
    RowLayout {
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
            right: parent.right
            topMargin: 44
        }
        spacing: 0

        // ---------------------------------------------------------- sidebar
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 250
            color: WinTheme.bgAlt

            Rectangle {
                anchors.right: parent.right
                width: 1
                height: parent.height
                color: WinTheme.border
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                anchors.topMargin: 14
                anchors.bottomMargin: 12
                spacing: 4

                // ------------------------------------------- account (Win11)
                RowLayout {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 12
                    spacing: 10

                    Item {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32

                        Image {
                            id: accountAvatar
                            anchors.fill: parent
                            sourceSize: Qt.size(32, 32)
                            source: Directories.userAvatarPathAccountsService
                            layer.enabled: true
                            layer.effect: OpacityMask {
                                maskSource: Circle {
                                    diameter: accountAvatar.height
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        StyledText {
                            text: SystemInfo.username.charAt(0).toUpperCase() + SystemInfo.username.slice(1)
                            color: WinTheme.text
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        StyledText {
                            text: "Account"
                            color: WinTheme.textSecondary
                            font.pixelSize: 11
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    MaterialSymbol {
                        text: "chevron_right"
                        iconSize: 18
                        color: WinTheme.textSecondary
                    }
                }

                WinSearchField {
                    id: searchField
                    Layout.fillWidth: true
                    Layout.bottomMargin: 10
                    placeholder: "Find a setting"
                    text: root.searchText
                    onTextChanged: root.searchText = text
                }

                ColumnLayout {
                    id: sidebarList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 2

                    Repeater {
                        model: filteredPages
                        WinSidebarItem {
                            required property var modelData
                            Layout.fillWidth: true
                            iconText: modelData.icon
                            label: modelData.name
                            selected: root.currentPage === root.pageIndex(modelData.name)
                            onClicked: {
                                root.openPage(modelData.name)
                                root.searchText = ""
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Rectangle {
                            Layout.preferredWidth: 30
                            Layout.preferredHeight: 30
                            radius: 15
                            color: WinTheme.accent
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: "computer"
                                iconSize: 16
                                color: "#ffffff"
                            }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            StyledText {
                                text: SystemDetails.hostname
                                color: WinTheme.text
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            StyledText {
                                text: SystemInfo.distroName
                                color: WinTheme.textSecondary
                                font.pixelSize: 10
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
            }
        }

        // ----------------------------------------------------- content pane
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: WinTheme.bg

            Loader {
                id: pageLoader
                anchors.fill: parent

                active: Config.ready
                Component.onCompleted: {
                    source = root.pages[0].component
                }

                Connections {
                    target: root
                    function onCurrentPageChanged() {
                        switchAnim.complete()
                        switchAnim.start()
                    }
                }

                Connections {
                    target: pageLoader.item
                    function onNavigateRequested(pageName) {
                        root.openPage(pageName)
                    }
                }

                SequentialAnimation {
                    id: switchAnim
                    NumberAnimation {
                        target: pageLoader
                        properties: "opacity"
                        from: 1
                        to: 0
                        duration: 80
                        easing.type: Easing.OutCubic
                    }
                    ParallelAnimation {
                        PropertyAction {
                            target: pageLoader
                            property: "source"
                            value: root.pages[root.currentPage].component
                        }
                    }
                    NumberAnimation {
                        target: pageLoader
                        properties: "opacity"
                        from: 0
                        to: 1
                        duration: 160
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
    }

    // Filtered sidebar list when searching
    readonly property var filteredPages: {
        const q = root.searchText.trim().toLowerCase()
        if (q.length === 0)
            return root.pages
        return root.pages.filter(p => p.name.toLowerCase().includes(q))
    }

    Shortcut {
        sequence: "Ctrl+PageDown"
        onActivated: root.currentPage = Math.min(root.currentPage + 1, root.pages.length - 1)
    }
    Shortcut {
        sequence: "Ctrl+PageUp"
        onActivated: root.currentPage = Math.max(root.currentPage - 1, 0)
    }
}
