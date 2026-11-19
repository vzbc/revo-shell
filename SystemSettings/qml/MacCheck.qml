import QtQuick

// macOS 27 checkbox: 16pt rounded square, accent fill + drawn checkmark.
Item {
    id: box

    property bool checked: false
    signal toggled

    width: 16
    height: 16

    Rectangle {
        anchors.fill: parent
        radius: 5
        color: box.checked ? Theme.accent : Theme.checkBg
        border.width: box.checked ? 0 : 1
        border.color: Theme.checkBorder

        Behavior on color {
            ColorAnimation { duration: 100 }
        }
    }

    Canvas {
        id: mark
        anchors.fill: parent
        visible: box.checked
        onVisibleChanged: requestPaint()
        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            ctx.strokeStyle = "white"
            ctx.lineWidth = 2
            ctx.lineCap = "round"
            ctx.lineJoin = "round"
            ctx.beginPath()
            ctx.moveTo(4.2, 8.4)
            ctx.lineTo(6.9, 11.1)
            ctx.lineTo(11.8, 5.2)
            ctx.stroke()
        }
        Component.onCompleted: requestPaint()
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -3
        onClicked: {
            box.checked = !box.checked
            box.toggled()
        }
    }
}
