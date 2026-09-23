import "../widgets" as Widgets
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

PanelWindow {
    id: win

    required property QtObject theme
    required property QtObject dashboardController
    required property QtObject systemStats
    required property QtObject systemHealth
    readonly property string screenKey: screen !== null ? screen.name : "default"

    implicitWidth: dashboard.implicitWidth
    implicitHeight: dashboard.implicitHeight
    color: "transparent"
    focusable: true
    visible: dashboardController.isOpen(screenKey)
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "lotus-control-dashboard"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    Component.onDestruction: {
        if (dashboardController.isOpen(screenKey))
            dashboardController.close();

    }
    onVisibleChanged: {
        if (visible) {
            focusTimer.restart();
        } else {
            focusTimer.stop();
            dashboard.resetTransientState();
        }
    }

    Timer {
        id: focusTimer

        interval: 60
        repeat: false
        onTriggered: dashboard.open()
    }

    anchors {
        top: true
        left: true
    }

    margins {
        top: theme.dashboardTopMargin
        left: Math.max(theme.islandMargin, Math.round((win.screen.width - win.implicitWidth) / 2))
    }

    Widgets.ControlDashboard {
        id: dashboard

        anchors.fill: parent
        theme: win.theme
        systemStats: win.systemStats
        systemHealth: win.systemHealth
        onCloseRequested: win.dashboardController.close()
    }

    HyprlandFocusGrab {
        active: win.visible
        windows: [win]
        onCleared: win.dashboardController.close()
    }

}
