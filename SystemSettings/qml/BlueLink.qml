import QtQuick

Text {
    id: link

    property string label: ""
    signal clicked

    text: label
    font.family: "SF Pro Text"
    font.pixelSize: 13
    color: Theme.link

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onContainsMouseChanged: link.font.underline = containsMouse
        onClicked: link.clicked()
    }
}
