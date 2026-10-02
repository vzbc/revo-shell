import QtQuick

Item {
    id: info

    signal clicked

    width: 17
    height: 17

    Canvas {
        id: cv
        anchors.fill: parent

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            ctx.strokeStyle = Theme.dotStroke
            ctx.lineWidth = 1.2
            ctx.beginPath()
            ctx.arc(8.5, 8.5, 7.2, 0, Math.PI * 2)
            ctx.stroke()
            // dot
            ctx.fillStyle = Theme.dotFg
            ctx.beginPath()
            ctx.arc(8.5, 5.4, 1.1, 0, Math.PI * 2)
            ctx.fill()
            // stem
            ctx.strokeStyle = Theme.dotFg
            ctx.lineWidth = 1.6
            ctx.lineCap = "round"
            ctx.beginPath()
            ctx.moveTo(8.5, 7.8)
            ctx.lineTo(8.5, 11.8)
            ctx.stroke()
        }

        Component.onCompleted: requestPaint()
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: info.clicked()
    }
}
