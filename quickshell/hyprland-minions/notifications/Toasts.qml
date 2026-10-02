import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import Quickshell.Wayland
import qs.services

// Pop-up notifications stacked in the bottom-right corner of the focused
// screen, just above the bar. Each one hides itself after its timeout (it
// stays in the notification centre); hovering pauses the timer, critical
// ones stay until closed.
PanelWindow {
    id: root

    screen: [...Quickshell.screens].find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    visible: Notifs.toasts.length > 0

    anchors {
        bottom: true
        right: true
    }
    margins {
        bottom: 6
        right: 6
    }
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "plasticbar-toasts"

    implicitWidth: 320
    implicitHeight: column.implicitHeight

    ColumnLayout {
        id: column

        width: parent.width
        spacing: 6

        Repeater {
            model: ScriptModel {
                values: Notifs.toasts
            }

            delegate: NotifCard {
                id: card

                Layout.fillWidth: true
                highlight: true

                Timer {
                    running: !card.critical && !card.hovered
                    interval: (card.modelData?.expireTimeout ?? 0) > 0 ? card.modelData.expireTimeout * 1000 : 6000
                    onTriggered: Notifs.hideToast(card.modelData)
                }
            }
        }
    }
}
