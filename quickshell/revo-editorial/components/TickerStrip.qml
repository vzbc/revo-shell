pragma ComponentBehavior: Bound

// TickerStrip — horizontal marquee (Motion Frames loop)
import QtQuick

Item {
    id: strip

    property string text: "SMOOTH LOOPS · ROTATING RINGS · TICKING FRAMES · "
    property color fg: "#0E0E0C"
    property color bg: "transparent"
    property int speedMs: 12000
    property int pixelSize: 11

    clip: true
    height: Math.max(20, label1.implicitHeight + 8)

    Rectangle {
        anchors.fill: parent
        color: strip.bg
    }

    // two copies for seamless wrap
    Row {
        id: track
        height: parent.height
        spacing: 40
        anchors.verticalCenter: parent.verticalCenter

        Text {
            id: label1
            text: strip.text
            color: strip.fg
            font.pixelSize: strip.pixelSize
            font.letterSpacing: 2
            font.bold: true
            verticalAlignment: Text.AlignVCenter
            textFormat: Text.PlainText
        }
        Text {
            text: strip.text
            color: strip.fg
            font.pixelSize: strip.pixelSize
            font.letterSpacing: 2
            font.bold: true
            verticalAlignment: Text.AlignVCenter
            textFormat: Text.PlainText
        }
    }

    NumberAnimation on x {
        running: true
        loops: Animation.Infinite
        from: 0
        to: -(label1.implicitWidth + 40)
        duration: strip.speedMs
        easing.type: Easing.Linear
    }
}
