import QtQuick
import "../../"

Item {
    id: root
    property real from: 0
    property real to: 100
    property real value: 50
    property real step: 1
    property bool muted: false
    property real handleSize: Math.round(18 * UIScale.value)
    signal moved(real val)
    signal wheeled(real angleDelta)
    signal released

    implicitHeight: Math.round(24 * UIScale.value)
    readonly property real _t: mouseArea.pressed ? _dragT : Math.max(0, Math.min(1, (value - from) / Math.max(0.0001, to - from)))
    property real _dragT: 0

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        height: UIScale.spacingSm
        radius: UIScale.spacingXs
        color: Colors.surfaceHigh

        Rectangle {
            width: parent.width * root._t
            height: parent.height
            radius: parent.radius
            color: root.muted ? Colors.muted : Colors.accent
            Behavior on color {
                ColorAnimation {
                    duration: Anim.fast
                }
            }
            Behavior on width {
                NumberAnimation {
                    duration: Anim.drag
                    easing.type: Easing.OutQuad
                }
            }
        }
    }

    Rectangle {
        width: root.handleSize
        height: root.handleSize
        radius: root.handleSize / 2
        anchors.verticalCenter: parent.verticalCenter
        x: root._t * (root.width - root.handleSize)
        color: root.muted ? Colors.muted : Colors.accent
        Behavior on color {
            ColorAnimation {
                duration: Anim.fast
            }
        }
        Behavior on x {
            NumberAnimation {
                duration: Anim.drag
                easing.type: Easing.OutQuad
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        preventStealing: true
        cursorShape: Qt.SizeHorCursor
        onPressed: function (m) {
            setFromX(m.x);
        }
        onPositionChanged: function (m) {
            if (pressed)
                setFromX(m.x);
        }
        onReleased: function (m) {
            root.released();
        }
        onWheel: function (w) {
            root.wheeled(w.angleDelta.y);
        }
        function setFromX(x) {
            var t = Math.max(0, Math.min(1, (x - root.handleSize * 0.5) / (root.width - root.handleSize)));
            var raw = root.from + t * (root.to - root.from);
            var quantized = Math.round(raw / root.step) * root.step;
            root._dragT = (quantized - root.from) / Math.max(0.0001, root.to - root.from);
            root.moved(quantized);
        }
    }
}
