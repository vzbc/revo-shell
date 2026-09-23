import QtQuick
import QtQuick.Controls
import qs.modules.common.widgets
import qs.modules.win

/**
 * Windows 11 style title bar icon button (minimize / close etc).
 */
Rectangle {
    id: root

    property string iconText: ""
    property bool close: false
    signal clicked()

    implicitWidth: 46
    implicitHeight: 36
    color: mouse.containsMouse ? (root.close ? "#e81123" : "#3a3a3a") : "transparent"
    radius: 4

    Behavior on color {
        ColorAnimation { duration: 100 }
    }

    MaterialSymbol {
        anchors.centerIn: parent
        text: root.iconText
        iconSize: 16
        color: mouse.containsMouse && root.close ? "#ffffff" : WinTheme.text
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
