import QtQuick
import QtQuick.Controls
import qs.modules.win

/**
 * Windows 11 style toggle switch.
 */
Item {
    id: root

    property bool checked: false
    property bool enabled: true
    signal toggled(bool value)

    implicitWidth: 44
    implicitHeight: 22

    Rectangle {
        id: track
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? WinTheme.accent : "#3a3a3a"
        Behavior on color {
            ColorAnimation { duration: 150 }
        }

        Rectangle {
            id: knob
            width: 16
            height: 16
            radius: width / 2
            color: root.enabled ? WinTheme.text : WinTheme.textTertiary
            anchors.verticalCenter: parent.verticalCenter
            x: root.checked ? parent.width - width - 3 : 3
            Behavior on x {
                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.checked = !root.checked
            root.toggled(root.checked)
        }
    }
}
