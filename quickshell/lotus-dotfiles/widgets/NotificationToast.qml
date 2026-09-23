import QtQuick
import Quickshell.Services.Notifications

Item {
    id: root

    required property QtObject theme
    required property QtObject notificationService
    required property var entry
    readonly property bool persistent: entry.urgency === NotificationUrgency.Critical || entry.expireTimeout === 0
    readonly property int requestedDuration: entry.expireTimeout > 0 ? entry.expireTimeout : (entry.urgency === NotificationUrgency.Low ? 3000 : 5000)

    implicitWidth: theme.notificationToastWidth
    implicitHeight: card.implicitHeight

    NotificationCard {
        id: card

        anchors.fill: parent
        theme: root.theme
        notificationService: root.notificationService
        entry: root.entry
        compact: true
    }

    Timer {
        interval: root.requestedDuration
        repeat: false
        running: !root.persistent
        onTriggered: root.notificationService.removeToast(root.entry.key, true)
    }

}
