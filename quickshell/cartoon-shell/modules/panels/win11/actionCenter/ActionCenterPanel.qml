// ActionCenterPanel.qml
import QtQuick
import QtQuick.Controls
import Quickshell.Services.UPower
import Quickshell.Services.Pipewire
import QtQuick.Layouts
import Quickshell
import qs.commons
import qs.components
import qs.services

PanelWindow {
    id: root
    readonly property var sink: Pipewire.defaultAudioSink

    function getIcon(volPercent) {
        if (volPercent < 10)
            return "volume_mute";
        if (volPercent < 60)
            return "volume_down";
        return "volume_up";
    }

    implicitWidth: ScalerService.s(450)
    implicitHeight: ScalerService.s(600)
    function getBrightnessIcon(currentBrightness) {
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
    Behavior on implicitHeight {
        NumberAnimation {
            duration: 60
            easing.type: Easing.OutCubic
        }
    }
    Behavior on implicitWidth {
        NumberAnimation {
            duration: 60
            easing.type: Easing.OutCubic
        }
    }
    property var lang: LanguageService.translations

    anchors {
        // Anchor theo vị trí của bar
        left: Settings.bar.position === "left"
        right: Settings.bar.position === "right" || Settings.bar.position === "top" || Settings.bar.position === "bottom"
        top: Settings.bar.position === "top"
        bottom: Settings.bar.position === "left" || Settings.bar.position === "right" || Settings.bar.position === "bottom"
    }

    margins {
        top: Settings.bar.position === "top" ? ScalerService.s(10) : 0
        bottom: (Settings.bar.position === "bottom" || Settings.bar.position === "left" || Settings.bar.position === "right") ? ScalerService.s(10) : 0
        left: Settings.bar.position === "left" ? ScalerService.s(10) : 0
        right: (Settings.bar.position === "right" || Settings.bar.position === "top" || Settings.bar.position === "bottom") ? ScalerService.s(10) : 0
    }
    color: "transparent"

    CustomRectangle {
        anchors.centerIn: parent
        implicitWidth: root.animationProgress > 0 ? parent.width : 0
        implicitHeight: root.animationProgress > 0 ? parent.height : 0
        color: theme.primary.background
        radius: ScalerService.s(Settings.appearance.radius1)
        clip: true

        ColumnLayout {
            anchors.fill: parent

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: ScalerService.s(40)

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 3
                        rowSpacing: ScalerService.s(8)
                        columnSpacing: ScalerService.s(8)
                        CustomRectangle {
                            Layout.preferredWidth: ScalerService.s(120)
                            Layout.preferredHeight: ScalerService.s(80)
                            radius: ScalerService.s(Settings.appearance.radius2)
                            color: theme.button.text
                            IconText {
                                anchors.centerIn: parent
                                name: NetworkService.wifi_icon_text_1
                                Layout.alignment: Qt.AlignHCenter
                                textColor: theme.primary.background
                            }
                        }
                    }
                    Item {
                        Layout.fillHeight: true
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: ScalerService.s(30)
                        spacing: ScalerService.s(20)
                        IconText {
                            font.variableAxes: {
                                "FILL": 0
                            }
                            name: {
                                if (!sink || sink.audio.muted)
                                    return "volume_off";
                                return getIcon(Math.round(sink.audio.volume * 100));
                            }
                            textColor: theme.primary.foreground
                        }
                        CustomSlider {
                            Layout.fillWidth: true
                            value: sink.audio.volume
                            enabled: !sink.audio.muted

                            onMoved: sink.audio.volume = value
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: ScalerService.s(30)
                        spacing: ScalerService.s(20)
                        IconText {
                            name: root.getBrightnessIcon(BrightnessService.currentBrightness)
                        }
                        CustomSlider {
                            Layout.fillWidth: true
                            value: BrightnessService.currentBrightness
                            enabled: !sink.audio.muted

                            onMoved: BrightnessService.setBright(value)
                        }
                    }
                }
            }

            CustomRectangle {
                color: theme.primary.dim_background

                bottomLeftRadius: ScalerService.s(Settings.appearance.radius1)
                bottomRightRadius: ScalerService.s(Settings.appearance.radius1)
                Layout.fillWidth: true
                Layout.preferredHeight: ScalerService.s(50)
                Rectangle {
                    opacity: 0.4
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                    }

                    height: ScalerService.s(1)
                    color: theme.primary.dim_foreground
                }
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: ScalerService.s(12)
                    anchors.rightMargin: ScalerService.s(12)
                    Item {
                        implicitWidth: UPower.displayDevice.isLaptopBattery ? ScalerService.s(65) : ScalerService.s(35)
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
            }
        }
    }
}
