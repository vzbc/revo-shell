import "../widgets" as Widgets
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: win

    required property QtObject theme
    required property QtObject launcherService
    required property QtObject launcherController
    required property QtObject workspaceService
    required property QtObject dashboardController
    required property QtObject clipboardController
    required property QtObject clipboardService
    required property QtObject notificationController
    required property QtObject panelController
    required property QtObject trayService
    required property QtObject trayController

    implicitWidth: status.implicitWidth
    implicitHeight: status.implicitHeight
    color: "transparent"
    focusable: true
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "lotus-top-left"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    anchors {
        top: true
        left: true
    }

    margins {
        top: theme.islandMargin
        left: theme.islandMargin
    }

    Widgets.TopLeftStatus {
        id: status

        anchors.fill: parent
        theme: win.theme
        screen: win.screen
        launcherService: win.launcherService
        launcherController: win.launcherController
        workspaceService: win.workspaceService
        dashboardController: win.dashboardController
        clipboardController: win.clipboardController
        clipboardService: win.clipboardService
        notificationController: win.notificationController
        panelController: win.panelController
        trayService: win.trayService
        trayController: win.trayController
        trayParentWindow: win
    }

}
