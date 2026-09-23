pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: root

    WlSessionLock {
        id: sessionLock

        LockSurface {
            lock: sessionLock
        }
    }

    function triggerLock() {
        lockTimer.start();
    }

    IpcHandler {
        target: "lockscreen"

        function lock() {
            lockTimer.start();
        }

        function unlock() {
            sessionLock.locked = false;
        }
    }

    // Small delay so any ongoing animations can finish before the compositor grabs focus
    Timer {
        id: lockTimer
        interval: 50
        onTriggered: sessionLock.locked = true
    }
}
