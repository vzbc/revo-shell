import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray
import qs.components
import qs.config

// Inset pill holding the StatusNotifier tray icons.
Item {
    id: root

    visible: SystemTray.items.values.length > 0
    implicitWidth: row.implicitWidth + 12

    Bevel {
        anchors.fill: parent
        sunken: true
        radius: height / 2
        faceColor: Qt.tint(Theme.bar, Qt.rgba(Theme.bevelShadow.r, Theme.bevelShadow.g, Theme.bevelShadow.b, 0.12))
    }

    RowLayout {
        id: row

        anchors.centerIn: parent
        spacing: 2

        Repeater {
            model: SystemTray.items

            delegate: TrayItem {}
        }
    }
}
