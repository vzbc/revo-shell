import QtQuick
import Quickshell
import Quickshell.Hyprland

// Window buttons for the workspace shown on this screen. Scroll to pan when
// there are more windows than fit.
Item {
    id: root

    required property ShellScreen screen

    readonly property var monitor: Hyprland.monitorFor(screen)

    ListView {
        id: list

        anchors.fill: parent
        orientation: ListView.Horizontal
        clip: true
        interactive: false
        spacing: 4
        boundsBehavior: Flickable.StopAtBounds

        model: root.monitor?.activeWorkspace?.toplevels ?? null

        delegate: TaskButton {
            width: Math.max(80, Math.min(200, (list.width + list.spacing) / Math.max(list.count, 1) - list.spacing))
            height: list.height
        }

        WheelHandler {
            onWheel: event => {
                const max = Math.max(0, list.contentWidth - list.width)
                list.contentX = Math.min(max, Math.max(0, list.contentX - event.angleDelta.y))
            }
        }
    }
}
