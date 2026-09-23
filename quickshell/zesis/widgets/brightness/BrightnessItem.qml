import QtQuick
import "../../"
import "../bar"
import "../shared"

BarButton {
    id: root
    readonly property bool available: BrightnessService.available
    icon: {
        var p = BrightnessService.percent;
        if (p >= 80)
            return "󰃠";
        if (p >= 40)
            return "󰃟";
        return "󰃞";
    }
    active: popup.visible
    visible: available
    onClicked: popup.visible ? popup.close() : popup.open()

    WheelHandler {
        onWheel: function (w) {
            BrightnessService.adjust(w.angleDelta.y > 0 ? 5 : -5);
        }
    }

    AnimatedPopup {
        id: popup
        anchorItem: root
        implicitWidth: Math.round(280 * UIScale.value)
        implicitHeight: Math.round(200 * UIScale.value)
        content: Component {
            Brightness {}
        }
    }
}
