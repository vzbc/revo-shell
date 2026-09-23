import "../widgets" as Widgets
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

PanelWindow {
    id: win

    required property QtObject theme
    required property QtObject launcherService
    required property QtObject launcherController
    readonly property string screenKey: screen !== null ? screen.name : "default"

    implicitWidth: launcher.implicitWidth
    implicitHeight: launcher.implicitHeight
    color: "transparent"
    focusable: true
    visible: launcherController.isOpen(screenKey)
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "lotus-application-launcher"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    Component.onDestruction: {
        if (launcherController.isOpen(screenKey))
            launcherController.close();

    }
    onVisibleChanged: {
        if (visible)
            focusTimer.restart();
        else
            focusTimer.stop();
    }

    Timer {
        id: focusTimer

        interval: 60
        repeat: false
        onTriggered: launcher.open()
    }

    anchors {
        top: true
        left: true
    }

    margins {
        top: theme.launcherTopMargin
        left: Math.max(theme.islandMargin, Math.round((win.screen.width - win.implicitWidth) / 2))
    }

    Widgets.ApplicationLauncher {
        id: launcher

        anchors.fill: parent
        theme: win.theme
        launcherService: win.launcherService
        active: win.visible
        onCloseRequested: win.launcherController.close()
    }

    HyprlandFocusGrab {
        active: win.visible
        windows: [win]
        onCleared: win.launcherController.close()
    }

}
