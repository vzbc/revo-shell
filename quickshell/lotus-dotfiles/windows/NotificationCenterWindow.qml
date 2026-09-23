import "../widgets" as Widgets
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

PanelWindow {
    id: win

    required property QtObject theme
    required property QtObject notificationService
    required property QtObject notificationController
    readonly property string screenKey: screen !== null ? screen.name : "default"

    implicitWidth: center.implicitWidth
    implicitHeight: Math.min(center.implicitHeight, screen !== null ? screen.height - theme.topReservedHeight - theme.space6 : center.implicitHeight)
    color: "transparent"
    focusable: true
    visible: notificationController.isOpen(screenKey)
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "lotus-notification-center"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    Component.onDestruction: {
        if (notificationController.isOpen(screenKey))
            notificationController.close();

    }
    onVisibleChanged: {
        if (visible) {
            focusTimer.restart();
        } else {
            focusTimer.stop();
            center.resetTransientState();
        }
    }

    Timer {
        id: focusTimer

        interval: 60
        repeat: false
        onTriggered: center.open()
    }

    anchors {
        top: true
        right: true
    }

    margins {
        top: theme.topReservedHeight + theme.space2
        right: theme.islandMargin
    }

    Widgets.NotificationCenter {
        id: center

        anchors.fill: parent
        theme: win.theme
        notificationService: win.notificationService
        onCloseRequested: win.notificationController.close()
    }

    HyprlandFocusGrab {
        active: win.visible
        windows: [win]
        onCleared: win.notificationController.close()
    }

}
