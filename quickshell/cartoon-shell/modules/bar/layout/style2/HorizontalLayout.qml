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

RowLayout {
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
            to: 1
            duration: 500
            easing.type: Easing.Linear
        }
    }
    Item {
        Layout.preferredWidth: ScalerService.s(12)
    }
    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        CustomRectangle {
            color: theme.primary.background
            radius: ScalerService.s(Settings.appearance.radius2)
            border.color: theme.button.border
            border.width: Settings.appearance.enableBorder ? ScalerService.s(3) : 0
            anchors.centerIn: parent
            implicitWidth: root.animationProgress > 0.1 ? parent.width * 0.8 : 0
            implicitHeight: root.animationProgress > 0.1 ? parent.height : 0

            RowLayout {
                spacing: ScalerService.s(12)
                anchors.margins: ScalerService.s(5)
                anchors.fill: parent
                Item {
                    Layout.preferredWidth: ScalerService.s(8)
                }
                ButtonIconText {
                    fontFamily: "Symbols Nerd Font"
                    name: "󰣇"
                    textColor: theme.button.text
                    size: "small"
                    Layout.alignment: Qt.AlignVCenter
                    onClicked: {
                        VisibleService.togglePanel("launcher");
                    }
                }
                Item {
                    Layout.fillWidth: true
                }
                CustomRectangle {
                    color: theme.primary.dim_background
                    implicitWidth: ScalerService.s(70)
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
                        CustomText {
                            size: "small"
                            name: RamSimpleService.ramPercent + "%"
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }
                }
                CustomRectangle {
                    color: theme.primary.dim_background
                    implicitWidth: ScalerService.s(70)
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
                        CustomText {
                            size: "small"
                            name: CpuSimpleService.cpuPercent + "%"
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }
                }
                RowLayout {
                    id: controlsRow

                    spacing: ScalerService.s(2)

                    ButtonIconText {
                        name: "skip_previous"
                        size: "normal"

                        textColor: theme.normal.blue
                        Layout.alignment: Qt.AlignVCenter
                        onClicked: Players?.mprisPlayer.previous()
                    }
                    ButtonIconText {
                        name: Players.mprisPlayer && Players.mprisPlayer.isPlaying ? "pause" : "play_arrow"
                        size: "normal"

                        Layout.alignment: Qt.AlignVCenter
                        textColor: theme.normal.green
                        onClicked: Players?.mprisPlayer.togglePlaying()
                    }
                    ButtonIconText {
                        name: "skip_next"
                        size: "normal"
                        textColor: theme.normal.blue

                        Layout.alignment: Qt.AlignVCenter
                        onClicked: Players?.mprisPlayer.next()
                    }
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
                    Layout.preferredWidth: ScalerService.s(12)
                }
                CustomText {
                    size: "xs"
                    name: `${DateTimeService.currentHour}:${DateTimeService.currentMinus} · ${DateTimeService.currentDate}`
                    Layout.alignment: Qt.AlignVCenter
                }
                Item {
                    Layout.preferredWidth: ScalerService.s(12)
                }
                CustomRectangle {
                    color: theme.primary.dim_background
                    implicitWidth: ScalerService.s(70)
                    radius: ScalerService.s(Settings.appearance.radius2)
                    Layout.fillHeight: true
                    RowLayout {
                        id: contentBri
                        anchors.centerIn: parent
                        IconText {
                            name: root.getBrightnessIcon()
                            textColor: theme.button.text
                            size: "small"
                        }
                        CustomText {
                            name: Math.floor(BrightnessService.currentBrightness * 100) + "%"
                            isBold: true
                            size: "small"
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
                    implicitWidth: ScalerService.s(70)
                    radius: ScalerService.s(Settings.appearance.radius2)
                    Layout.fillHeight: true
                    RowLayout {
                        id: contentVlo
                        anchors.centerIn: parent
                        IconText {
                            size: "small"
                            name: {
                                if (!sink || sink.audio.muted)
                                    return "volume_off";
                                return getIcon(Math.round(sink.audio.volume * 100));
                            }
                            textColor: theme.button.text
                        }
                        CustomText {
                            name: sink ? Math.round(sink.audio.volume * 100) + "%" : "0%"
                            isBold: true
                            size: "small"
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
                    implicitWidth: UPower.displayDevice.isLaptopBattery ? ScalerService.s(70) : ScalerService.s(35)
                    radius: ScalerService.s(Settings.appearance.radius2)
                    Layout.fillHeight: true
                    RowLayout {
                        anchors.centerIn: parent
                        IconText {
                            size: "small"
                            name: UPower.displayDevice.isLaptopBattery ? getBatteryIcon(UPowerDeviceState.toString(UPower.displayDevice.state)) : "battery_android_question"
                            textColor: UPower.displayDevice.isLaptopBattery ? theme.button.text : theme.normal.red
                        }
                        CustomText {
                            visible: UPower.displayDevice.isLaptopBattery
                            name: Math.round(UPower.displayDevice.percentage * 100) + "%"
                            isBold: true
                            size: "small"
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
                    implicitWidth: ScalerService.s(35)
                    radius: ScalerService.s(Settings.appearance.radius2)
                    Layout.fillHeight: true
                    RowLayout {
                        anchors.centerIn: parent
                        IconText {
                            name: "bluetooth"
                            size: "small"
                            textColor: theme.normal.blue
                        }
                    }
                }
                CustomRectangle {
                    color: theme.primary.dim_background
                    implicitWidth: ScalerService.s(35)
                    radius: ScalerService.s(Settings.appearance.radius2)
                    Layout.fillHeight: true
                    RowLayout {
                        anchors.centerIn: parent
                        IconText {
                            name: NetworkService.wifi_icon_text_2
                            size: "small"
                            textColor: theme.normal.green
                        }
                    }

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

                Item {
                    Layout.fillWidth: true
                }
                ButtonIconText {
                    fontFamily: "Symbols Nerd Font"
                    name: "󰐥"
                    size: "small"
                    Layout.alignment: Qt.AlignVCenter
                    textColor: theme.normal.red
                }
                Item {
                    Layout.preferredWidth: ScalerService.s(8)
                }
            }
        }
    }

    Item {
        Layout.preferredWidth: ScalerService.s(12)
    }
}
