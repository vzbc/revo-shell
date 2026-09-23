pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    // Which TaskbarItem instance currently owns the popup. Null = none.
    // Keyed by instance.
    property var activeItem: null

    Timer {
        id: closeTimer
        interval: 350
        onTriggered: root.activeItem = null
    }

    function hover(item) {
        activeItem = item;
        closeTimer.stop();
    }

    function leave() {
        closeTimer.restart();
    }
}
