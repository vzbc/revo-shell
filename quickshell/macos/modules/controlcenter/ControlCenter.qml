import QtQuick
import Quickshell
import "../../services"
import "eqsh" as EqCC

// Wrapper hosting eqsh's Control Center, bridged to ShellController state.
Scope {
    id: host

    EqCC.ControlCenter {
        id: cc
        screen: Quickshell.screens[0]
    }

    Connections {
        target: ShellController
        function onControlCenterOpenChanged() {
            if (ShellController.controlCenterOpen) cc.openCC();
            else cc.closeCC();
        }
    }

    Connections {
        target: cc
        function onOpenedChanged() {
            if (ShellController.controlCenterOpen !== cc.opened)
                ShellController.controlCenterOpen = cc.opened;
        }
    }
}
