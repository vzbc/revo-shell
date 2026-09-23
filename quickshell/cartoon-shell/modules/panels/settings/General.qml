// components/Settings/GeneralSettings.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.components
import "./general/" as Com
import "./appearance/" as AppCom
import "./" as Bar

Item {
    id: root
    property int currentTab: 0
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

    // Timer để reload ngôn ngữ
    property Timer reloadTimer: Timer {
        interval: 30
        repeat: false
        onTriggered: languageLoader.loadLanguage()
    }

    // Chỉ giữ lại giao diện minimal mode
    ColumnLayout {
        anchors.fill: parent
        spacing: ScalerService.s(10)

        // Top Navigation Bar
        Bar.TopNavigationBar {
            animationProgress: root.animationProgress
            indexCategory: 0
            onCurrentTab: function (index) {
                root.currentTab = index;
            }
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: root.currentTab

            Loader {
                active: root.currentTab === 0
                source: "./general/LanguageRegion.qml"
                onLoaded: {
                    item.visible = Qt.binding(function () {
                        return root.currentTab === 0;
                    });
                }
            }

            // Tab 1: Date & Time
            ScrollView {
                clip: true
                ScrollBar.vertical.policy: ScrollBar.AsNeeded

                ColumnLayout {
                    width: parent.width
                    spacing: ScalerService.s(20)
                    anchors.margins: ScalerService.s(20)

                    Text {
                        text: lang?.general?.date_time || "Date & Time"
                        color: theme.primary.foreground
                        font {
                            family: "ComicShannsMono Nerd Font"
                            pixelSize: ScalerService.s(24)
                            bold: true
                        }
                        Layout.alignment: Qt.AlignLeft
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: ScalerService.s(1)
                        color: theme.primary.foreground
                        opacity: 0.3
                    }

                    // Nội dung Date & Time ở đây
                    Text {
                        text: "Date & Time settings content"
                        color: theme.primary.foreground
                        Layout.alignment: Qt.AlignLeft
                        font.pixelSize: ScalerService.s(14)
                    }
                }
            }

            // Tab 2: Session
            ScrollView {
                clip: true
                ScrollBar.vertical.policy: ScrollBar.AsNeeded

                ColumnLayout {
                    width: parent.width
                    spacing: ScalerService.s(20)
                    anchors.margins: ScalerService.s(20)

                    Text {
                        text: lang?.general?.session || "Session"
                        color: theme.primary.foreground
                        font {
                            family: "ComicShannsMono Nerd Font"
                            pixelSize: ScalerService.s(24)
                            bold: true
                        }
                        Layout.alignment: Qt.AlignLeft
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: ScalerService.s(1)
                        color: theme.primary.foreground
                        opacity: 0.3
                    }

                    // Nội dung Session ở đây
                    Text {
                        text: "Session settings content"
                        color: theme.primary.foreground
                        Layout.alignment: Qt.AlignLeft
                        font.pixelSize: ScalerService.s(14)
                    }
                }
            }

            // Tab 3: Behavior
            ScrollView {
                clip: true
                ScrollBar.vertical.policy: ScrollBar.AsNeeded

                ColumnLayout {
                    width: parent.width
                    spacing: ScalerService.s(20)
                    anchors.margins: ScalerService.s(20)

                    Text {
                        text: lang?.general?.behavior || "Behavior"
                        color: theme.primary.foreground
                        font {
                            family: "ComicShannsMono Nerd Font"
                            pixelSize: ScalerService.s(24)
                            bold: true
                        }
                        Layout.alignment: Qt.AlignLeft
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: ScalerService.s(1)
                        color: theme.primary.foreground
                        opacity: 0.3
                    }

                    // Nội dung Behavior ở đây
                    Text {
                        text: "Behavior settings content"
                        color: theme.primary.foreground
                        Layout.alignment: Qt.AlignLeft
                        font.pixelSize: ScalerService.s(14)
                    }
                }
            }

            // Tab 4: Notifications
            ScrollView {
                clip: true
                ScrollBar.vertical.policy: ScrollBar.AsNeeded

                ColumnLayout {
                    width: parent.width
                    spacing: ScalerService.s(20)
                    anchors.margins: ScalerService.s(20)

                    Text {
                        text: lang?.general?.notifications || "Notifications"
                        color: theme.primary.foreground
                        font {
                            family: "ComicShannsMono Nerd Font"
                            pixelSize: ScalerService.s(24)
                            bold: true
                        }
                        Layout.alignment: Qt.AlignLeft
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: ScalerService.s(1)
                        color: theme.primary.foreground
                        opacity: 0.3
                    }

                    // Nội dung Notifications ở đây
                    Text {
                        text: "Notifications settings content"
                        color: theme.primary.foreground
                        Layout.alignment: Qt.AlignLeft
                        font.pixelSize: ScalerService.s(14)
                    }
                }
            }

            // Tab 5: Privacy
            ScrollView {
                clip: true
                ScrollBar.vertical.policy: ScrollBar.AsNeeded

                ColumnLayout {
                    width: parent.width
                    spacing: ScalerService.s(20)
                    anchors.margins: ScalerService.s(20)

                    Text {
                        text: lang?.general?.privacy || "Privacy"
                        color: theme.primary.foreground
                        font {
                            family: "ComicShannsMono Nerd Font"
                            pixelSize: ScalerService.s(24)
                            bold: true
                        }
                        Layout.alignment: Qt.AlignLeft
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: ScalerService.s(1)
                        color: theme.primary.foreground
                        opacity: 0.3
                    }

                    // Nội dung Privacy ở đây
                    Text {
                        text: "Privacy settings content"
                        color: theme.primary.foreground
                        Layout.alignment: Qt.AlignLeft
                        font.pixelSize: ScalerService.s(14)
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        console.log("GeneralSettings loaded");
    }
}
