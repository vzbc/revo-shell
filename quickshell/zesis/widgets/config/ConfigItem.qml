import QtQuick
import "../../"
import "../bar"
import "../shared"

BarButton {
    id: root
    icon: "󰒓"
    active: popup.visible
    onClicked: popup.visible ? popup.close() : popup.open()

    AnimatedPopup {
        id: popup
        anchorItem: root
        implicitWidth: Math.round(280 * UIScale.value)
        implicitHeight: Math.round(500 * UIScale.value)
        hasBackground: false
        content: Component {
            Config {}
        }
    }
}
