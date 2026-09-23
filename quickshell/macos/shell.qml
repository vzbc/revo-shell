import QtQuick
import Quickshell
import "./services"
import "./modules/topbar"
import "./modules/spotlight"
import "./modules/dock"
import "./modules/about"
import "./modules/notification"
import "./modules/lock"
import "./modules/session"
import "./modules/controlcenter"
import "./modules/desktop"

ShellRoot {
    id: root

    TopBar { id: topBar }
    Spotlight {}
    Dock {}
    AboutWindow { parentWindow: topBar }
    NotificationPopup {}
    LockScreen {}
    Session {}
    ConfirmDialog {}
    ForceQuit {}
    ControlCenter {}

    Component.onCompleted: { void Apps.ready; }
}
