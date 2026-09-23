import QtQuick
import "../../"
import "../bar"
import "../shared"

BarButton {
    id: root
    readonly property bool available: WifiService.showInBar
    icon: WifiService.barIcon()
    active: popup.visible
    visible: available
    onClicked: popup.visible ? popup.close() : popup.open()

    AnimatedPopup {
        id: popup
        anchorItem: root
        implicitWidth: Math.round(320 * UIScale.value)
        implicitHeight: Math.round(440 * UIScale.value)
        content: Component {
            Wifi {}
        }
    }
}
