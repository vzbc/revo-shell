// ScrollVelocityText.qml — dual-row horizontal scroll marquee (thank-you)
// Style: magicui ScrollBasedVelocity
import QtQuick

Item {
    id: root

    property string text: "Thank You"
    property int pixelSize: 72
    property color color: "#FFFFFF"
    property string fontFamily: "SF Pro Display"
    property real baseVelocity: 40
    property int row1Direction: 1
    property int row2Direction: -1
    property bool running: true
    property real rowOpacity1: 0.9
    property real rowOpacity2: 0.35

    clip: true
    implicitWidth: 600
    implicitHeight: pixelSize * 2.4

    readonly property string repeated: {
        var unit = text + "   •   "
        var s = ""
        for (var i = 0; i < 8; i++)
            s += unit
        return s
    }

    Row {
        id: row1
        y: 0
        height: parent.height / 2
        spacing: 0

        Repeater {
            model: 2
            Text {
                text: root.repeated
                font.family: root.fontFamily
                font.pixelSize: root.pixelSize
                font.weight: Font.Bold
                color: root.color
                opacity: root.rowOpacity1
                font.letterSpacing: -1
            }
        }

        XAnimator on x {
            running: root.running && root.visible
            from: 0
            to: -root.pixelSize * 12
            duration: Math.max(400, Math.round(1000 * (root.pixelSize * 12) / Math.max(1, root.baseVelocity)))
            loops: Animation.Infinite
        }
    }

    Row {
        id: row2
        y: parent.height / 2
        height: parent.height / 2
        spacing: 0

        Repeater {
            model: 2
            Text {
                text: root.repeated
                font.family: root.fontFamily
                font.pixelSize: root.pixelSize
                font.weight: Font.Bold
                color: root.color
                opacity: root.rowOpacity2
                font.letterSpacing: -1
            }
        }

        XAnimator on x {
            running: root.running && root.visible
            from: -root.pixelSize * 12
            to: 0
            duration: Math.max(400, Math.round(1000 * (root.pixelSize * 12) / Math.max(1, root.baseVelocity)))
            loops: Animation.Infinite
        }
    }

    Rectangle {
        anchors.left: parent.left
        width: parent.width * 0.18
        height: parent.height
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "#FF000000" }
            GradientStop { position: 1.0; color: "#00000000" }
        }
        z: 5
    }

    Rectangle {
        anchors.right: parent.right
        width: parent.width * 0.18
        height: parent.height
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "#00000000" }
            GradientStop { position: 1.0; color: "#FF000000" }
        }
        z: 5
    }
}
