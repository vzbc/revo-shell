import QtQuick
import Quickshell
import qs.config
import qs.ui.components.lockscreen
import "./services"
import "./modules/topbar"
import "./modules/spotlight"
import "./modules/dock"
import "./modules/about"
import "./modules/notification"
import "./modules/session"
import "./modules/controlcenter"
import "./modules/desktop"
import "./modules/settings"
import "./modules/launcher"

ShellRoot {
    id: root

    TopBar { id: topBar }
    Spotlight {}
    Launcher {}
    Dock {}
    AboutWindow { parentWindow: topBar }
    NotificationPopup {}
    Session {}
    ConfirmDialog {}
    ForceQuit {}
    ControlCenter {}
    Settings {}

    // eqsh LockScreen (ext-session-lock) replaces the old PanelWindow lock
    Loader {
        id: lockLoader
        active: Config.lockScreen.enable
        sourceComponent: Lock {
            id: lockScreen
            onLock: ShellController.lock()
            onUnlocking: if (!Config.notch.delayedLockAnim) ShellController.unlock()
            onUnlock: ShellController.unlock()
            Component.onCompleted: Runtime.subscribe("lockscreen", () => lockScreen.lockScreen())
        }
    }

    Connections {
        target: ShellController
        function onLockedChanged() {
            if (ShellController.locked) {
                if (!Runtime.locked) Runtime.locked = true;
                Runtime.run("lockscreen");
            } else {
                if (Runtime.locked) Runtime.locked = false;
            }
        }
    }

    // eqsh Spotlight reads Runtime.spotlightOpen; macos uses ShellController.spotlightOpen
    Connections {
        target: Runtime
        function onSpotlightOpenChanged() {
            if (ShellController.spotlightOpen !== Runtime.spotlightOpen)
                ShellController.spotlightOpen = Runtime.spotlightOpen;
        }
    }
    Connections {
        target: ShellController
        function onSpotlightOpenChanged() {
            if (Runtime.spotlightOpen !== ShellController.spotlightOpen)
                Runtime.spotlightOpen = ShellController.spotlightOpen;
        }
    }

    Component.onCompleted: { void Apps.ready; }
}
