import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import qs.components
import qs.config

BarPopup {
    id: popup

    readonly property var device: UPower.displayDevice

    function formatTime(seconds) {
        if (seconds <= 0) return ""
        const h = Math.floor(seconds / 3600)
        const m = Math.floor(seconds / 60) % 60
        return h > 0 ? `${h}h ${m}m` : `${m}m`
    }

    readonly property string status: {
        switch (device.state) {
        case UPowerDeviceState.Charging: return "Charging"
        case UPowerDeviceState.FullyCharged: return "Fully charged"
        case UPowerDeviceState.PendingCharge: return "Plugged in"
        default: return UPower.onBattery ? "On battery" : "Plugged in"
        }
    }

    readonly property string remaining: device.state === UPowerDeviceState.Charging
        ? (formatTime(device.timeToFull) !== "" ? formatTime(device.timeToFull) + " until full" : "")
        : (formatTime(device.timeToEmpty) !== "" ? formatTime(device.timeToEmpty) + " remaining" : "")

    implicitWidth: 190

    PopupHeader {
        text: "Battery"

        BarText {
            text: Math.round(popup.device.percentage * 100) + "%"
        }
    }

    // Read-only gauge in the same style as the volume slider track.
    Item {
        Layout.fillWidth: true
        implicitHeight: 14

        Bevel {
            anchors.fill: parent
            radius: height / 2
            sunken: true
            faceColor: Theme.field
        }

        Bevel {
            x: 1
            y: 1
            height: parent.height - 2
            width: Math.max(height, (parent.width - 2) * Math.min(1, popup.device.percentage))
            radius: height / 2
            shadow: false
            faceColor: popup.device.percentage <= 0.15 && UPower.onBattery ? Theme.warning : Theme.selection
        }
    }

    BarText {
        text: popup.status
    }

    BarText {
        visible: popup.remaining !== ""
        text: popup.remaining
        color: Theme.textDim
    }

    BarText {
        visible: popup.device.changeRate > 0
        text: popup.device.changeRate.toFixed(1) + " W"
        color: Theme.textDim
    }

    Separator {
        vertical: false
    }

    BarText {
        text: "Power profile"
        color: Theme.textDim
    }

    BarButton {
        Layout.fillWidth: true
        implicitHeight: 26
        text: "Power Save"
        active: PowerProfiles.profile === PowerProfile.PowerSaver
        onClicked: PowerProfiles.profile = PowerProfile.PowerSaver
    }

    BarButton {
        Layout.fillWidth: true
        implicitHeight: 26
        text: "Balanced"
        active: PowerProfiles.profile === PowerProfile.Balanced
        onClicked: PowerProfiles.profile = PowerProfile.Balanced
    }

    BarButton {
        Layout.fillWidth: true
        implicitHeight: 26
        text: "Performance"
        active: PowerProfiles.profile === PowerProfile.Performance
        enabled: PowerProfiles.hasPerformanceProfile
        onClicked: PowerProfiles.profile = PowerProfile.Performance
    }
}
