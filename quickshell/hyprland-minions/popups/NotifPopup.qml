import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components
import qs.config
import qs.notifications
import qs.services

// Notification centre, newest first.
BarPopup {
    id: popup

    implicitWidth: 330
    implicitHeight: 380
    padding: 6

    PopupHeader {
        text: "Notifications"

        BarButton {
            implicitHeight: 24
            text: "DND"
            active: Notifs.dnd
            tooltip: "Do not disturb"
            onClicked: Notifs.dnd = !Notifs.dnd
        }

        BarButton {
            implicitHeight: 24
            text: "Clear"
            enabled: Notifs.count > 0
            onClicked: Notifs.clear()
        }
    }

    // Inset well the list sits in.
    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        Bevel {
            anchors.fill: parent
            sunken: true
            faceColor: Theme.field
        }

        ListView {
            anchors.fill: parent
            anchors.margins: 6
            clip: true
            spacing: 6
            boundsBehavior: Flickable.StopAtBounds

            model: ScriptModel {
                values: [...Notifs.list.values].reverse()
            }

            delegate: NotifCard {
                width: ListView.view.width
            }
        }

        BarText {
            anchors.centerIn: parent
            visible: Notifs.count === 0
            text: "No new notifications"
            color: Theme.textMuted
        }
    }
}
