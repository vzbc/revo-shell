import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.components

// Pager with one button per Hyprland workspace on this screen. Click to
// switch, scroll to cycle.
RowLayout {
    id: root

    required property ShellScreen screen

    readonly property var workspaces: [...Hyprland.workspaces.values]
        .filter(w => w.id > 0 && w.monitor?.name === root.screen.name)
        .sort((a, b) => a.id - b.id)

    function cycle(step) {
        const current = workspaces.findIndex(w => w.active)
        const next = workspaces[(current + step + workspaces.length) % workspaces.length]
        next?.activate()
    }

    spacing: 3

    Repeater {
        model: ScriptModel {
            values: root.workspaces
        }

        delegate: BarButton {
            required property var modelData

            Layout.fillHeight: true
            Layout.preferredWidth: Math.max(22, implicitWidth)
            text: modelData.name
            active: modelData.active
            tooltip: "Workspace " + modelData.name + " (" + modelData.toplevels.values.length + " windows)"
            onClicked: modelData.activate()
            onScrolled: wheel => root.cycle(wheel.angleDelta.y > 0 ? -1 : 1)
        }
    }
}
