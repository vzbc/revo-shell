import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import Quickshell.Services.Pipewire
import QtQuick.Effects
import qs.commons
import qs.services
import qs.components
import "../../widget/" as Com

RowLayout {
    id: root
    property real animationProgress: 0

    readonly property var sink: Pipewire.defaultAudioSink
    function getIcon(volPercent) {
        if (volPercent < 10)
            return "volume_mute";
        if (volPercent < 60)
            return "volume_down";
        return "volume_up";
    }
    function getBatteryIcon(level, status) {
        if (status === "Charging") {
            return "battery_android_frame_bolt";
        }

        if (level <= 0) {
            return "battery_android_frame_1";
        } else if (level <= 1 / 7) {
            return "battery_android_frame_2";
        } else if (level <= 2 / 7) {
            return "battery_android_frame_3";
        } else if (level <= 3 / 7) {
            return "battery_android_frame_4";
        } else if (level <= 4 / 7) {
            return "battery_android_frame_5";
        } else if (level <= 5 / 7) {
            return "battery_android_frame_6";
        } else {
            return "battery_android_frame_full";
        }
    }
    function getBrightnessIcon() {
        if (currentBrightness <= 0)
            return "brightness_1";
        if (currentBrightness <= 1 / 7)
            return "brightness_2";
        if (currentBrightness <= 2 / 7)
            return "brightness_3";
        if (currentBrightness <= 3 / 7)
            return "brightness_4";
        if (currentBrightness <= 4 / 7)
            return "brightness_5";
        if (currentBrightness <= 5 / 7)
            return "brightness_6";
        return "brightness_7";
    }

    SequentialAnimation on animationProgress {
        running: true
        NumberAnimation {
            from: 0
            to: 1
            duration: 500
            easing.type: Easing.Linear
        }
    }
    Item {
        anchors.fill: parent
        CustomRectangle {
            color: theme.primary.background
            anchors.centerIn: parent
            implicitWidth: root.animationProgress > 0.1 ? parent.width : 0
            implicitHeight: root.animationProgress > 0.1 ? parent.height : 0
            RowLayout {
                spacing: ScalerService.s(12)
                anchors.leftMargin: ScalerService.s(12)
                anchors.rightMargin: ScalerService.s(12)
                anchors.topMargin: ScalerService.s(5)
                anchors.bottomMargin: ScalerService.s(5)
                anchors.fill: parent
                RowLayout {
                    spacing: ScalerService.s(20)
                    IconImage {
                        path: "launcher/win11.svg"
                        size: "large"
                    }

                    CustomRectangle {
                        Layout.preferredWidth: ScalerService.s(200)
                        Layout.preferredHeight: ScalerService.s(30)
                        radius: ScalerService.s(Settings.appearance.radius1)
                        color: theme.button.background
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: ScalerService.s(12)
                            anchors.rightMargin: ScalerService.s(12)
                            anchors.topMargin: ScalerService.s(5)
                            anchors.bottomMargin: ScalerService.s(5)
                            spacing: ScalerService.s(12)
                            IconText {
                                fontFamily: "Symbols Nerd Font"
                                name: ""
                                textColor: theme.primary.dim_foreground
                                size: "small"
                                Layout.alignment: Qt.AlignVCenter
                            }
                            CustomText {
                                name: "Search"
                                size: "small"
                            }
                            Item {
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
                Item {
                    Layout.fillWidth: true
                }
                CustomRectangle {
                    Layout.preferredWidth: ScalerService.s(280)
                    radius: ScalerService.s(Settings.appearance.radius2)
                    color: theme.primary.dim_background
                    Layout.fillHeight: true
                    Com.WorkspaceSectionHorizontal {
                        anchors.centerIn: parent
                    }
                }
                Item {
                    Layout.fillWidth: true
                }
                RowLayout {
                    Layout.fillHeight: true
                    spacing: ScalerService.s(8)
                    IconText {
                        name: NetworkService.wifi_icon_text_1
                        size: "small"
                        Layout.alignment: Qt.AlignHCenter
                        textColor: theme.primary.foreground
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onClicked: {
                                SoundService.playSound("pick");
                                VisibleService.togglePanel("wifi");
                            }
                        }
                    }
                    IconText {
                        Layout.alignment: Qt.AlignHCenter
                        name: {
                            if (!sink || sink.audio.muted)
                                return "volume_off";
                            return getIcon(Math.round(sink.audio.volume * 100));
                        }
                        textColor: theme.primary.foreground
                        size: "small"
                    }
                    Item {
                        implicitWidth: UPower.displayDevice.isLaptopBattery ? ScalerService.s(80) : ScalerService.s(35)
                        Layout.fillHeight: true
                        RowLayout {
                            anchors.fill: parent
                            IconText {
                                size: "small"
                                name: UPower.displayDevice.isLaptopBattery ? getBatteryIcon(UPowerDeviceState.toString(UPower.displayDevice.state)) : "battery_android_question"
                                textColor: theme.primary.foreground
                            }
                            CustomText {
                                visible: UPower.displayDevice.isLaptopBattery
                                size: "small"
                                name: Math.round(UPower.displayDevice.percentage * 100) + "%"
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.RightButton
                            propagateComposedEvents: true
                            cursorShape: Qt.PointingHandCursor
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillHeight: true
                    Layout.preferredWidth: ScalerService.s(100)
                    CustomText {
                        name: DateTimeService.currentTime
                        Layout.alignment: Qt.AlignHCenter
                        size: "xs"
                    }
                    CustomText {
                        name: DateTimeService.currentDate1
                        Layout.alignment: Qt.AlignHCenter
                        size: "xs"
                    }
                }
            }
        }
    }
}
