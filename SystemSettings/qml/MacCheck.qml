import QtQuick

Item {
    id: box

    property bool checked: false
    signal toggled

    width: 15
    height: 15

    Rectangle {
        anchors.fill: parent
        radius: 4
        color: box.checked ? Theme.accent : Theme.checkBg
        border.width: 1
        border.color: box.checked ? Qt.rgba(0, 0, 0, 0.04) : Theme.checkBorder

        Behavior on color {
            ColorAnimation { duration: 100 }
        }
    }

    Text {
        visible: box.checked
        anchors.centerIn: parent
        text: "✓"
        color: "white"
        font.pixelSize: 11
        font.bold: true
        anchors.verticalCenterOffset: -1
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            box.checked = !box.checked
            box.toggled()
        }
    }
}
