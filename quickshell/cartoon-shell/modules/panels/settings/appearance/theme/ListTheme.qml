import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import qs.commons
import qs.components
import qs.services

ColumnLayout {
    id: root
    width: parent.width
    spacing: ScalerService.s(15)
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

    CustomText {
        text: "Preset Themes"
        color: theme.primary ? theme.primary.foreground : "#d8dee9"
        opacity: root.animationProgress > 0.1 ? 1 : 0
        size: "small"
        Behavior on opacity {
            NumberAnimation {
                duration: 200
            }
        }
        isBold: true
        Layout.alignment: Qt.AlignLeft
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 3  // Đã sửa từ: panelManager.fullsetting ? 5 : 3
        columnSpacing: ScalerService.s(10)  // Đã sửa từ: panelManager.fullsetting ? 15 : 10
        rowSpacing: ScalerService.s(10)  // Đã sửa từ: panelManager.fullsetting ? 15 : 10

        Repeater {
            model: [
                {
                    name: "Auto",
                    type: "matugen",
                    accent: "black"
                },
                {
                    name: "Macchiato",
                    type: "macchiato",
                    accent: "#24273a"
                },
                {
                    name: "Gruvbox",
                    type: "gruvbox",
                    accent: "#f5eee6"
                },
                {
                    name: "Tokyo Storm",
                    type: "tokyonightStorm",
                    accent: "#7aa2f7"
                },
                {
                    name: "Nord",
                    type: "nord",
                    accent: "#88c0d0"
                },
                {
                    name: "Dracula",
                    type: "dracula",
                    accent: "#BD93F9"
                },
                {
                    name: "One dark",
                    type: "one_dark",
                    accent: "#61AFEF"
                }
            ]

            delegate: Rectangle {
                id: themeDelegate
                Layout.fillWidth: true
                Layout.preferredHeight: ScalerService.s(60)
                radius: ScalerService.s(8)

                opacity: 0

                SequentialAnimation on opacity {
                    running: root.animationProgress > 0.6

                    PauseAnimation {
                        duration: index * 50
                    }

                    NumberAnimation {
                        to: 1
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                }
                color: Settings.appearance.theme === modal.type ? Qt.alpha(theme.button.text, 0.6) : (themeMouseArea.containsMouse ? Qt.alpha(theme.button.background_select, 0.6) : Qt.alpha(theme.button.background, 0.6))
                border.color: Settings.appearance.theme === modal.type ? Qt.alpha(theme.button.text, 0.6) : (themeMouseArea.containsPress ? Qt.alpha(theme.button.border_select, 0.6) : Qt.alpha(theme.button.border, 0.6))
                border.width: Settings.appearance.enableBorder ? ScalerService.s(2) : 0
                property var modal: ({
                        name: modelData.name,
                        type: modelData.type,
                        accent: modelData.accent
                    })

                MouseArea {
                    id: themeMouseArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        SoundService.playSound("pick");
                        if (Settings.appearance.theme !== modal.type) {
                            Settings.appearance.theme = modal.type;

                            if (modal.type === "matugen") {
                                Settings.appearance.dynamic = true;
                            } else {
                                Settings.appearance.dynamic = false;
                            }

                            // Không cần gọi reloadTimer vì ThemeService sẽ tự động load
                            console.log("Theme changed to:", modal.type, "dynamic:", Settings.appearance.dynamic);
                        }
                    }
                }

                // ✔ checkmark theme đang active
                Rectangle {
                    visible: Settings.appearance.theme === modal.type
                    width: ScalerService.s(20)
                    height: ScalerService.s(20)
                    radius: ScalerService.s(10)
                    color: theme.button.text
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: ScalerService.s(5)

                    IconText {
                        name: "check"
                        size: "xs"
                        textColor: theme.primary.background
                        anchors.centerIn: parent
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: ScalerService.s(10)
                    spacing: ScalerService.s(10)

                    Rectangle {
                        Layout.preferredWidth: ScalerService.s(40)
                        Layout.preferredHeight: ScalerService.s(40)
                        radius: ScalerService.s(6)
                        color: modal.accent
                    }

                    CustomText {
                        name: modal.name
                        color: theme.primary ? theme.primary.foreground : "#d8dee9"
                        wrapMode: Text.WordWrap
                        width: ScalerService.s(40)
                        horizontalAlignment: Text.AlignLeft
                        isBold: true
                        size: "xs"
                    }
                }
            }
        }
    }
}
