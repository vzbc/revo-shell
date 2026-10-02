import QtQuick
import qs.config

// Inset pill track with a glossy candy fill and a round plastic knob.
// `value` is 0..1 and should be bound to the real value; drags and scrolls
// emit `moved` with the new value.
Item {
    id: root

    property real value: 0
    property real step: 0.05

    signal moved(real value)

    implicitWidth: 160
    implicitHeight: 18

    readonly property real clamped: Math.min(1, Math.max(0, value))
    readonly property real knob: height

    Bevel {
        anchors.fill: parent
        anchors.topMargin: 3
        anchors.bottomMargin: 3
        radius: height / 2
        sunken: true
        faceColor: Theme.field

        Bevel {
            x: 1
            y: 1
            height: parent.height - 2
            width: Math.max(height, (root.width - root.knob) * root.clamped + root.knob / 2)
            visible: root.clamped > 0
            radius: height / 2
            shadow: false
            faceColor: Theme.selection
        }
    }

    Bevel {
        width: root.knob
        height: root.knob
        x: (parent.width - width) * root.clamped
        radius: width / 2
        faceColor: area.containsMouse || area.pressed ? Theme.faceHover : Theme.face
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true

        function setFromX(x) {
            root.moved(Math.min(1, Math.max(0, (x - root.knob / 2) / (width - root.knob))))
        }

        onPressed: mouse => setFromX(mouse.x)
        onPositionChanged: mouse => {
            if (pressed)
                setFromX(mouse.x)
        }
        onWheel: wheel => root.moved(Math.min(1, Math.max(0, root.value + (wheel.angleDelta.y > 0 ? root.step : -root.step))))
    }
}
