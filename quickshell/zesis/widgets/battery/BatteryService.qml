pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

Singleton {
    id: root

    property bool testMode: false
    property int testPercent: 4
    property bool testCharging: false
    property bool testFull: false
    property real testPowerW: 12.5
    property real testHours: 2.5

    readonly property var _dev: UPower.displayDevice

    readonly property bool available: testMode ? true : _dev.ready && _dev.isPresent
    readonly property int percent: testMode ? testPercent : Math.round(_dev.percentage * 100)
    readonly property real powerW: testMode ? testPowerW : Math.abs(_dev.changeRate)

    readonly property bool charging: testMode ? testCharging : _dev.state === UPowerDeviceState.Charging || _dev.state === UPowerDeviceState.PendingCharge
    readonly property bool full: testMode ? testFull : _dev.state === UPowerDeviceState.FullyCharged
    readonly property bool discharging: testMode ? (!testCharging && !testFull) : _dev.state === UPowerDeviceState.Discharging || _dev.state === UPowerDeviceState.PendingDischarge

    readonly property string status: {
        if (testMode) {
            if (testFull)
                return "Full";
            if (testCharging)
                return "Charging";
            return "Discharging";
        }
        switch (_dev.state) {
        case UPowerDeviceState.Charging:
            return "Charging";
        case UPowerDeviceState.Discharging:
            return "Discharging";
        case UPowerDeviceState.FullyCharged:
            return "Full";
        case UPowerDeviceState.PendingCharge:
            return "Pending Charge";
        case UPowerDeviceState.PendingDischarge:
            return "Pending Discharge";
        case UPowerDeviceState.Empty:
            return "Empty";
        default:
            return "Unknown";
        }
    }

    readonly property real hoursRemaining: {
        if (!available || full)
            return -1;
        if (testMode)
            return (charging || discharging) ? testHours : -1;
        if (charging && _dev.timeToFull > 0)
            return _dev.timeToFull / 3600;
        if (discharging && _dev.timeToEmpty > 0)
            return _dev.timeToEmpty / 3600;
        return -1;
    }

    // { w10: bool, w5: bool } - reset when plugged in or above 10%
    property var _warnings: ({
            w10: false,
            w5: false
        })

    function _checkWarnings() {
        if (testMode || !available || charging || full) {
            _warnings = {
                w10: false,
                w5: false
            };
            return;
        }
        if (percent > 10) {
            _warnings = {
                w10: false,
                w5: false
            };
            return;
        }
        var w = _warnings;
        if (percent <= 5 && !w.w5) {
            _warnings = {
                w10: true,
                w5: true
            };
            _notifyProc.command = ["notify-send", "-u", "critical", "-i", "battery-caution", "Battery Critical", "Battery is at " + percent + "%. Plug in now."];
            _notifyProc.running = true;
        } else if (percent <= 10 && !w.w10) {
            _warnings = {
                w10: true,
                w5: false
            };
            _notifyProc.command = ["notify-send", "-u", "normal", "-i", "battery-low", "Battery Low", "Battery is at " + percent + "%."];
            _notifyProc.running = true;
        }
    }

    onPercentChanged: _checkWarnings()
    onChargingChanged: _checkWarnings()
    onFullChanged: _checkWarnings()

    Process {
        id: _notifyProc
    }

    readonly property string icon: {
        if (!available)
            return "";
        if (charging || full)
            return "󰂄";
        if (percent >= 90)
            return "󰁹";
        if (percent >= 70)
            return "󰂁";
        if (percent >= 50)
            return "󰁿";
        if (percent >= 30)
            return "󰁽";
        if (percent >= 10)
            return "󰁺";
        return "󰂃";
    }
}
