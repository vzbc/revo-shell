import QtQuick
import QtQuick.Layouts
import qs.config

// Moulded groove (soft dark line + light line), vertical by default. Sized
// for use directly inside a Row/ColumnLayout.
Item {
    id: root

    property bool vertical: true

    Layout.fillHeight: vertical
    Layout.fillWidth: !vertical
    implicitWidth: vertical ? 6 : 2
    implicitHeight: vertical ? 2 : 6

    Rectangle {
        x: root.vertical ? root.width / 2 - 1 : 0
        y: root.vertical ? 3 : root.height / 2 - 1
        width: root.vertical ? 1 : root.width
        height: root.vertical ? root.height - 6 : 1
        radius: 0.5
        color: Qt.rgba(Theme.bevelShadow.r, Theme.bevelShadow.g, Theme.bevelShadow.b, 0.25)
    }

    Rectangle {
        x: root.vertical ? root.width / 2 : 0
        y: root.vertical ? 3 : root.height / 2
        width: root.vertical ? 1 : root.width
        height: root.vertical ? root.height - 6 : 1
        radius: 0.5
        color: Qt.rgba(Theme.bevelLight.r, Theme.bevelLight.g, Theme.bevelLight.b, 0.7)
    }
}
