import QtQuick
import "../../"
import "../bar"
import "../shared"

BarButton {
    id: root
    icon: "󰔯"
    active: popup.visible
    onClicked: popup.visible ? popup.close() : popup.open()

    AnimatedPopup {
        id: popup
        anchorItem: root
        implicitWidth: 380
        implicitHeight: 520
        hasBackground: false
        content: Component {
            ThemeSwitcher {}
        }
    }
}
