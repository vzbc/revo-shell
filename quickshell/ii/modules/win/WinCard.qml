import QtQuick
import qs.modules.win

/**
 * Windows 11 style card container. Can be clickable (with hover state).
 */
Rectangle {
    id: root

    property bool clickable: false
    property bool hoverable: clickable
    property color cardColor: WinTheme.card
    signal clicked()

    color: {
        if (clickable && hoverArea.containsMouse)
            return WinTheme.cardHover
        return cardColor
    }
    radius: 8
    border.color: hoverArea.containsMouse ? WinTheme.border : "transparent"
    border.width: 1

    Behavior on color {
        ColorAnimation { duration: 120 }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        visible: root.hoverable
        hoverEnabled: true
        cursorShape: root.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
    }
}
