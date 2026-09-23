pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root
    signal lockRequested
    function triggerLock() {
        root.lockRequested();
    }
}
