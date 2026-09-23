pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import "../../"
import "../shared"
import "../airpods"

Item {
    id: root

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        PanelHeader {
            Layout.fillWidth: true
            breadcrumb: I18n.t("bluetooth.breadcrumb")
            title: I18n.t("bluetooth.title")
            rightActions: Component {
                RowLayout {
                    spacing: UIScale.spacingSm

                    Rectangle {
                        implicitHeight: Math.round(34 * UIScale.value)
                        implicitWidth: scanRow.implicitWidth + Math.round(22 * UIScale.value)
                        radius: UIScale.radiusMd
                        visible: BluetoothService.powered
                        color: BluetoothService.scanning ? Colors.withAlpha(Colors.accent, 0.18) : (scanMa.containsMouse ? Colors.withAlpha(Colors.text, 0.08) : Colors.withAlpha(Colors.text, 0.05))
                        border.color: BluetoothService.scanning ? Colors.withAlpha(Colors.accent, 0.35) : Colors.withAlpha(Colors.text, 0.08)
                        border.width: 1
                        Behavior on color {
                            ColorAnimation {
                                duration: Anim.fast
                            }
                        }
                        Behavior on border.color {
                            ColorAnimation {
                                duration: Anim.fast
                            }
                        }

                        Row {
                            id: scanRow
                            anchors.centerIn: parent
                            spacing: Math.round(6 * UIScale.value)

                            Text {
                                text: "󰂱"
                                font.pixelSize: Math.round(15 * UIScale.value)
                                color: BluetoothService.scanning ? Colors.accent : Colors.textDim
                                anchors.verticalCenter: parent.verticalCenter
                                Behavior on color {
                                    ColorAnimation {
                                        duration: Anim.fast
                                    }
                                }

                                RotationAnimator on rotation {
                                    running: BluetoothService.scanning
                                    from: 0
                                    to: 360
                                    duration: 1400
                                    loops: Animation.Infinite
                                }
                            }
                            Text {
                                text: BluetoothService.scanning ? I18n.t("bluetooth.stop") : I18n.t("bluetooth.scan")
                                color: BluetoothService.scanning ? Colors.accent : Colors.textDim
                                font.pixelSize: UIScale.fontBody
                                font.weight: Font.DemiBold
                                anchors.verticalCenter: parent.verticalCenter
                                Behavior on color {
                                    ColorAnimation {
                                        duration: Anim.fast
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: scanMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: BluetoothService.scanning ? BluetoothService.stopScan() : BluetoothService.startScan()
                        }
                    }

                    ToggleSwitch {
                        checked: BluetoothService.powered
                        onToggled: {
                            if (BluetoothService.activeAdapter)
                                BluetoothService.activeAdapter.enabled = !BluetoothService.powered;
                        }
                    }
                }
            }
        }

        Flickable {
            id: flick
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: col.implicitHeight + UIScale.spacingMd
            clip: true
            flickableDirection: Flickable.VerticalFlick

            ColumnLayout {
                id: col
                width: flick.width
                spacing: 0

                Item {
                    implicitHeight: UIScale.spacingMd
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

                // Adapter picker (only when multiple adapters)

                SectionLabel {
                    text: I18n.t("bluetooth.adapterSection")
                    Layout.leftMargin: UIScale.panelPad
                    Layout.topMargin: UIScale.spacingXs
                    Layout.bottomMargin: UIScale.spacingXs
                    visible: BluetoothService.available && Bluetooth.adapters.values.length > 1
                }

                Flow {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                    Layout.bottomMargin: UIScale.spacingMd
                    spacing: UIScale.spacingSm
                    visible: BluetoothService.available && Bluetooth.adapters.values.length > 1

                    Repeater {
                        model: Bluetooth.adapters.values

                        delegate: Rectangle {
                            id: adapterChip
                            required property var modelData

                            readonly property bool isActive: BluetoothService.activeAdapter === adapterChip.modelData

                            implicitHeight: Math.round(30 * UIScale.value)
                            implicitWidth: adapterChipRow.implicitWidth + Math.round(18 * UIScale.value)
                            radius: UIScale.radiusSm
                            color: isActive ? Colors.withAlpha(Colors.accent, 0.18) : (chipMa.containsMouse ? Colors.withAlpha(Colors.text, 0.08) : Colors.withAlpha(Colors.text, 0.05))
                            border.color: isActive ? Colors.withAlpha(Colors.accent, 0.4) : Colors.withAlpha(Colors.text, 0.08)
                            border.width: 1
                            Behavior on color {
                                ColorAnimation {
                                    duration: Anim.fast
                                }
                            }
                            Behavior on border.color {
                                ColorAnimation {
                                    duration: Anim.fast
                                }
                            }

                            Row {
                                id: adapterChipRow
                                anchors.centerIn: parent
                                spacing: Math.round(5 * UIScale.value)

                                Text {
                                    text: "󰂯"
                                    font.pixelSize: Math.round(11 * UIScale.value)
                                    color: adapterChip.isActive ? Colors.accent : Colors.textDim
                                    anchors.verticalCenter: parent.verticalCenter
                                    Behavior on color {
                                        ColorAnimation {
                                            duration: Anim.fast
                                        }
                                    }
                                }
                                Text {
                                    text: adapterChip.modelData?.name ?? ""
                                    color: adapterChip.isActive ? Colors.accent : Colors.textDim
                                    font.pixelSize: UIScale.fontSmall
                                    font.weight: adapterChip.isActive ? Font.DemiBold : Font.Normal
                                    anchors.verticalCenter: parent.verticalCenter
                                    Behavior on color {
                                        ColorAnimation {
                                            duration: Anim.fast
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: chipMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: BluetoothService.selectAdapter(adapterChip.modelData)
                            }
                        }
                    }
                }

                // Paired devices

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                    Layout.bottomMargin: UIScale.spacingXs
                    visible: BluetoothService.available && BluetoothService.powered

                    SectionLabel {
                        text: I18n.t("bluetooth.pairedDevicesSection")
                        Layout.fillWidth: true
                    }
                    Text {
                        text: BluetoothService.pairedDevices.length + ""
                        color: Colors.muted
                        font.pixelSize: UIScale.fontCaption
                        font.family: "monospace"
                    }
                }

                Repeater {
                    model: BluetoothService.pairedDevices

                    delegate: Item {
                        id: pairedItem
                        required property var modelData

                        readonly property bool isLoading: modelData.state === BluetoothDeviceState.Connecting || modelData.state === BluetoothDeviceState.Disconnecting

                        readonly property bool hasBattery: modelData.batteryAvailable
                        readonly property real batteryLevel: modelData.battery

                        Layout.fillWidth: true
                        Layout.leftMargin: UIScale.panelPad
                        Layout.rightMargin: UIScale.panelPad
                        Layout.bottomMargin: UIScale.spacingSm
                        implicitHeight: pairedCard.implicitHeight
                        visible: BluetoothService.available && BluetoothService.powered

                        HoverHandler {
                            id: cardHover
                        }

                        Rectangle {
                            id: pairedCard
                            anchors.left: parent.left
                            anchors.right: parent.right
                            radius: UIScale.radiusMd
                            color: Colors.surface
                            implicitHeight: cardContent.implicitHeight + UIScale.spacingMd * 2

                            Rectangle {
                                anchors.fill: parent
                                radius: parent.radius
                                color: Colors.withAlpha(Colors.text, 0.025)
                                opacity: cardHover.hovered ? 1 : 0
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: Anim.fast
                                    }
                                }
                            }

                            Column {
                                id: cardContent
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    top: parent.top
                                    margins: UIScale.spacingMd
                                }
                                spacing: Math.round(8 * UIScale.value)

                                // Main row: icon · info · buttons
                                RowLayout {
                                    width: parent.width
                                    spacing: UIScale.spacingSm

                                    // Device type icon
                                    Rectangle {
                                        implicitWidth: Math.round(36 * UIScale.value)
                                        implicitHeight: Math.round(36 * UIScale.value)
                                        radius: UIScale.radiusSm
                                        color: pairedItem.modelData.connected ? Colors.withAlpha(Colors.accent, 0.15) : Colors.surfaceHigh
                                        Behavior on color {
                                            ColorAnimation {
                                                duration: Anim.fast
                                            }
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            text: BluetoothService.deviceIcon(pairedItem.modelData.icon, pairedItem.modelData.name)
                                            font.pixelSize: Math.round(18 * UIScale.value)
                                            color: pairedItem.modelData.connected ? Colors.accent : Colors.muted
                                            Behavior on color {
                                                ColorAnimation {
                                                    duration: Anim.fast
                                                }
                                            }
                                        }
                                    }

                                    // Name + status
                                    Column {
                                        Layout.fillWidth: true
                                        spacing: Math.round(3 * UIScale.value)

                                        Text {
                                            text: pairedItem.modelData.name || pairedItem.modelData.address
                                            color: Colors.text
                                            font.pixelSize: UIScale.fontBody
                                            font.weight: Font.DemiBold
                                            elide: Text.ElideRight
                                            width: parent.width
                                        }
                                        Row {
                                            spacing: Math.round(5 * UIScale.value)
                                            Rectangle {
                                                width: Math.round(6 * UIScale.value)
                                                height: Math.round(6 * UIScale.value)
                                                radius: width / 2
                                                anchors.verticalCenter: parent.verticalCenter
                                                color: pairedItem.modelData.connected ? Colors.accent : pairedItem.isLoading ? Colors.withAlpha(Colors.accent, 0.45) : Colors.withAlpha(Colors.text, 0.18)
                                                Behavior on color {
                                                    ColorAnimation {
                                                        duration: Anim.fast
                                                    }
                                                }
                                            }
                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                color: pairedItem.modelData.connected ? Colors.accent : Colors.textDim
                                                font.pixelSize: UIScale.fontSmall
                                                Behavior on color {
                                                    ColorAnimation {
                                                        duration: Anim.fast
                                                    }
                                                }
                                                text: {
                                                    if (pairedItem.modelData.state === BluetoothDeviceState.Connecting)
                                                        return I18n.t("bluetooth.connecting");
                                                    if (pairedItem.modelData.state === BluetoothDeviceState.Disconnecting)
                                                        return I18n.t("bluetooth.disconnecting");
                                                    if (pairedItem.modelData.connected) {
                                                        if (pairedItem.hasBattery)
                                                            return I18n.t("bluetooth.connectedWithBattery", [Math.round(pairedItem.batteryLevel * 100)]);
                                                        return I18n.t("bluetooth.connected");
                                                    }
                                                    return I18n.t("bluetooth.paired");
                                                }
                                            }
                                            Text {
                                                text: "·  " + pairedItem.modelData.address
                                                color: Colors.muted
                                                font.pixelSize: UIScale.fontSmall
                                                font.family: "monospace"
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                        }
                                    }

                                    // Action buttons
                                    Row {
                                        spacing: Math.round(6 * UIScale.value)

                                        // Auto-connect (trust) toggle
                                        Rectangle {
                                            implicitWidth: Math.round(44 * UIScale.value)
                                            implicitHeight: Math.round(30 * UIScale.value)
                                            radius: UIScale.radiusSm
                                            color: pairedItem.modelData.trusted ? (autoHover.hovered ? Colors.withAlpha(Colors.accent, 0.28) : Colors.withAlpha(Colors.accent, 0.18)) : (autoHover.hovered ? Colors.withAlpha(Colors.text, 0.08) : Colors.withAlpha(Colors.text, 0.04))
                                            border.color: pairedItem.modelData.trusted ? Colors.withAlpha(Colors.accent, 0.4) : Colors.withAlpha(Colors.text, 0.1)
                                            border.width: 1
                                            Behavior on color {
                                                ColorAnimation {
                                                    duration: Anim.fast
                                                }
                                            }
                                            Behavior on border.color {
                                                ColorAnimation {
                                                    duration: Anim.fast
                                                }
                                            }

                                            Text {
                                                anchors.centerIn: parent
                                                text: I18n.t("common.auto")
                                                color: pairedItem.modelData.trusted ? Colors.accent : Colors.textDim
                                                font.pixelSize: UIScale.fontSmall
                                                font.weight: pairedItem.modelData.trusted ? Font.DemiBold : Font.Normal
                                                Behavior on color {
                                                    ColorAnimation {
                                                        duration: Anim.fast
                                                    }
                                                }
                                            }

                                            HoverHandler {
                                                id: autoHover
                                            }
                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: pairedItem.modelData.trusted = !pairedItem.modelData.trusted
                                            }
                                        }

                                        // Connect / Disconnect
                                        Rectangle {
                                            implicitWidth: Math.max(connLabel.implicitWidth + Math.round(16 * UIScale.value), Math.round(42 * UIScale.value))
                                            implicitHeight: Math.round(30 * UIScale.value)
                                            radius: UIScale.radiusSm
                                            opacity: pairedItem.isLoading ? 0.55 : 1.0
                                            Behavior on opacity {
                                                NumberAnimation {
                                                    duration: Anim.fast
                                                }
                                            }
                                            color: connHover.hovered ? (pairedItem.modelData.connected ? Colors.withAlpha("#e05c5c", 0.22) : Colors.withAlpha(Colors.accent, 0.22)) : (pairedItem.modelData.connected ? Colors.withAlpha("#e05c5c", 0.1) : Colors.withAlpha(Colors.accent, 0.1))
                                            Behavior on color {
                                                ColorAnimation {
                                                    duration: Anim.fast
                                                }
                                            }

                                            Text {
                                                id: connLabel
                                                anchors.centerIn: parent
                                                text: pairedItem.modelData.connected ? I18n.t("bluetooth.disconnect") : I18n.t("bluetooth.connect")
                                                color: pairedItem.modelData.connected ? "#e05c5c" : Colors.accent
                                                font.pixelSize: UIScale.fontSmall
                                                font.weight: Font.DemiBold
                                                visible: !pairedItem.isLoading
                                                Behavior on color {
                                                    ColorAnimation {
                                                        duration: Anim.fast
                                                    }
                                                }
                                            }

                                            Text {
                                                anchors.centerIn: parent
                                                text: "󰑓"
                                                font.pixelSize: Math.round(14 * UIScale.value)
                                                color: Colors.accent
                                                visible: pairedItem.isLoading
                                                RotationAnimator on rotation {
                                                    running: pairedItem.isLoading
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
                                                enabled: !pairedItem.isLoading
                                                onClicked: pairedItem.modelData.connected = !pairedItem.modelData.connected
                                            }
                                        }

                                        // Forget
                                        Rectangle {
                                            implicitWidth: forgetLabel.implicitWidth + Math.round(14 * UIScale.value)
                                            implicitHeight: Math.round(30 * UIScale.value)
                                            radius: UIScale.radiusSm
                                            color: forgetHover.hovered ? Colors.withAlpha("#e05c5c", 0.18) : Colors.withAlpha("#e05c5c", 0.07)
                                            Behavior on color {
                                                ColorAnimation {
                                                    duration: Anim.fast
                                                }
                                            }

                                            Text {
                                                id: forgetLabel
                                                anchors.centerIn: parent
                                                text: I18n.t("bluetooth.forget")
                                                color: forgetHover.hovered ? "#e05c5c" : Colors.withAlpha("#e05c5c", 0.5)
                                                font.pixelSize: UIScale.fontSmall
                                                font.weight: Font.DemiBold
                                                Behavior on color {
                                                    ColorAnimation {
                                                        duration: Anim.fast
                                                    }
                                                }
                                            }

                                            HoverHandler {
                                                id: forgetHover
                                            }
                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: pairedItem.modelData.forget()
                                            }
                                        }
                                    }
                                }

                                // Battery bar, visible only when connected and battery data available
                                Rectangle {
                                    width: parent.width
                                    height: Math.round(3 * UIScale.value)
                                    radius: height / 2
                                    color: Colors.withAlpha(Colors.text, 0.07)
                                    visible: pairedItem.modelData.connected && pairedItem.hasBattery

                                    Rectangle {
                                        width: parent.width * pairedItem.batteryLevel
                                        height: parent.height
                                        radius: parent.radius
                                        color: BluetoothService.batteryColor(pairedItem.batteryLevel)
                                        Behavior on width {
                                            NumberAnimation {
                                                duration: Anim.slow
                                                easing.type: Easing.OutCubic
                                            }
                                        }
                                        Behavior on color {
                                            ColorAnimation {
                                                duration: Anim.slow
                                            }
                                        }
                                    }
                                }

                                // AirPods L/R/case battery bars
                                Column {
                                    width: parent.width
                                    spacing: Math.round(4 * UIScale.value)
                                    visible: AirPodsService.connected && pairedItem.modelData.address === AirPodsService._activeMac

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
                        }
                    }
                }

                Text {
                    text: I18n.t("bluetooth.noPairedDevices")
                    color: Colors.muted
                    font.pixelSize: UIScale.fontSmall
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                    Layout.topMargin: UIScale.spacingMd
                    Layout.bottomMargin: UIScale.spacingMd
                    visible: BluetoothService.available && BluetoothService.powered && BluetoothService.pairedDevices.length === 0
                }

                // Nearby devices

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                    Layout.topMargin: UIScale.spacingMd
                    Layout.bottomMargin: UIScale.spacingXs
                    visible: BluetoothService.available && BluetoothService.powered && (BluetoothService.scanning || BluetoothService.nearbyDevices.length > 0)

                    SectionLabel {
                        text: I18n.t("bluetooth.nearbyDevicesSection")
                        Layout.fillWidth: true
                    }

                    Row {
                        spacing: Math.round(5 * UIScale.value)
                        visible: BluetoothService.scanning

                        Rectangle {
                            width: Math.round(6 * UIScale.value)
                            height: Math.round(6 * UIScale.value)
                            radius: width / 2
                            anchors.verticalCenter: parent.verticalCenter
                            color: Colors.accent

                            SequentialAnimation on opacity {
                                loops: Animation.Infinite
                                NumberAnimation {
                                    to: 0.25
                                    duration: 700
                                    easing.type: Easing.InOutSine
                                }
                                NumberAnimation {
                                    to: 1.0
                                    duration: 700
                                    easing.type: Easing.InOutSine
                                }
                            }
                        }
                        Text {
                            text: I18n.t("bluetooth.scanning")
                            color: Colors.accent
                            font.pixelSize: UIScale.fontCaption
                            font.weight: Font.Bold
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Text {
                        text: BluetoothService.nearbyDevices.length + ""
                        color: Colors.muted
                        font.pixelSize: UIScale.fontCaption
                        font.family: "monospace"
                        visible: !BluetoothService.scanning && BluetoothService.nearbyDevices.length > 0
                    }
                }

                Text {
                    text: I18n.t("bluetooth.lookingForDevices")
                    color: Colors.muted
                    font.pixelSize: UIScale.fontSmall
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                    Layout.topMargin: UIScale.spacingMd
                    Layout.bottomMargin: UIScale.spacingSm
                    visible: BluetoothService.available && BluetoothService.powered && BluetoothService.scanning && BluetoothService.nearbyDevices.length === 0
                }

                Repeater {
                    model: BluetoothService.nearbyDevices

                    delegate: Item {
                        id: nearbyItem
                        required property var modelData

                        Layout.fillWidth: true
                        Layout.leftMargin: UIScale.panelPad
                        Layout.rightMargin: UIScale.panelPad
                        Layout.bottomMargin: UIScale.spacingSm
                        implicitHeight: nearbyCard.implicitHeight
                        visible: BluetoothService.available && BluetoothService.powered

                        Rectangle {
                            id: nearbyCard
                            anchors.left: parent.left
                            anchors.right: parent.right
                            radius: UIScale.radiusMd
                            color: Colors.withAlpha(Colors.text, 0.04)
                            border.color: Colors.withAlpha(Colors.text, 0.07)
                            border.width: 1
                            implicitHeight: nearbyInner.implicitHeight + Math.round(20 * UIScale.value)

                            RowLayout {
                                id: nearbyInner
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    top: parent.top
                                    margins: UIScale.spacingMd
                                }
                                spacing: UIScale.spacingSm

                                Rectangle {
                                    implicitWidth: Math.round(36 * UIScale.value)
                                    implicitHeight: Math.round(36 * UIScale.value)
                                    radius: UIScale.radiusSm
                                    color: Colors.surfaceHigh

                                    Text {
                                        anchors.centerIn: parent
                                        text: BluetoothService.deviceIcon(nearbyItem.modelData.icon, nearbyItem.modelData.name)
                                        font.pixelSize: Math.round(18 * UIScale.value)
                                        color: Colors.textDim
                                    }
                                }

                                Column {
                                    Layout.fillWidth: true
                                    spacing: Math.round(3 * UIScale.value)

                                    Text {
                                        text: nearbyItem.modelData.name || I18n.t("bluetooth.unknownDevice")
                                        color: Colors.text
                                        font.pixelSize: UIScale.fontBody
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                        width: parent.width
                                    }
                                    Text {
                                        text: nearbyItem.modelData.pairing ? I18n.t("bluetooth.pairing") : nearbyItem.modelData.address
                                        color: nearbyItem.modelData.pairing ? Colors.accent : Colors.muted
                                        font.pixelSize: UIScale.fontSmall
                                        font.family: nearbyItem.modelData.pairing ? "" : "monospace"
                                        Behavior on color {
                                            ColorAnimation {
                                                duration: Anim.fast
                                            }
                                        }
                                    }
                                }

                                // Pair / Cancel
                                Rectangle {
                                    implicitWidth: Math.max(pairLabel.implicitWidth + Math.round(18 * UIScale.value), Math.round(42 * UIScale.value))
                                    implicitHeight: Math.round(30 * UIScale.value)
                                    radius: UIScale.radiusSm
                                    color: nearbyItem.modelData.pairing ? Colors.withAlpha(Colors.accent, 0.08) : (pairHover.hovered ? Colors.withAlpha(Colors.accent, 0.22) : Colors.withAlpha(Colors.accent, 0.12))
                                    border.color: Colors.withAlpha(Colors.accent, nearbyItem.modelData.pairing ? 0.15 : 0.3)
                                    border.width: 1
                                    Behavior on color {
                                        ColorAnimation {
                                            duration: Anim.fast
                                        }
                                    }

                                    Text {
                                        id: pairLabel
                                        anchors.centerIn: parent
                                        text: nearbyItem.modelData.pairing ? I18n.t("common.cancel") : I18n.t("bluetooth.pair")
                                        color: Colors.accent
                                        font.pixelSize: UIScale.fontSmall
                                        font.weight: Font.DemiBold
                                        opacity: nearbyItem.modelData.pairing ? 0.6 : 1.0
                                        Behavior on opacity {
                                            NumberAnimation {
                                                duration: Anim.fast
                                            }
                                        }
                                    }

                                    Text {
                                        anchors {
                                            right: pairLabel.left
                                            rightMargin: Math.round(5 * UIScale.value)
                                            verticalCenter: parent.verticalCenter
                                        }
                                        text: "󰑓"
                                        font.pixelSize: Math.round(12 * UIScale.value)
                                        color: Colors.accent
                                        visible: nearbyItem.modelData.pairing
                                        opacity: 0.6

                                        RotationAnimator on rotation {
                                            running: nearbyItem.modelData.pairing
                                            from: 0
                                            to: 360
                                            duration: 800
                                            loops: Animation.Infinite
                                        }
                                    }

                                    HoverHandler {
                                        id: pairHover
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (nearbyItem.modelData.pairing)
                                                BluetoothService.cancelPairDevice(nearbyItem.modelData);
                                            else
                                                BluetoothService.pairDevice(nearbyItem.modelData);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Item {
                    implicitHeight: UIScale.spacingMd
                }
            }
        }
    }
}
