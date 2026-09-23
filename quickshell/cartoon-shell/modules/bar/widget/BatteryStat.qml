import QtQuick
import QtQuick.Layouts
import qs.components
import qs.commons
import qs.services
import Quickshell.Services.UPower

RowLayout {
    id: root
    property int style: Settings.bar.battery.style
    property int percent: Math.round(UPower.displayDevice.percentage * 100)
    property bool batteryCharging: false
    function getBatteryIcon() {
        if (batteryCharging)
            return "battery/charge.png";
        if (root.percent <= 30)
            return "battery/battery-1.png";
        if (root.percent <= 60)
            return "battery/battery-2.png";
        if (root.percent <= 90)
            return "battery/battery-3.png";
        return "battery/full.png";
    }
    spacing: ScalerService.s(2)

    IconImage {
        path: root.getBatteryIcon()
    }
    CustomText {
        visible: !isVertical
        name: `${root.percent}%`
        size: "small"
    }
}
