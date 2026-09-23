import "../widgets" as Widgets
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: win

    required property QtObject theme
    required property QtObject mediaService

    implicitWidth: status.implicitWidth
    implicitHeight: status.implicitHeight
    color: "transparent"
    focusable: true
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "lotus-top-center"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    anchors {
        top: true
    }

    margins {
        top: theme.islandMargin
    }

    Widgets.MediaIsland {
        id: status

        anchors.fill: parent
        theme: win.theme
        mediaService: win.mediaService
    }

}
