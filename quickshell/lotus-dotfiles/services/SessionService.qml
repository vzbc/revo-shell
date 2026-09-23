import QtQuick
import Quickshell

QtObject {
    function runAction(action) {
        switch (action) {
        case "lock":
            Quickshell.execDetached(["hyprlock"]);
            break;
        case "suspend":
            Quickshell.execDetached(["systemctl", "suspend"]);
            break;
        case "logout":
            Quickshell.execDetached(["hyprctl", "dispatch", "exit"]);
            break;
        case "restart":
            Quickshell.execDetached(["systemctl", "reboot"]);
            break;
        case "poweroff":
            Quickshell.execDetached(["systemctl", "poweroff"]);
            break;
        }
    }

}
