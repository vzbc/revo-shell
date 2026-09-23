import "../widgets" as Widgets
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

PanelWindow {
    id: win

    required property QtObject theme
    required property QtObject sessionMenuController
    required property QtObject sessionService
    readonly property string screenKey: screen !== null ? screen.name : "default"

    implicitWidth: sessionMenu.implicitWidth
    implicitHeight: sessionMenu.implicitHeight
    color: "transparent"
    focusable: true
    visible: sessionMenuController.isOpen(screenKey)
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "lotus-session-menu"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    Component.onDestruction: {
        if (sessionMenuController.isOpen(screenKey))
            sessionMenuController.close();

    }
    onVisibleChanged: {
        if (visible) {
            focusTimer.restart();
        } else {
            focusTimer.stop();
            sessionMenu.resetTransientState();
        }
    }

    Timer {
        id: focusTimer

        interval: 60
        repeat: false
        onTriggered: sessionMenu.open()
    }

    anchors {
        top: true
        left: true
    }

    margins {
        top: Math.max(win.theme.islandMargin, Math.round((win.screen.height - win.implicitHeight) / 2))
        left: Math.max(win.theme.islandMargin, Math.round((win.screen.width - win.implicitWidth) / 2))
    }

    Widgets.SessionMenu {
        id: sessionMenu

        anchors.fill: parent
        theme: win.theme
        sessionService: win.sessionService
        onCloseRequested: win.sessionMenuController.close()
    }

    HyprlandFocusGrab {
        active: win.visible
        windows: [win]
        onCleared: win.sessionMenuController.close()
    }

}
