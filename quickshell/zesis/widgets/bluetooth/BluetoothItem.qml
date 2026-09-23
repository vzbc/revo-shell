pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import Quickshell.Io
import "../../"
import "../bar"
import "../shared"
import "../airpods"

BarButton {
    id: root

    icon: BluetoothService.powered ? "󰂯" : "󰂲"
    active: popup.visible
    onClicked: popup.visible ? popup.close() : popup.open()

    AnimatedPopup {
        id: popup
        anchorItem: root
        implicitWidth: Math.round(300 * UIScale.value)
        implicitHeight: Math.round(380 * UIScale.value)
        content: Component {
            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                PanelHeader {
                    Layout.fillWidth: true
                    breadcrumb: I18n.t("bluetooth.breadcrumb")
                    title: I18n.t("bluetooth.title")
                    rightActions: Component {
                        ToggleSwitch {
                            checked: BluetoothService.powered
                            onToggled: {
                                if (BluetoothService.activeAdapter)
                                    BluetoothService.activeAdapter.enabled = !BluetoothService.powered;
                            }
                        }
                    }
                }

                Flickable {
                    id: flick
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentWidth: width
                    contentHeight: col.implicitHeight
                    clip: true
                    flickableDirection: Flickable.VerticalFlick

                    ColumnLayout {
                        id: col
                        width: flick.width
                        spacing: 0

                        Item {
                            implicitHeight: UIScale.spacingSm
                        }

                        Text {
                            text: I18n.t("bluetooth.adapterNotFound")
                            color: Colors.textDim
                            font.pixelSize: UIScale.fontSmall
                            horizontalAlignment: Text.AlignHCenter
                            Layout.fillWidth: true
                            Layout.topMargin: UIScale.spacingLg
                            visible: !BluetoothService.available
                        }

                        Text {
                            text: I18n.t("bluetooth.off")
                            color: Colors.textDim
                            font.pixelSize: UIScale.fontSmall
                            horizontalAlignment: Text.AlignHCenter
                            Layout.fillWidth: true
                            Layout.topMargin: UIScale.spacingLg
                            visible: BluetoothService.available && !BluetoothService.powered
                        }

                        SectionLabel {
                            text: I18n.t("bluetooth.pairedDevicesSection")
                            Layout.leftMargin: UIScale.spacingMd + UIScale.spacingXs
                            Layout.topMargin: UIScale.spacingXs
                            Layout.bottomMargin: UIScale.spacingXs
                            visible: BluetoothService.available && BluetoothService.powered && BluetoothService.pairedDevices.length > 0
                        }

                        Repeater {
                            model: BluetoothService.pairedDevices

                            delegate: Rectangle {
                                id: devRow

                                required property var modelData

                                readonly property bool isLoading: modelData.state === BluetoothDeviceState.Connecting || modelData.state === BluetoothDeviceState.Disconnecting

                                property int sysBattery: -1
                                readonly property bool hasBattery: modelData.batteryAvailable || sysBattery >= 0
                                readonly property real batteryLevel: modelData.batteryAvailable ? modelData.battery : (sysBattery >= 0 ? sysBattery / 100.0 : 0.0)

                                Process {
                                    id: sysBattProc
                                    command: ["cat", "/sys/class/power_supply/ps-controller-battery-" + devRow.modelData.address.toLowerCase() + "/capacity"]
                                    stdout: SplitParser {
                                        onRead: function (data) {
                                            var n = parseInt(data.trim());
                                            devRow.sysBattery = isNaN(n) ? -1 : n;
                                        }
                                    }
                                }

                                Timer {
                                    interval: 60000
                                    running: !devRow.modelData.batteryAvailable && devRow.modelData.connected
                                    repeat: true
                                    triggeredOnStart: true
                                    onTriggered: {
                                        if (!sysBattProc.running)
                                            sysBattProc.running = true;
                                    }
                                }

                                onSysBatteryChanged: {
                                    if (!modelData.batteryAvailable)
                                        BluetoothService.checkBatteryWarning(modelData.address, sysBattery >= 0 ? sysBattery / 100.0 : -1.0, modelData.name || modelData.address);
                                }

                                Connections {
                                    target: devRow.modelData
                                    function onBatteryChanged() {
                                        if (devRow.modelData.batteryAvailable)
                                            BluetoothService.checkBatteryWarning(devRow.modelData.address, devRow.modelData.battery, devRow.modelData.name || devRow.modelData.address);
                                    }
                                }

                                Layout.fillWidth: true
                                Layout.leftMargin: UIScale.spacingMd
                                Layout.rightMargin: UIScale.spacingMd
                                Layout.bottomMargin: UIScale.spacingXs
                                radius: UIScale.radiusMd
                                color: Colors.surface
                                implicitHeight: devInner.implicitHeight + Math.round(18 * UIScale.value)
                                visible: BluetoothService.available && BluetoothService.powered

                                RowLayout {
                                    id: devInner
                                    anchors {
                                        left: parent.left
                                        right: parent.right
                                        top: parent.top
                                        margins: UIScale.spacingMd
                                    }
                                    spacing: UIScale.spacingSm

                                    Rectangle {
                                        implicitWidth: Math.round(32 * UIScale.value)
                                        implicitHeight: Math.round(32 * UIScale.value)
                                        radius: UIScale.radiusSm
                                        color: devRow.modelData.connected ? Colors.withAlpha(Colors.accent, 0.15) : Colors.surfaceHigh
                                        Behavior on color {
                                            ColorAnimation {
                                                duration: Anim.fast
                                            }
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            text: BluetoothService.deviceIcon(devRow.modelData.icon, devRow.modelData.name)
                                            font.pixelSize: Math.round(16 * UIScale.value)
                                            color: devRow.modelData.connected ? Colors.accent : Colors.muted
                                            Behavior on color {
                                                ColorAnimation {
                                                    duration: Anim.fast
                                                }
                                            }
                                        }
                                    }

                                    Column {
                                        Layout.fillWidth: true
                                        spacing: Math.round(3 * UIScale.value)

                                        Text {
                                            text: devRow.modelData.name || devRow.modelData.address
                                            color: Colors.text
                                            font.pixelSize: UIScale.fontSmall
                                            font.weight: Font.DemiBold
                                            elide: Text.ElideRight
                                            width: parent.width
                                        }

                                        Row {
                                            spacing: Math.round(4 * UIScale.value)

                                            Rectangle {
                                                width: Math.round(6 * UIScale.value)
                                                height: Math.round(6 * UIScale.value)
                                                radius: width / 2
                                                anchors.verticalCenter: parent.verticalCenter
                                                color: devRow.modelData.connected ? Colors.accent : Colors.withAlpha(Colors.text, 0.2)
                                                Behavior on color {
                                                    ColorAnimation {
                                                        duration: Anim.fast
                                                    }
                                                }
                                            }

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                color: devRow.modelData.connected ? Colors.accent : Colors.textDim
                                                font.pixelSize: UIScale.fontTiny
                                                Behavior on color {
                                                    ColorAnimation {
                                                        duration: Anim.fast
                                                    }
                                                }
                                                text: {
                                                    if (devRow.modelData.state === BluetoothDeviceState.Connecting)
                                                        return I18n.t("bluetooth.connecting");
                                                    if (devRow.modelData.state === BluetoothDeviceState.Disconnecting)
                                                        return I18n.t("bluetooth.disconnecting");
                                                    if (devRow.modelData.connected && devRow.hasBattery)
                                                        return I18n.t("bluetooth.connectedWithBattery", [Math.round(devRow.batteryLevel * 100)]);
                                                    return devRow.modelData.connected ? I18n.t("bluetooth.connected") : I18n.t("bluetooth.paired");
                                                }
                                            }
                                        }

                                        Column {
                                            width: parent.width
                                            spacing: Math.round(3 * UIScale.value)
                                            topPadding: Math.round(4 * UIScale.value)
                                            visible: AirPodsService.connected && devRow.modelData.address === AirPodsService._activeMac

                                            BluetoothBattBar {
                                                label: "L"
                                                level: AirPodsService.leftLevel
                                                charging: AirPodsService.leftCharging
                                                dim: !AirPodsService.leftEar
                                            }
                                            BluetoothBattBar {
                                                label: "R"
                                                level: AirPodsService.rightLevel
                                                charging: AirPodsService.rightCharging
                                                dim: !AirPodsService.rightEar
                                            }
                                            BluetoothBattBar {
                                                label: I18n.t("bluetooth.case")
                                                level: AirPodsService.caseLevel
                                                charging: AirPodsService.caseCharging
                                                visible: AirPodsService.caseLevel > 0
                                            }
                                        }
                                    }

                                    Rectangle {
                                        implicitWidth: Math.max(connLabel.implicitWidth + Math.round(14 * UIScale.value), Math.round(34 * UIScale.value))
                                        implicitHeight: Math.round(26 * UIScale.value)
                                        radius: UIScale.radiusSm
                                        opacity: devRow.isLoading ? 0.55 : 1.0
                                        Behavior on opacity {
                                            NumberAnimation {
                                                duration: Anim.fast
                                            }
                                        }
                                        color: connHover.hovered ? (devRow.modelData.connected ? Colors.withAlpha("#e05c5c", 0.22) : Colors.withAlpha(Colors.accent, 0.22)) : (devRow.modelData.connected ? Colors.withAlpha("#e05c5c", 0.1) : Colors.withAlpha(Colors.accent, 0.1))
                                        Behavior on color {
                                            ColorAnimation {
                                                duration: Anim.fast
                                            }
                                        }

                                        Text {
                                            id: connLabel
                                            anchors.centerIn: parent
                                            text: devRow.modelData.connected ? I18n.t("bluetooth.disconnect") : I18n.t("bluetooth.connect")
                                            color: devRow.modelData.connected ? "#e05c5c" : Colors.accent
                                            font.pixelSize: UIScale.fontTiny
                                            font.weight: Font.DemiBold
                                            visible: !devRow.isLoading
                                            Behavior on color {
                                                ColorAnimation {
                                                    duration: Anim.fast
                                                }
                                            }
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰑓"
                                            font.pixelSize: Math.round(12 * UIScale.value)
                                            color: Colors.accent
                                            visible: devRow.isLoading
                                            RotationAnimator on rotation {
                                                running: devRow.isLoading
                                                from: 0
                                                to: 360
                                                duration: 800
                                                loops: Animation.Infinite
                                            }
                                        }

                                        HoverHandler {
                                            id: connHover
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            enabled: !devRow.isLoading
                                            onClicked: devRow.modelData.connected = !devRow.modelData.connected
                                        }
                                    }
                                }
                            }
                        }

                        Text {
                            text: I18n.t("bluetooth.noPairedDevices")
                            color: Colors.muted
                            font.pixelSize: UIScale.fontSmall
                            horizontalAlignment: Text.AlignHCenter
                            Layout.fillWidth: true
                            Layout.topMargin: UIScale.spacingLg
                            visible: BluetoothService.available && BluetoothService.powered && BluetoothService.pairedDevices.length === 0
                        }

                        Item {
                            implicitHeight: UIScale.spacingSm
                        }
                    }
                }
            }
        }
    }
}
