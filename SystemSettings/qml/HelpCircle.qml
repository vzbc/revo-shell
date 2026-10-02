import QtQuick

Item {
    id: help

    signal clicked

    width: 20
    height: 20

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: helpArea.containsMouse ? Theme.glyphBgHover : Theme.glyphBg
        border.width: 1
        border.color: Qt.rgba(0, 0, 0, 0.04)
    }

    Text {
        anchors.centerIn: parent
        text: "?"
        font.pixelSize: 12
        font.bold: true
        color: Theme.glyphFg
        anchors.verticalCenterOffset: -0.5
    }

    MouseArea {
        id: helpArea
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: help.clicked()
    }
}
