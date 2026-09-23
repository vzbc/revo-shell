import QtQuick
import qs.modules.win

/**
 * Windows 11 style horizontal progress bar.
 */
Rectangle {
    id: root

    property real value: 0            // 0..1
    property color barColor: WinTheme.accent

    implicitWidth: 200
    implicitHeight: 6
    radius: 3
    color: "#3a3a3a"

    Rectangle {
        width: parent.width * Math.min(1, Math.max(0, root.value))
        height: parent.height
        radius: parent.radius
        color: root.barColor
        Behavior on width {
            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
        }
    }
}
