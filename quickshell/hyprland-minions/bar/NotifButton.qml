import QtQuick
import qs.components
import qs.popups
import qs.services

// Click for the notification centre, middle click toggles do-not-disturb.
BarButton {
    id: root

    implicitWidth: 65
    active: popup.shown
    text: Notifs.dnd ? "DND" : Notifs.count > 0 ? "Notif " + Notifs.count : "Notif"
    tooltip: Notifs.dnd ? "Do not disturb (middle click to turn off)" : ""

    onClicked: mouse => {
        if (mouse.button === Qt.MiddleButton)
            Notifs.dnd = !Notifs.dnd
        else
            popup.toggle()
    }

    NotifPopup {
        id: popup
        anchorItem: root
        align: Qt.AlignRight
    }
}
