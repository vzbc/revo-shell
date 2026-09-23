import QtQuick
import "../../"
import "../bar"
import "../shared"

BarButton {
    id: root
    icon: NotifServer.muted ? (NotifServer.history.count > 0 ? "󰂛" : "") : NotifServer.unreadCount > 0 ? "󱅫" : NotifServer.history.count > 0 ? "󰂚" : ""
    active: popup.visible
    onClicked: popup.visible ? popup.close() : popup.open()

    AnimatedPopup {
        id: popup
        anchorItem: root
        implicitWidth: Math.round(340 * UIScale.value)
        implicitHeight: Math.round(480 * UIScale.value)
        content: Component {
            NotifHistory {}
        }
        onOpened: NotifServer.markRead()
    }
}
