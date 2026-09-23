import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Services.Pipewire
import qs.components
import qs.services

ColumnLayout {
    required property PwNode node
    property alias showIcon: icon.visible
    property alias showMediaName: mediaLabel.visible

    // bind the node so we can read its properties
    PwObjectTracker {
        objects: [node]
    }

    spacing: ScalerService.s(8)

    // Header row với app info và controls
    RowLayout {
        spacing: ScalerService.s(8)

        // App icon với styling theme
        Rectangle {
            id: icon
            width: ScalerService.s(24)
            height: ScalerService.s(24)
            radius: ScalerService.s(4)
            color: theme.button.background

            Image {
                anchors.fill: parent
                anchors.margins: ScalerService.s(2)
                source: {
                    const iconName = node.properties["application.icon-name"];
                    if (iconName) {
                        return `image://icon/${iconName}`;
                    } else {
                        return "../../../assets/volume/volume.png";
                    }
                }
                sourceSize.width: ScalerService.s(20)
                sourceSize.height: ScalerService.s(20)
                fillMode: Image.PreserveAspectFit
            }
        }

        // App và media info
        ColumnLayout {
            Layout.fillWidth: true
            spacing: ScalerService.s(2)

            CustomText {
                id: appLabel
                name: {
                    const appName = node.properties["application.name"] ?? (node.description != "" ? node.description : node.name);
                    return appName || "Unknown Application";
                }
                isBold: true
                size: "small"
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            CustomText {
                id: mediaLabel
                name: node.properties["media.name"] ?? ""
                size: "xs"
                elide: Text.ElideRight
                Layout.fillWidth: true
                visible: text !== ""
                textColor: theme.primary.dim_foreground
            }
        }

        // Mute button với icon theme
        Button {
            id: muteButton
            text: ""
            width: ScalerService.s(28)
            height: ScalerService.s(28)
            opacity: hovered ? 1.0 : 0.8

            background: Item {}

            contentItem: IconText {
                name: node.audio.muted ? "volume_off" : "volume_up"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                textColor: node.audio.muted ? theme.normal.red : theme.button.text
            }

            onClicked: node.audio.muted = !node.audio.muted

            ToolTip.text: node.audio.muted ? lang.entry.muted : lang.entry.mute
            ToolTip.visible: hovered
        }
    }

    // Volume control section
    RowLayout {
        spacing: ScalerService.s(8)

        // Volume percentage
        CustomText {
            Layout.preferredWidth: ScalerService.s(40)
            name: `${Math.round(node.audio.volume * 100)}%`
            isBold: true
            size: "small"
            textColor: node.audio.muted ? theme.normal.red : theme.button.text
            horizontalAlignment: Text.AlignRight
        }

        Slider {
            id: volumeSlider
            Layout.fillWidth: true
            from: 0
            to: 1
            value: node.audio.volume
            enabled: !node.audio.muted
            opacity: enabled ? 1.0 : 0.5

            onMoved: node.audio.volume = value

            background: Rectangle {
                x: volumeSlider.leftPadding
                y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                implicitWidth: ScalerService.s(200)
                implicitHeight: ScalerService.s(6)
                width: volumeSlider.availableWidth
                height: implicitHeight
                radius: ScalerService.s(3)
                color: theme.button.background

                // Progress fill
                Rectangle {
                    width: volumeSlider.visualPosition * parent.width
                    height: parent.height
                    color: {
                        if (node.audio.muted)
                            return theme.normal.black;
                        const vol = node.audio.volume;
                        if (vol > 1.0)
                            return theme.normal.red;
                        if (vol > 0.8)
                            return theme.normal.yellow;
                        return theme.normal.blue;
                    }
                    radius: ScalerService.s(3)
                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                            easing.type: Easing.InOutQuad
                        }
                    }
                }

                // Clip indicator (khi volume > 100%)
                Rectangle {
                    visible: node.audio.volume > 1.0
                    x: parent.width - width
                    width: ScalerService.s(3)
                    height: parent.height + ScalerService.s(2)
                    radius: ScalerService.s(1.5)
                    color: theme.normal.red
                    border.color: theme.bright.red
                    border.width: ScalerService.s(1)
                }
            }

            handle: Rectangle {
                x: volumeSlider.leftPadding + volumeSlider.visualPosition * (volumeSlider.availableWidth - width)
                y: volumeSlider.topPadding + volumeSlider.availableHeight / 2 - height / 2
                implicitWidth: ScalerService.s(16)
                implicitHeight: ScalerService.s(16)
                radius: ScalerService.s(8)
                color: volumeSlider.pressed ? theme.normal.blue : theme.primary.background
                border.color: node.audio.muted ? theme.normal.black : node.audio.volume > 1.0 ? theme.normal.red : node.audio.volume > 0.8 ? theme.normal.yellow : theme.normal.blue
                border.width: ScalerService.s(2)

                // Inner dot
                Rectangle {
                    anchors.centerIn: parent
                    width: ScalerService.s(4)
                    height: ScalerService.s(4)
                    radius: ScalerService.s(2)
                    color: theme.primary.foreground
                    opacity: volumeSlider.pressed ? 1.0 : 0.7
                }

                Behavior on color {
                    ColorAnimation {
                        duration: 150
                        easing.type: Easing.InOutQuad
                    }
                }
                Behavior on border.color {
                    ColorAnimation {
                        duration: 200
                        easing.type: Easing.InOutQuad
                    }
                }
            }
        }
    }

    // Peak level indicator (hiển thị khi có âm thanh phát ra)
    Rectangle {
        visible: node.audio.peak > 0.01
        Layout.fillWidth: true
        Layout.preferredHeight: ScalerService.s(2)
        radius: ScalerService.s(1)
        color: theme.button.background

        Rectangle {
            width: parent.width * Math.min(node.audio.peak, 1.0)
            height: parent.height
            radius: ScalerService.s(1)
            color: {
                const peak = node.audio.peak;
                if (peak > 0.9)
                    return theme.normal.red;
                if (peak > 0.7)
                    return theme.normal.yellow;
                return theme.normal.green;
            }

            Behavior on width {
                NumberAnimation {
                    duration: 80
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on color {
                ColorAnimation {
                    duration: 150
                    easing.type: Easing.InOutQuad
                }
            }
        }
    }
}
