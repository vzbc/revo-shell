pragma Singleton

import Quickshell
import Quickshell.Services.Notifications
import QtQuick

// Notification daemon. Every notification is kept in `list` until dismissed
// (the notification centre); new ones are also shown briefly as toasts
// unless do-not-disturb is on.
Singleton {
    id: root

    readonly property var list: server.trackedNotifications
    readonly property int count: server.trackedNotifications.values.length

    // Notifications currently shown as toasts, oldest first.
    property var toasts: []
    property bool dnd: false

    function hideToast(notification) {
        root.toasts = root.toasts.filter(n => n !== notification)
    }

    function clear() {
        [...server.trackedNotifications.values].forEach(n => n.dismiss())
    }

    // Runs the "default" action if the app provided one (usually focuses it).
    function activate(notification) {
        const action = [...notification.actions].find(a => a.identifier === "default")
        if (action) action.invoke()
    }

    NotificationServer {
        id: server

        keepOnReload: true
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        actionsSupported: true

        onNotification: notification => {
            notification.tracked = true
            notification.closed.connect(() => root.hideToast(notification))
            if (!root.dnd)
                root.toasts = [...root.toasts, notification]
        }
    }
}
