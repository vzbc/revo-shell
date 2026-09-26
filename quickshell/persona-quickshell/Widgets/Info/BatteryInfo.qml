pragma Singleton
pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Services.UPower
import QtQuick

Singleton {
    id: root

    readonly property bool available: UPower.displayDevice?.isLaptopBattery ?? false
    readonly property real percentage: UPower.displayDevice?.percentage ?? 0
    readonly property var chargeState: UPower.displayDevice?.state ?? null
    readonly property bool isCharging: chargeState === UPowerDeviceState.Charging
    readonly property bool isPluggedIn: isCharging || chargeState === UPowerDeviceState.PendingCharge
    readonly property bool isFull: chargeState === UPowerDeviceState.FullyCharged
    readonly property bool isLow: available && percentage <= 0.20
    readonly property bool isCritical: available && percentage <= 0.10
    readonly property real energyRate: UPower.displayDevice?.changeRate ?? 0
    readonly property real timeToEmpty: UPower.displayDevice?.timeToEmpty ?? 0
    readonly property real timeToFull: UPower.displayDevice?.timeToFull ?? 0

    readonly property string icon: {
        if (!available)
            return "󰂑";
        if (isCharging || isFull)
            return "󰂄";
        var icons = ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"];
        return icons[Math.min(Math.floor(percentage * 10), 9)];
    }

    readonly property string percentageString: Math.round(percentage * 100) + "%"

    readonly property string timeRemainingString: {
        if (isCharging && timeToFull > 0) {
            var h = Math.floor(timeToFull / 3600);
            var m = Math.floor((timeToFull % 3600) / 60);
            return h + "h " + m + "m until full";
        } else if (!isCharging && timeToEmpty > 0) {
            var h = Math.floor(timeToEmpty / 3600);
            var m = Math.floor((timeToEmpty % 3600) / 60);
            return h + "h " + m + "m remaining";
        }
        return "";
    }
}
