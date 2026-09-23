import "../widgets" as Widgets
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

PanelWindow {
    id: win

    required property QtObject theme
    required property QtObject trayService
    required property QtObject trayController
    readonly property string screenKey: screen !== null ? screen.name : "default"

    implicitWidth: overflow.implicitWidth
    implicitHeight: overflow.implicitHeight
    color: "transparent"
    focusable: true
    visible: trayController.isOpen(screenKey) && trayService.overflowItems(4).length > 0
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "lotus-tray-overflow"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    onVisibleChanged: {
        if (visible)
            Qt.callLater(overflow.forceActiveFocus);

    }

    anchors {
        top: true
        left: true
    }

    margins {
        top: theme.topReservedHeight + theme.space2
        left: theme.islandMargin
    }

    Widgets.TrayOverflow {
        id: overflow

        anchors.fill: parent
        theme: win.theme
        trayService: win.trayService
        parentWindow: win
        onCloseRequested: win.trayController.close()
    }

    HyprlandFocusGrab {
        active: win.visible
        windows: [win]
        onCleared: win.trayController.close()
    }

}
