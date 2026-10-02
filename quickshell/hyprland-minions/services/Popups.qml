pragma Singleton

import Quickshell
import QtQuick

// Tracks the one bar popup that is currently open (across all screens), so
// opening a popup closes whichever one was open before.
Singleton {
    id: root

    property var current: null

    // Emitted by the `startmenu` IPC target; the bar on the named screen
    // toggles its start menu.
    signal startMenuRequested(string screenName)

    function open(popup) {
        root.current = popup
    }

    function close() {
        root.current = null
    }

    function toggle(popup) {
        root.current = root.current === popup ? null : popup
    }
}
