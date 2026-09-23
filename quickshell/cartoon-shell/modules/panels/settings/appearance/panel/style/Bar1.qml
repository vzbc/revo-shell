import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components
import qs.commons

Item {
    id: root
    Layout.fillWidth: true
    Layout.preferredHeight: ScalerService.s(50)
    CustomRectangle {
        id: container
        anchors.fill: parent
        anchors.margins: ScalerService.s(2)
        radius: ScalerService.s(12)

        color: {
            if (Settings.bar.style === "style1") {
                return Qt.alpha(theme.button.text, 0.15);
            }
            return mouseArea.containsMouse ? Qt.alpha(theme.button.background_select, 0.4) : Qt.alpha(theme.button.background, 0.2);
        }
        border.width: Settings.appearance.enableBorder ? ScalerService.s(2) : 0

        RowLayout {
            anchors.margins: ScalerService.s(8)
            anchors.fill: parent
            opacity: Settings.bar.style === "style1" ? 0.6 : 1
            CustomRectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: ScalerService.s(25)
                radius: ScalerService.s(Settings.appearance.radius3)
                color: theme.primary.background
                IconImage {
                    path: "launcher/dashboard.png"
                    size: "small"
                    anchors.centerIn: parent
                }
            }
            CustomRectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: ScalerService.s(90)
                radius: ScalerService.s(Settings.appearance.radius3)
                color: theme.primary.background
                RowLayout {
                    spacing: ScalerService.s(2)
                    anchors.fill: parent
                    IconImage {
                        path: "workspace/pacman/active.png"
                        size: "small"
                    }
                    IconImage {
                        path: "workspace/pacman/exists.png"
                        size: "small"
                    }
                    IconImage {
                        path: "workspace/pacman/exists.png"
                        size: "small"
                    }
                    IconImage {
                        path: "workspace/empty.png"
                        size: "small"
                    }
                }
            }
            CustomRectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: ScalerService.s(80)
                radius: ScalerService.s(Settings.appearance.radius3)
                color: theme.primary.background
                RowLayout {
                    anchors.fill: parent
                    IconText {
                        size: "small"
                        name: "skip_previous"
                    }
                    IconText {
                        size: "small"
                        name: "pause"
                    }
                    IconText {
                        size: "small"
                        name: "skip_next"
                    }
                }
            }
            CustomRectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: ScalerService.s(100)
                radius: ScalerService.s(Settings.appearance.radius3)
                color: theme.primary.background
                RowLayout {
                    anchors.fill: parent
                    CustomText {
                        name: "6:50"
                        size: "small"
                        Layout.alignment: Qt.AlignVCenter
                    }
                    IconImage {
                        path: "weather/icon_weather_status/cloudy_sunny.png"
                        Layout.alignment: Qt.AlignVCenter
                        size: "small"
                    }
                    IconImage {
                        path: `flags/${Settings.appearance.countryFlag}.png`
                        Layout.alignment: Qt.AlignVCenter
                        size: "small"
                    }
                }
            }
            CustomRectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: ScalerService.s(50)
                radius: ScalerService.s(Settings.appearance.radius3)
                color: theme.primary.background
                RowLayout {
                    anchors.fill: parent
                    IconImage {
                        path: "cpu/cpu.png"
                        Layout.alignment: Qt.AlignVCenter
                        size: "small"
                    }
                    IconImage {
                        path: "panel/memory.png"
                        size: "small"
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
            }
            CustomRectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: ScalerService.s(85)
                radius: ScalerService.s(Settings.appearance.radius3)
                color: theme.primary.background
                RowLayout {
                    anchors.fill: parent
                    IconImage {
                        path: "wifi/wifi.png"
                        size: "small"
                        Layout.alignment: Qt.AlignVCenter
                    }
                    IconImage {
                        path: "volume/volume.png"
                        size: "small"
                        Layout.alignment: Qt.AlignVCenter
                    }
                    IconImage {
                        path: "system/poweroff.png"
                        size: "small"
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
            }
            Item {
                Layout.fillWidth: true
            }
        }

        border.color: {
            if (Settings.bar.style === "style1") {
                return Qt.alpha(theme.button.text, 0.8);
            }
            return mouseArea.containsPress ? Qt.alpha(theme.button.border_select, 0.6) : Qt.alpha(theme.button.border, 0.3);
        }

        Behavior on color {
            ColorAnimation {
                duration: 200
            }
        }
        Behavior on border.color {
            ColorAnimation {
                duration: 200
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onClicked: {
                SoundService.playSound("pick");
                Settings.bar.style = "style1";
                Settings.bar.styleWorkspace = "image";
                Settings.bar.iconWorkspace = "pacman";
            }
        }

        SequentialAnimation on opacity {
            running: root.animationProgress > 0.1
            NumberAnimation {
                from: 0
                to: 1
                duration: 300
                easing.type: Easing.OutCubic
            }
        }

        SequentialAnimation on scale {
            running: root.animationProgress > 0.1
            NumberAnimation {
                from: 0.5
                to: 1.0
                duration: 400
                easing.type: Easing.OutBack
            }
        }
    }
}
