pragma Singleton

import QtQuick
import Quickshell

// Stub for eqsh's NotificationDaemon.
// eqsh's version owns a NotificationServer, which would collide with
// macos/services/Notifications.qml (two servers in one process).
// Only the DND surface is needed by the ported Control Center.
Singleton {
    id: root

    property bool popupInhibited: false

    function toggleDND() {
        root.popupInhibited = !root.popupInhibited;
    }
}
