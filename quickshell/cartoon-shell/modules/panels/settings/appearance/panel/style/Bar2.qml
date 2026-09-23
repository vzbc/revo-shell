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
            if (Settings.bar.style === "style2") {
                return Qt.alpha(theme.button.text, 0.15);
            }
            return mouseArea.containsMouse ? Qt.alpha(theme.button.background_select, 0.4) : Qt.alpha(theme.button.background, 0.2);
        }
        border.width: Settings.appearance.enableBorder ? ScalerService.s(2) : 0

        RowLayout {
            anchors.margins: ScalerService.s(8)
            spacing: ScalerService.s(8)
            anchors.fill: parent
            opacity: Settings.bar.style === "style2" ? 0.6 : 1
            CustomRectangle {
                anchors.fill: parent
                radius: ScalerService.s(Settings.appearance.radius3)
                color: theme.primary.background
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: ScalerService.s(5)
                    IconText {
                        name: "󰣇"
                        textColor: theme.button.text
                        size: "small"
                        fontFamily: "Symbols Nerd Font"
                        Layout.alignment: Qt.AlignVCenter
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                    CustomRectangle {
                        color: theme.primary.dim_background
                        implicitWidth: ScalerService.s(35)
                        radius: ScalerService.s(Settings.appearance.radius2)
                        Layout.fillHeight: true
                        RowLayout {
                            id: contentRam
                            anchors.centerIn: parent
                            IconText {
                                name: " "
                                fontFamily: "Symbols Nerd Font"
                                textColor: theme.normal.green
                                size: "xs"
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }
                    }
                    CustomRectangle {
                        color: theme.primary.dim_background
                        implicitWidth: ScalerService.s(35)
                        radius: ScalerService.s(Settings.appearance.radius2)
                        Layout.fillHeight: true
                        RowLayout {
                            id: contentCpu
                            anchors.centerIn: parent
                            IconText {
                                name: ""
                                fontFamily: "Symbols Nerd Font"
                                textColor: theme.normal.red
                                size: "xs"
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }
                    }
                    CustomRectangle {
                        color: theme.primary.dim_background
                        implicitWidth: ScalerService.s(60)
                        radius: ScalerService.s(Settings.appearance.radius2)
                        Layout.fillHeight: true
                        RowLayout {

                            spacing: ScalerService.s(2)

                            IconText {
                                name: "skip_previous"
                                size: "xs"

                                textColor: theme.normal.blue
                                Layout.alignment: Qt.AlignVCenter
                            }
                            IconText {
                                name: Players.mprisPlayer && Players.mprisPlayer.isPlaying ? "pause" : "play_arrow"
                                size: "xs"

                                Layout.alignment: Qt.AlignVCenter
                                textColor: theme.normal.green
                            }
                            IconText {
                                name: "skip_next"
                                size: "xs"
                                textColor: theme.normal.blue

                                Layout.alignment: Qt.AlignVCenter
                            }
                        }
                    }
                    CustomRectangle {
                        Layout.preferredWidth: ScalerService.s(120)
                        color: theme.primary.dim_background
                        radius: ScalerService.s(8)
                        Layout.fillHeight: true
                        RowLayout {
                            spacing: ScalerService.s(2)
                            anchors.fill: parent
                            IconText {
                                name: "󰮯"
                                fontFamily: "Symbols Nerd Font"
                                Layout.alignment: Qt.AlignVCenter
                                size: "xs"
                                textColor: theme.normal.yellow
                            }
                            Item {
                                Layout.fillWidth: true
                            }
                            IconText {
                                name: "󰊠"
                                fontFamily: "Symbols Nerd Font"
                                Layout.alignment: Qt.AlignVCenter
                                textColor: theme.normal.blue
                                size: "xs"
                            }
                            Item {
                                Layout.fillWidth: true
                            }
                            IconText {
                                name: "󰊠"
                                fontFamily: "Symbols Nerd Font"
                                Layout.alignment: Qt.AlignVCenter
                                textColor: theme.normal.blue
                                size: "xs"
                            }
                            Item {
                                Layout.fillWidth: true
                            }
                            IconText {
                                name: ""
                                fontFamily: "Symbols Nerd Font"
                                Layout.alignment: Qt.AlignVCenter
                                textColor: theme.primary.dim_foreground
                                size: "xs"
                            }
                            Item {
                                Layout.fillWidth: true
                            }
                            IconText {
                                name: ""
                                fontFamily: "Symbols Nerd Font"
                                Layout.alignment: Qt.AlignVCenter
                                textColor: theme.primary.dim_foreground
                                size: "xs"
                            }
                        }
                    }
                    CustomText {
                        name: "9:50"
                        size: "xs"
                    }
                    CustomRectangle {
                        color: theme.primary.dim_background
                        implicitWidth: ScalerService.s(22)
                        radius: ScalerService.s(Settings.appearance.radius2)
                        Layout.fillHeight: true
                        IconText {
                            anchors.centerIn: parent
                            name: "brightness_4"
                            Layout.alignment: Qt.AlignVCenter
                            size: "xs"
                        }
                    }
                    CustomRectangle {
                        color: theme.primary.dim_background
                        implicitWidth: ScalerService.s(22)
                        radius: ScalerService.s(Settings.appearance.radius2)
                        Layout.fillHeight: true
                        IconText {
                            anchors.centerIn: parent
                            name: "battery_android_frame_4"
                            Layout.alignment: Qt.AlignVCenter
                            size: "xs"
                        }
                    }
                    CustomRectangle {
                        color: theme.primary.dim_background
                        implicitWidth: ScalerService.s(22)
                        radius: ScalerService.s(Settings.appearance.radius2)
                        Layout.fillHeight: true
                        IconText {
                            anchors.centerIn: parent
                            name: "android_wifi_3_bar"
                            textColor: theme.normal.blue
                            Layout.alignment: Qt.AlignVCenter
                            size: "xs"
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }
                    IconText {
                        name: "󰐥"
                        size: "small"
                        textColor: theme.normal.red
                        fontFamily: "Symbols Nerd Font"
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
            }
        }

        border.color: {
            if (Settings.bar.style === "style2") {
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
                Settings.bar.style = "style2";
                Settings.bar.styleWorkspace = "icon";
                Settings.bar.iconWorkspace = "pac_man";
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
