import "../widgets" as Widgets
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

PanelWindow {
    id: win

    required property QtObject theme
    required property QtObject clipboardController
    required property QtObject clipboardService
    readonly property string screenKey: screen !== null ? screen.name : "default"

    implicitWidth: clipboardManager.implicitWidth
    implicitHeight: clipboardManager.implicitHeight
    color: "transparent"
    focusable: true
    visible: clipboardController.isOpen(screenKey)
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "lotus-clipboard"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    Component.onDestruction: {
        if (clipboardController.isOpen(screenKey))
            clipboardController.close();

    }
    onVisibleChanged: {
        if (visible) {
            focusTimer.restart();
        } else {
            focusTimer.stop();
            clipboardManager.resetTransientState();
        }
    }

    Timer {
        id: focusTimer

        interval: 60
        repeat: false
        onTriggered: clipboardManager.open()
    }

    anchors {
        top: true
        left: true
    }

    margins {
        top: theme.clipboardTopMargin
        left: Math.max(theme.islandMargin, Math.round((win.screen.width - win.implicitWidth) / 2))
    }

    Widgets.ClipboardManager {
        id: clipboardManager

        anchors.fill: parent
        theme: win.theme
        clipboardService: win.clipboardService
        active: win.visible
        onCloseRequested: win.clipboardController.close()
    }

    HyprlandFocusGrab {
        active: win.visible
        windows: [win]
        onCleared: win.clipboardController.close()
    }

}
