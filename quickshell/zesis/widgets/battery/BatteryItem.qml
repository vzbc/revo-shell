import QtQuick
import "../../"
import "../bar"
import "../shared"

BarButton {
    id: root
    readonly property bool available: BatteryService.available
    icon: BatteryService.icon
    active: popup.visible
    visible: available
    onClicked: popup.visible ? popup.close() : popup.open()

    AnimatedPopup {
        id: popup
        anchorItem: root
        implicitWidth: Math.round(280 * UIScale.value)
        implicitHeight: Math.round(300 * UIScale.value)
        content: Component {
            Battery {}
        }
    }
}
