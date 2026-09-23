import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.services
import qs.commons
import qs.components

// Import các thành phần phụ trong cùng thư mục
import "../../../components/" as Components
import "./" as LauncherComponents

PanelWindow {
    id: root
    property real animationProgress: 0
    SequentialAnimation on animationProgress {
        running: true

        NumberAnimation {
            from: 0
            to: 1
            duration: 500
            easing.type: Easing.Linear
        }
    }

    implicitWidth: {
        if (VisibleService.setting) {
            return ScalerService.s(1000);
        } else {
            return ScalerService.s(600);
        }
    }
    implicitHeight: {
        if (VisibleService.setting) {
            return ScalerService.s(700);
        } else {
            return ScalerService.s(640);
        }
    }
    color: "transparent"
    focusable: true

    signal confirmRequested(string action, string actionLabel)

    Behavior on width {
        NumberAnimation {
            duration: 60
        }
    }
    Behavior on height {
        NumberAnimation {
            duration: 60
        }
    }

    property bool settingsPanelVisible: false
    property bool rootVisible: true

    // Sửa hàm closePanel

    function togglePanel() {
        root.visible = !launcherPanel.visible;
        if (root.visible) {
            openLauncher();
        }
    }

    anchors {
        // Xác định vị trí anchor dựa trên position của bar
        left: (Settings.bar.position === "left" || Settings.bar.position === "top" || Settings.bar.position === "bottom")
        right: Settings.bar.position === "right"
        top: (Settings.bar.position === "top" || Settings.bar.position === "left" || Settings.bar.position === "right")
        bottom: Settings.bar.position === "bottom"
    }

    margins {
        top: Settings.bar.position === "top" || Settings.bar.position === "left" || Settings.bar.position === "right" ? ScalerService.s(10) : 0
        bottom: Settings.bar.position === "bottom" ? ScalerService.s(10) : 0
        left: (Settings.bar.position === "left" || Settings.bar.position === "top" || Settings.bar.position === "bottom") ? ScalerService.s(10) : 0
        right: Settings.bar.position === "right" ? ScalerService.s(10) : 0
    }

    // Focus scope để quản lý focus
    Rectangle {
        anchors.top: Settings.bar.position == "top" ? parent.top : false
        anchors.left: Settings.bar.position == "left" ? parent.left : false
        anchors.bottom: Settings.bar.position === "bottom" ? parent.bottom : false
        anchors.right: Settings.bar.position === "right" ? parent.right : false
        implicitWidth: root.animationProgress > 0 ? parent.width : 0
        implicitHeight: root.animationProgress > 0 ? parent.height : 0
        Behavior on implicitHeight {
            NumberAnimation {
                id: heightAnim
                duration: 500
                easing.type: Easing.OutCubic
            }
        }
        Behavior on implicitWidth {
            NumberAnimation {
                id: widthAnim
                duration: 500
                easing.type: Easing.OutCubic
            }
        }
        Loader {
            anchors.fill: parent

            active: !heightAnim.running && !widthAnim.running

            sourceComponent: FloatingCircles {
                circleColor: theme.button.text
                anchors.fill: parent
                circleCount: 4
            }
        }
        radius: ScalerService.s(Settings.appearance.radius1)
        color: theme.primary.background
        border.color: theme.button.border
        border.width: Settings.appearance.enableBorder ? ScalerService.s(3) : 0

        ColumnLayout {
            anchors.fill: parent
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: {
                        if (VisibleService.fullsetting && settingsPanelVisible) {
                            return ScalerService.s(20); // Margin lớn hơn khi full screen
                        }
                        return ScalerService.s(16);
                    }
                    spacing: ScalerService.s(12)

                    LauncherComponents.Sidebar {
                        id: sidebar
                        visible: !(VisibleService.fullsetting && VisibleService.setting)
                        onConfirmRequested: (action, actionLabel) => {
                            root.confirmRequested(action, actionLabel);
                        }
                    }

                    Loader {
                        id: settingsPanelLoader
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        active: VisibleService.setting
                        source: "../settings/SettingsPanel.qml"
                        onLoaded: {
                            item.root = launcherPanel;
                            item.visible = Qt.binding(function () {
                                return VisibleService.setting;
                            });
                        }
                    }

                    ColumnLayout {
                        visible: !VisibleService.setting
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: ScalerService.s(10)

                        CustomText {
                            text: lang.system.application
                            isBold: true
                            Layout.alignment: Qt.AlignHCenter
                            size: "2xl"
                            opacity: root.animationProgress > 0.2 ? 1 : 0
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 200
                                }
                            }
                        }

                        LauncherComponents.LauncherSearch {
                            id: searchBox
                            onSearchChanged: text => launcherList.runSearch(text)
                            onAccepted: text => launcherList.runSearch(text)
                            opacity: root.animationProgress > 0.3 ? 1 : 0
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 200
                                }
                            }
                        }

                        LauncherComponents.LauncherList {
                            id: launcherList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            opacity: root.animationProgress > 0.4 ? 1 : 0
                            animationProgress: root.animationProgress
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 200
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Khi panel trở nên visible, focus vào search field
    onVisibleChanged: {
        if (visible && rootVisible) {
            Qt.callLater(function () {
                if (searchBox && searchBox.searchField) {
                    searchBox.searchField.forceActiveFocus();
                    searchBox.searchField.selectAll();
                }
            });
        }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: VisibleService.togglePanel("launcher")
    }

    Component.onCompleted: {
        // Đảm bảo panel không visible khi khởi động
        visible = false;
    }
}
