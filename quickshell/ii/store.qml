//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.win
import qs.modules.store

/**
 * Windows 11 style Store for illogical-impulse.
 * Sources: Flathub, Arch repositories and the AUR.
 */
ApplicationWindow {
    id: root

    property var pages: [
        { name: "Home", icon: "home", component: "modules/store/StoreHome.qml" },
        { name: "Apps", icon: "grid_view", component: "modules/store/StoreBrowse.qml" },
        { name: "Library", icon: "collections_bookmark", component: "modules/store/StoreLibrary.qml" }
    ]
    property int currentPage: 0
    property bool maximized: false
    property string searchText: ""
    property bool inSearch: false
    property var currentApp: null
    property bool inDetail: false

    visible: true
    onClosing: Qt.quit()
    title: "Store"

    Component.onCompleted: {
        MaterialThemeLoader.reapplyTheme()
        WinTheme.apply()
        StoreCatalog.ensureCatalog()
    }

    minimumWidth: 900
    minimumHeight: 600
    width: 1180
    height: 780
    color: WinTheme.bg

    function contentSource() {
        if (root.inDetail && root.currentApp)
            return "modules/store/StoreProduct.qml"
        if (root.inSearch)
            return "modules/store/StoreSearch.qml"
        return root.pages[root.currentPage].component
    }
    function openApp(app) {
        StoreCatalog.currentApp = app
        root.currentApp = app
        root.inDetail = true
    }
    function goToPage(index) {
        root.inDetail = false
        root.currentApp = null
        root.inSearch = false
        root.currentPage = index
    }
    function doSearch() {
        const q = root.searchText.trim()
        if (q.length === 0) {
            root.inSearch = false
            return
        }
        StoreCatalog.activeQuery = q
        StoreCatalog.aurSearch(q)
        root.inDetail = false
        root.currentApp = null
        root.inSearch = true
    }
    function goBack() {
        if (root.inDetail) {
            root.inDetail = false
            root.currentApp = null
        } else if (root.inSearch) {
            root.inSearch = false
            root.searchText = ""
        } else {
            root.currentPage = 0
        }
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
                visible: root.inDetail || root.inSearch || root.currentPage !== 0
                iconText: "arrow_back"
                onClicked: root.goBack()
            }

            StyledText {
                text: "Store"
                color: WinTheme.text
                font.pixelSize: 14
                font.weight: Font.DemiBold
            }

            Item { Layout.fillWidth: true }

            WinSearchField {
                Layout.preferredWidth: 230
                placeholder: "Search apps"
                text: root.searchText
                onTextChanged: {
                    root.searchText = text
                    if (text.trim().length === 0 && root.inSearch)
                        root.inSearch = false
                }
                onAccepted: root.doSearch()
            }

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

        // ---------------------------------------------------------- nav rail
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 64
            color: WinTheme.bgAlt

            Rectangle {
                anchors.right: parent.right
                width: 1
                height: parent.height
                color: WinTheme.border
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.topMargin: 10
                anchors.leftMargin: 6
                anchors.rightMargin: 6
                spacing: 4

                Repeater {
                    model: root.pages
                    Rectangle {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        Layout.preferredHeight: 52
                        radius: 6
                        color: root.currentPage === index && !root.inDetail && !root.inSearch
                            ? WinTheme.cardAlt : (hover.hovered ? WinTheme.card : "transparent")
                        HoverHandler { id: hover }
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 2
                            MaterialSymbol {
                                Layout.alignment: Qt.AlignHCenter
                                text: modelData.icon
                                iconSize: 18
                                color: root.currentPage === index && !root.inDetail && !root.inSearch
                                    ? WinTheme.accent : WinTheme.textSecondary
                            }
                            StyledText {
                                Layout.alignment: Qt.AlignHCenter
                                text: modelData.name
                                color: root.currentPage === index && !root.inDetail && !root.inSearch
                                    ? WinTheme.text : WinTheme.textTertiary
                                font.pixelSize: 9
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.goToPage(index)
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    radius: 6
                    color: hover2.hovered ? WinTheme.card : "transparent"
                    HoverHandler { id: hover2 }
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 2
                        MaterialSymbol {
                            Layout.alignment: Qt.AlignHCenter
                            text: "refresh"
                            iconSize: 18
                            color: StoreCatalog.generating ? WinTheme.accent : WinTheme.textSecondary
                        }
                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Update"
                            color: WinTheme.textTertiary
                            font.pixelSize: 9
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: StoreCatalog.ensureCatalog()
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
                source: root.contentSource()

                Connections {
                    target: pageLoader.item
                    function onOpenAppRequested(app) { root.openApp(app) }
                    function onSearchRequested(text) {
                        root.searchText = text
                        root.doSearch()
                    }
                    function onBrowseRequested() { root.goToPage(1) }
                }

                Connections {
                    target: root
                    function onCurrentPageChanged() { switchAnim.restart() }
                    function onInSearchChanged() { switchAnim.restart() }
                    function onInDetailChanged() { switchAnim.restart() }
                    function onCurrentAppChanged() { if (root.inDetail) switchAnim.restart() }
                }

                SequentialAnimation {
                    id: switchAnim
                    running: false
                    NumberAnimation {
                        target: pageLoader
                        properties: "opacity"
                        from: 1
                        to: 0
                        duration: 70
                        easing.type: Easing.OutCubic
                    }
                    PropertyAction {
                        target: pageLoader
                        property: "source"
                        value: root.contentSource()
                    }
                    NumberAnimation {
                        target: pageLoader
                        properties: "opacity"
                        from: 0
                        to: 1
                        duration: 150
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
    }
}
