import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import qs.components
import qs.popups

BarButton {
    id: root

    readonly property var device: UPower.displayDevice
    readonly property bool charging: device.state === UPowerDeviceState.Charging
        || device.state === UPowerDeviceState.PendingCharge
        || device.state === UPowerDeviceState.FullyCharged

    visible: device.ready && device.isLaptopBattery
    implicitWidth: batteryRow.implicitWidth + 12
    active: popup.shown
    onClicked: popup.toggle()

    RowLayout {
        id: batteryRow

        anchors.centerIn: parent
        spacing: 4

        BatteryIcon {
            level: root.device.percentage
            charging: root.charging
            color: root.textColor
        }

        BarText {
            text: Math.round(root.device.percentage * 100) + "%"
            color: root.textColor
        }
    }

    BatteryPopup {
        id: popup
        anchorItem: root
        align: Qt.AlignRight
    }
}
