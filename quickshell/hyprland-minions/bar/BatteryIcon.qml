import QtQuick
import qs.config

// Little capsule battery gauge with a glossy fill.
Item {
    id: root

    property real level: 0 // 0..1
    property bool charging: false
    property color color: Theme.text

    implicitWidth: 22
    implicitHeight: 11

    Rectangle {
        width: parent.width - 2
        height: parent.height
        radius: 3.5
        color: Theme.field
        border.width: 1
        border.color: root.color

        Rectangle {
            x: 2
            y: 2
            height: parent.height - 4
            width: Math.round((parent.width - 4) * Math.min(1, Math.max(0, root.level)))
            radius: 2
            color: root.charging ? Theme.selection : root.level <= 0.15 ? Theme.warning : Theme.activeFace

            Rectangle {
                width: parent.width
                height: parent.height / 2
                radius: 2
                color: Qt.rgba(1, 1, 1, 0.45)
            }
        }
    }

    // Terminal nub
    Rectangle {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 2
        height: 5
        radius: 1
        color: root.color
    }
}
