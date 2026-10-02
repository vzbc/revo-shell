import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.config

// One taskbar per screen:
// [Start][workspaces] | [windows ..........] | [tray] [VOL][BAT][Notif][clock]
PanelWindow {
    id: bar

    required property ShellScreen modelData

    screen: modelData
    anchors {
        bottom: true
        left: true
        right: true
    }
    implicitHeight: Theme.barHeight
    exclusiveZone: implicitHeight
    color: "transparent"
    WlrLayershell.namespace: "plasticbar"

    // The bar is one big slab of plastic floating just above the screen edge.
    Bevel {
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 4
        anchors.topMargin: 1
        anchors.bottomMargin: 4
        radius: Theme.radiusLarge
        faceColor: Theme.bar
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 9
        anchors.rightMargin: 9
        anchors.topMargin: 5
        anchors.bottomMargin: 8
        spacing: 4

        StartButton {
            screen: bar.screen
            Layout.fillHeight: true
        }

        Workspaces {
            screen: bar.screen
            Layout.fillHeight: true
        }

        Separator {}

        Taskbar {
            screen: bar.screen
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        Separator {}

        SysTray {
            Layout.fillHeight: true
        }

        VolumeButton {
            Layout.fillHeight: true
        }

        BatteryButton {
            Layout.fillHeight: true
        }

        NotifButton {
            Layout.fillHeight: true
        }

        Clock {
            Layout.fillHeight: true
        }
    }
}
