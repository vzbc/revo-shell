pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.UPower

Singleton {
    id: root

    readonly property var device: UPower.displayDevice
    readonly property bool available: device ? device.isLaptopBattery : false
    readonly property real percentage: device ? device.percentage : 1.0
    readonly property bool isCharging: device ? device.state === UPowerDeviceState.Charging : false
    readonly property bool isFull: device ? device.state === UPowerDeviceState.FullyCharged : false
    readonly property real timeToEmpty: device ? device.timeToEmpty : 0
    readonly property real timeToFull: device ? device.timeToFull : 0

    readonly property int iconLevel: {
        const p = root.percentage * 100;
        if (p > 95) return 5;
        if (p > 75) return 4;
        if (p > 50) return 3;
        if (p > 25) return 2;
        return 1;
    }
}
