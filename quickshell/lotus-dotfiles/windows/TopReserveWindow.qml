import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: win

    required property QtObject theme

    implicitHeight: 1
    color: "transparent"
    focusable: false
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: theme.topReservedHeight
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "lotus-top-reserve"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors {
        top: true
        left: true
        right: true
    }

    mask: Region {
    }

}
