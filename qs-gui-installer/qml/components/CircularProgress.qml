// CircularProgress.qml - Animated circular progress (Magic UI AnimatedCircularProgressBar → QML)
import QtQuick

Item {
    id: root

    property real value: 0
    property real maxValue: 100
    property color gaugePrimaryColor: "#4F46E5"
    property color gaugeSecondaryColor: "#1A1A1A"
    property color trackColor: Qt.rgba(0, 0, 0, 0.1)
    property color labelColor: "#FFFFFF"
    property int size: 180
    property int stroke: 14
    property string centerText: Math.round(displayValue) + "%"
    property bool animate: true

    property real displayValue: 0

    readonly property real normalized: Math.max(0, Math.min(value, maxValue)) / maxValue

    implicitWidth: size
    implicitHeight: size

    onValueChanged: applyValue()

    function applyValue() {
        if (animate) {
            valueAnim.to = normalized * 360
            valueAnim.restart()
        } else {
            displayValue = Math.max(0, Math.min(value, maxValue))
        }
    }

    Component.onCompleted: applyValue()

    onNormalizedChanged: {
        if (!animate)
            displayValue = Math.max(0, Math.min(value, maxValue))
    }

    NumberAnimation {
        id: valueAnim
        target: root
        property: "displayValue"
        duration: 700
        easing.type: Easing.OutCubic
    }

    Canvas {
        id: bgRing
        anchors.fill: parent
        antialiasing: true

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            var c = width / 2
            var r = c - root.stroke / 2 - 1
            ctx.beginPath()
            ctx.arc(c, c, r, 0, Math.PI * 2)
            ctx.lineWidth = root.stroke
            ctx.strokeStyle = Qt.rgba(root.trackColor.r, root.trackColor.g, root.trackColor.b, root.trackColor.a)
            ctx.stroke()
        }

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
    }

    Canvas {
        id: fgRing
        anchors.fill: parent
        antialiasing: true

        property real progress: 0

        onProgressChanged: requestPaint()
        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()
            var c = width / 2
            var r = c - root.stroke / 2 - 1
            if (progress <= 0.001)
                return
            ctx.beginPath()
            ctx.arc(c, c, r, -Math.PI / 2, -Math.PI / 2 + (progress / root.maxValue) * Math.PI * 2, false)
            ctx.lineWidth = root.stroke
            ctx.lineCap = "round"
            ctx.strokeStyle = root.gaugePrimaryColor
            ctx.stroke()
        }

        Connections {
            target: root
            function onDisplayValueChanged() {
                fgRing.progress = root.displayValue
            }
        }
    }

    // Glow
    Rectangle {
        anchors.centerIn: parent
        width: size * 0.7
        height: width
        radius: width / 2
        color: Qt.rgba(root.gaugePrimaryColor.r, root.gaugePrimaryColor.g, root.gaugePrimaryColor.b, 0.08)
        visible: root.displayValue > 0
    }

    Text {
        anchors.centerIn: parent
        text: root.centerText
        font.family: "SF Pro Display"
        font.pixelSize: size * 0.22
        font.bold: true
        color: root.labelColor
    }
}
