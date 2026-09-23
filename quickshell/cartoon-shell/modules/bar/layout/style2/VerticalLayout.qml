import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import QtQuick.Effects
import qs.modules.bar
import qs.commons
import qs.services
import qs.services.ram
import qs.services.cpu
import qs.components
import Quickshell.Services.Pipewire
import "../../widget/" as Com

ColumnLayout {
    id: root
    property real animationProgress: 0

    readonly property var sink: Pipewire.defaultAudioSink
    property real currentBrightness: BrightnessService.currentBrightness

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

    function changeVolume(delta) {
        if (!sink)
            return;
        var newVol = Math.min(1.5, Math.max(0, sink.audio.volume + delta));
        sink.audio.volume = newVol;
        if (sink.audio.muted && delta > 0)
            sink.audio.muted = false;
    }

    function toggleMute() {
        if (sink)
            sink.audio.muted = !sink.audio.muted;
    }

    function getIcon(volPercent) {
        if (volPercent < 10)
            return "volume_mute";
        if (volPercent < 60)
            return "volume_down";
        return "volume_up";
    }

    SequentialAnimation on animationProgress {
        running: true
        NumberAnimation {
            from: 0
            to: 2
            duration: 1000
            easing.type: Easing.Linear
        }
    }

    Item {
        Layout.preferredHeight: ScalerService.s(5)
    }

    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        CustomRectangle {
            color: theme.primary.background
            radius: ScalerService.s(Settings.appearance.radius2)
            border.color: theme.button.border
            border.width: Settings.appearance.enableBorder ? ScalerService.s(3) : 0
            implicitWidth: root.animationProgress > 0.1 ? parent.width : 0
            implicitHeight: root.animationProgress > 0.1 ? parent.height * 0.95 : 0
            anchors.centerIn: parent

            visible: root.animationProgress > 0.1

            ColumnLayout {
                spacing: ScalerService.s(12)
                anchors.margins: ScalerService.s(2)
                anchors.fill: parent

                Item {
                    Layout.preferredHeight: ScalerService.s(0)
                }

                ButtonIconText {
                    fontFamily: "Symbols Nerd Font"
                    name: "󰣇"
                    textColor: theme.button.text
                    Layout.alignment: Qt.AlignHCenter
                    onClicked: {
                        VisibleService.togglePanel("launcher");
                    }
                    opacity: root.animationProgress > 0.3 ? 1 : 0
                }

                Item {
                    Layout.fillHeight: true
                }

                CustomRectangle {
                    color: theme.primary.dim_background
                    implicitWidth: ScalerService.s(30)
                    implicitHeight: ScalerService.s(55)
                    radius: ScalerService.s(Settings.appearance.radius2)
                    Layout.alignment: Qt.AlignHCenter

                    opacity: root.animationProgress > 0.2 ? 1 : 0
                    ColumnLayout {
                        id: contentRam
                        anchors.centerIn: parent
                        IconText {
                            name: ""
                            fontFamily: "Symbols Nerd Font"
                            textColor: theme.normal.green
                            size: "xs"
                            Layout.alignment: Qt.AlignHCenter
                            opacity: root.animationProgress > 0.35 ? 1 : 0
                        }
                        CustomText {
                            size: "xs"
                            name: RamSimpleService.ramPercent + "%"
                            Layout.alignment: Qt.AlignHCenter
                            opacity: root.animationProgress > 0.4 ? 1 : 0
                        }
                    }
                }

                CustomRectangle {
                    color: theme.primary.dim_background
                    implicitWidth: ScalerService.s(30)
                    implicitHeight: ScalerService.s(55)
                    radius: ScalerService.s(Settings.appearance.radius2)
                    Layout.alignment: Qt.AlignHCenter
                    opacity: root.animationProgress > 0.25 ? 1 : 0

                    ColumnLayout {
                        id: contentCpu
                        anchors.centerIn: parent
                        IconText {
                            name: ""
                            fontFamily: "Symbols Nerd Font"
                            textColor: theme.normal.red
                            size: "xs"
                            Layout.alignment: Qt.AlignHCenter
                            opacity: root.animationProgress > 0.45 ? 1 : 0
                        }
                        CustomText {
                            size: "xs"
                            name: CpuSimpleService.cpuPercent + "%"
                            Layout.alignment: Qt.AlignHCenter
                            opacity: root.animationProgress > 0.5 ? 1 : 0
                        }
                    }
                }

                ColumnLayout {
                    id: controlsRow
                    spacing: ScalerService.s(2)
                    Layout.alignment: Qt.AlignHCenter

                    ButtonIconText {
                        name: "skip_previous"
                        size: "normal"
                        textColor: theme.normal.blue
                        Layout.alignment: Qt.AlignHCenter
                        onClicked: Players?.mprisPlayer.previous()
                        opacity: root.animationProgress > 0.55 ? 1 : 0
                    }
                    ButtonIconText {
                        name: Players.mprisPlayer && Players.mprisPlayer.isPlaying ? "pause" : "play_arrow"
                        size: "normal"
                        Layout.alignment: Qt.AlignHCenter
                        textColor: theme.normal.green
                        onClicked: Players?.mprisPlayer.togglePlaying()
                        opacity: root.animationProgress > 0.6 ? 1 : 0
                    }
                    ButtonIconText {
                        name: "skip_next"
                        size: "normal"
                        textColor: theme.normal.blue
                        Layout.alignment: Qt.AlignHCenter
                        onClicked: Players?.mprisPlayer.next()
                        opacity: root.animationProgress > 0.65 ? 1 : 0
                    }
                }

                CustomRectangle {
                    Layout.preferredHeight: ScalerService.s(240)
                    radius: ScalerService.s(Settings.appearance.radius2)
                    color: theme.primary.dim_background
                    implicitWidth: ScalerService.s(30)
                    opacity: root.animationProgress > 0.3 ? 1 : 0

                    Layout.alignment: Qt.AlignHCenter

                    Com.WorkspaceSectionVertical {
                        opacity: root.animationProgress > 0.7 ? 1 : 0
                        anchors.centerIn: parent
                    }
                }

                ColumnLayout {
                    spacing: ScalerService.s(5)
                    Layout.alignment: Qt.AlignHCenter

                    CustomText {
                        size: "small"
                        name: `${DateTimeService.currentHour}`
                        Layout.alignment: Qt.AlignHCenter
                        opacity: root.animationProgress > 0.75 ? 1 : 0
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Item {
                            Layout.fillWidth: true
                        }
                        CustomRectangle {
                            opacity: root.animationProgress > 0.8 ? 1 : 0

                            Layout.preferredWidth: ScalerService.s(25)
                            Layout.preferredHeight: ScalerService.s(2)
                            color: theme.primary.foreground
                            radius: ScalerService.s(Settings.appearance.radius2)
                            Layout.alignment: Qt.AlignHCenter
                        }
                        Item {
                            Layout.fillWidth: true
                        }
                    }

                    CustomText {
                        size: "small"
                        opacity: root.animationProgress > 0.85 ? 1 : 0
                        name: `${DateTimeService.currentMinus}`
                        Layout.alignment: Qt.AlignHCenter
                    }
                }

                CustomRectangle {
                    color: theme.primary.dim_background
                    implicitWidth: ScalerService.s(30)
                    radius: ScalerService.s(Settings.appearance.radius2)
                    implicitHeight: ScalerService.s(55)
                    Layout.alignment: Qt.AlignHCenter
                    opacity: root.animationProgress > 0.35 ? 1 : 0

                    ColumnLayout {
                        id: contentBri
                        anchors.centerIn: parent
                        IconText {
                            name: root.getBrightnessIcon()
                            textColor: theme.button.text
                            Layout.alignment: Qt.AlignHCenter
                            size: "small"
                            opacity: root.animationProgress > 0.9 ? 1 : 0
                        }
                        CustomText {
                            name: Math.floor(BrightnessService.currentBrightness * 100) + "%"
                            Layout.alignment: Qt.AlignHCenter
                            size: "xs"
                            opacity: root.animationProgress > 0.95 ? 1 : 0
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.RightButton
                        propagateComposedEvents: true
                        cursorShape: Qt.PointingHandCursor

                        onWheel: wheel => {
                            let step = 0.05;

                            SoundService.playSound("pop");
                            if (wheel.angleDelta.y > 0)
                                BrightnessService.changeBright(step);
                            else if (wheel.angleDelta.y < 0)
                                BrightnessService.changeBright(-step);
                        }

                        onPressed: mouse => {
                            if (mouse.button === Qt.RightButton) {
                                toggleMute();
                                mouse.accepted = true;
                            } else {
                                mouse.accepted = false;
                            }
                        }
                    }
                }

                CustomRectangle {
                    color: theme.primary.dim_background
                    implicitWidth: ScalerService.s(30)
                    opacity: root.animationProgress > 0.4 ? 1 : 0
                    radius: ScalerService.s(Settings.appearance.radius2)
                    implicitHeight: ScalerService.s(55)
                    Layout.alignment: Qt.AlignHCenter

                    ColumnLayout {
                        id: contentVlo
                        anchors.centerIn: parent
                        IconText {
                            size: "small"
                            name: {
                                if (!sink || sink.audio.muted)
                                    return "volume_off";
                                return getIcon(Math.round(sink.audio.volume * 100));
                            }
                            Layout.alignment: Qt.AlignHCenter
                            textColor: theme.button.text
                            opacity: root.animationProgress > 1 ? 1 : 0
                        }
                        CustomText {
                            name: sink ? Math.round(sink.audio.volume * 100) + "%" : "0%"
                            Layout.alignment: Qt.AlignHCenter
                            size: "xs"
                            opacity: root.animationProgress > 1.05 ? 1 : 0
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.RightButton
                        propagateComposedEvents: true
                        cursorShape: Qt.PointingHandCursor

                        onWheel: wheel => {
                            let step = 0.05;

                            SoundService.playSound("pop");
                            if (wheel.angleDelta.y > 0)
                                changeVolume(step);
                            else if (wheel.angleDelta.y < 0)
                                changeVolume(-step);
                        }

                        onPressed: mouse => {
                            if (mouse.button === Qt.RightButton) {
                                toggleMute();
                                mouse.accepted = true;
                            } else {
                                mouse.accepted = false;
                            }
                        }
                    }
                }

                CustomRectangle {
                    color: theme.primary.dim_background
                    implicitWidth: ScalerService.s(30)
                    radius: ScalerService.s(Settings.appearance.radius2)
                    opacity: root.animationProgress > 0.45 ? 1 : 0
                    implicitHeight: ScalerService.s(60)
                    Layout.alignment: Qt.AlignHCenter

                    ColumnLayout {
                        anchors.centerIn: parent
                        IconText {
                            size: "small"
                            name: UPower.displayDevice.isLaptopBattery ? getBatteryIcon(UPower.displayDevice.percentage, UPowerDeviceState.toString(UPower.displayDevice.state)) : "battery_android_question"
                            textColor: UPower.displayDevice.isLaptopBattery ? theme.button.text : theme.normal.red
                            Layout.alignment: Qt.AlignHCenter
                            opacity: root.animationProgress > 1.1 ? 1 : 0
                        }
                        CustomText {
                            visible: UPower.displayDevice.isLaptopBattery
                            name: Math.round(UPower.displayDevice.percentage * 100) + "%"
                            size: "xs"
                            Layout.alignment: Qt.AlignHCenter

                            opacity: root.animationProgress > 1.15 ? 1 : 0
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.RightButton
                        propagateComposedEvents: true
                        cursorShape: Qt.PointingHandCursor
                    }
                }

                CustomRectangle {
                    color: theme.primary.dim_background
                    implicitWidth: ScalerService.s(30)
                    radius: ScalerService.s(Settings.appearance.radius2)
                    implicitHeight: ScalerService.s(70)
                    opacity: root.animationProgress > 0.5 ? 1 : 0

                    Layout.alignment: Qt.AlignHCenter

                    ColumnLayout {
                        anchors.centerIn: parent
                        IconText {
                            name: NetworkService.wifi_icon_text_2
                            size: "small"
                            textColor: theme.button.text
                            Layout.alignment: Qt.AlignHCenter
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor

                                onClicked: {
                                    SoundService.playSound("pick");
                                    VisibleService.togglePanel("wifi");
                                }
                            }

                            opacity: root.animationProgress > 1.2 ? 1 : 0
                        }
                        IconText {
                            name: "bluetooth"
                            size: "small"
                            textColor: theme.button.text
                            Layout.alignment: Qt.AlignHCenter

                            opacity: root.animationProgress > 1.25 ? 1 : 0
                        }
                    }
                }

                Item {
                    Layout.fillHeight: true
                }

                ButtonIconText {
                    fontFamily: "Symbols Nerd Font"
                    name: "󰐥"
                    textColor: theme.normal.red
                    Layout.alignment: Qt.AlignHCenter
                    opacity: root.animationProgress > 1.3 ? 1 : 0
                }

                Item {
                    Layout.preferredHeight: ScalerService.s(0)
                }
            }
        }
    }

    Item {
        Layout.preferredHeight: ScalerService.s(5)
    }
}
