import QtQuick

Rectangle {
    id: tile

    property string label: ""
    property color tileColor: "#9B9B9F"

    width: 24
    height: 24
    radius: 6
    color: tileColor

    Text {
        anchors.centerIn: parent
        text: tile.label.length > 0 ? tile.label.charAt(0).toUpperCase() : "?"
        font.family: "SF Pro Text"
        font.pixelSize: 12
        font.bold: true
        color: "white"
    }
}
