// Device item component for Bluetooth panel
import QtQuick
import qs.services
import QtQuick.Layouts
import qs.components
import qs.services
import qs.commons

Rectangle {
    id: delegateRoot
    required property var modelData
    required property int index
    required property var adapter

    signal pairError(string message)

    width: ListView.view.width
    height: ScalerService.s(70)
    color: Qt.alpha(theme.button.background, 0.5)
    radius: ScalerService.s(Settings.appearance.radius2)
    border.width: Settings.appearance.enableBorder ? ScalerService.s(2) : 0
    border.color: theme.button.border

    scale: deviceMouseArea.containsPress ? 0.98 : 1.0
    Behavior on scale {
        NumberAnimation {
            duration: 100
        }
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

    // Pairing indicator
    Rectangle {
        id: pairingIndicator
        visible: modelData?.pairing || false
        anchors.centerIn: parent
        width: parent.width - ScalerService.s(20)
        height: parent.height - ScalerService.s(20)
        radius: ScalerService.s(8)
        color: theme.normal.yellow
        opacity: 0.3

        Text {
            anchors.centerIn: parent
            text: lang?.bluetooth?.pairing || "Đang ghép nối..."
            color: theme.primary.foreground
            font.pixelSize: ScalerService.s(14)
            font.weight: Font.Bold
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: ScalerService.s(12)
        spacing: ScalerService.s(12)
        opacity: modelData?.pairing ? 0.7 : 1.0

        // Device icon
        Rectangle {
            width: ScalerService.s(46)
            height: ScalerService.s(46)
            radius: ScalerService.s(23)
            color: modelData?.connected ? theme.normal.blue : theme.button.background

            Text {
                anchors.centerIn: parent
                text: getDeviceIcon(modelData?.icon || "")
                font.pixelSize: ScalerService.s(20)
            }
        }

        // Device info
        ColumnLayout {
            Layout.fillWidth: true
            spacing: ScalerService.s(2)

            Text {
                text: modelData?.name || lang?.bluetooth?.no_devices || "Unknown Device"
                color: theme.primary.foreground
                font.pixelSize: ScalerService.s(16)
                font.family: "ComicShannsMono Nerd Font"
                font.weight: Font.Medium
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            CustomText {
                name: {
                    if (modelData?.connecting)
                        return lang?.bluetooth?.connecting || "Đang kết nối...";
                    if (modelData?.connected)
                        return lang?.bluetooth?.connected || "Đã kết nối";
                    if (modelData?.paired)
                        return lang?.bluetooth?.paired || "Đã ghép nối";
                    return lang?.bluetooth?.not_connected || "Chưa kết nối";
                }
                color: {
                    if (modelData?.connecting)
                        return theme.normal.yellow;
                    if (modelData?.connected)
                        return theme.button.text;
                    if (modelData?.paired)
                        return theme.button.text;
                    return theme.normal.red;
                }
                size: "xs"
            }
        }

        // Action buttons
        RowLayout {
            spacing: ScalerService.s(8)

            // Connect/Disconnect button
            Rectangle {
                width: ScalerService.s(32)
                height: ScalerService.s(32)
                radius: ScalerService.s(8)
                color: theme.button.text
                opacity: (modelData?.paired || modelData?.connecting) ? 1 : 0.5
                enabled: !modelData?.pairing

                scale: connectMouseArea.containsPress ? 0.9 : (connectMouseArea.containsMouse ? 1.1 : 1.0)
                Behavior on scale {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutBack
                    }
                }
                Behavior on color {
                    ColorAnimation {
                        duration: 200
                    }
                }

                IconText {
                    anchors.centerIn: parent
                    name: modelData?.connecting ? "hourglass_bottom" : modelData?.connected ? "bluetooth_connected" : "attachment"
                    textColor: theme.primary.background
                    size: "small"

                    rotation: modelData?.connecting ? 360 : 0
                    RotationAnimator on rotation {
                        running: modelData?.connecting || false
                        from: 0
                        to: 360
                        duration: 1000
                        loops: Animation.Infinite
                    }
                }

                MouseArea {
                    id: connectMouseArea
                    anchors.fill: parent
                    enabled: parent.enabled
                    hoverEnabled: true
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        if (modelData?.connected) {
                            modelData.disconnect();
                        } else if (modelData?.paired && !modelData?.connecting) {
                            modelData.connect();
                        }
                    }
                }
            }

            // Pair/Forget button
            Rectangle {
                width: ScalerService.s(32)
                height: ScalerService.s(32)
                radius: ScalerService.s(8)
                color: theme.button.text
                opacity: modelData?.pairing ? 0.8 : 1
                enabled: !modelData?.pairing

                scale: pairMouseArea.containsPress ? 0.9 : (pairMouseArea.containsMouse ? 1.1 : 1.0)
                Behavior on scale {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutBack
                    }
                }
                Behavior on color {
                    ColorAnimation {
                        duration: 200
                    }
                }

                IconText {
                    anchors.centerIn: parent
                    name: modelData?.pairing ? "hourglass_bottom" : modelData?.paired ? "delete" : "bluetooth_connected"
                    color: theme.primary.background
                    size: "small"
                }

                MouseArea {
                    id: pairMouseArea
                    anchors.fill: parent
                    enabled: parent.enabled && !modelData?.connected
                    hoverEnabled: true
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        if (modelData?.paired) {
                            modelData.forget();
                        } else {
                            // Ensure adapter is pairable
                            if (adapter) {
                                adapter.pairable = true;
                                adapter.discoverable = true;
                            }

                            // Try to pair
                            try {
                                modelData.pair();
                            } catch (error) {
                                delegateRoot.pairError(lang?.bluetooth?.pair_error || "Không thể ghép nối với thiết bị");
                            }
                        }
                    }
                }
            }
        }
    }

    MouseArea {
        id: deviceMouseArea
        anchors.fill: parent
        hoverEnabled: true
        propagateComposedEvents: true
        onPressed: function (mouse) {
            mouse.accepted = false;
        }
    }

    // Device state connections
    Connections {
        target: modelData
        function onPairingChanged() {
        }
        function onPairedChanged() {
        }
    }

    function getDeviceIcon(iconName) {
        if (iconName.includes("audio"))
            return "🎧";
        if (iconName.includes("phone"))
            return "📱";
        if (iconName.includes("computer"))
            return "💻";
        if (iconName.includes("input-mouse"))
            return "🖱";
        if (iconName.includes("input-keyboard"))
            return "⌨";
        if (iconName.includes("camera"))
            return "📷";
        if (iconName.includes("printer"))
            return "🖨";
        return "📡";
    }
}
