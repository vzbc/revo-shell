pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../"

PanelWindow {
    id: root

    readonly property int panelW: Math.round(320 * UIScale.value)
    readonly property int triggerW: Math.round(52 * UIScale.value)
    readonly property int valveDiam: Math.round(42 * UIScale.value)
    readonly property real requiredDeg: 720.0

    readonly property real openness: Math.max(0, Math.min(1.0, drag.accumulated / root.requiredDeg))
    property bool latched: false

    WlrLayershell.namespace: "zesis:valvePanel"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    exclusiveZone: -1
    color: "transparent"
    anchors {
        left: true
        top: true
        bottom: true
    }
    implicitWidth: panelW

    mask: Region {
        x: 0
        y: 0
        width: drag.active ? root.panelW : root.triggerW + (root.panelW - root.triggerW) * root.openness
        height: 4096
    }

    QtObject {
        id: drag
        property real accumulated: 0.0
        property real lastAngle: 0.0
        property bool active: false
        onAccumulatedChanged: valveCanvas.requestPaint()
    }

    NumberAnimation {
        id: springAnim
        target: drag
        property: "accumulated"
        duration: Anim.slow
        easing.type: Easing.OutBack
        easing.overshoot: 0.7
    }

    Item {
        anchors.fill: parent
        clip: true

        Rectangle {
            id: panel
            width: root.panelW
            height: parent.height
            x: -(root.panelW - root.triggerW) * (1.0 - root.openness)
            color: Colors.bg
            border.color: Colors.outline
            border.width: 1

            Item {
                id: triggerStrip
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: root.triggerW

                Canvas {
                    id: valveCanvas
                    anchors.centerIn: parent
                    width: root.valveDiam
                    height: root.valveDiam

                    property bool _latched: root.latched
                    on_LatchedChanged: requestPaint()

                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);

                        var isLatched = root.latched;
                        var visualAngle = drag.accumulated;
                        var progress = Math.max(0, Math.min(1.0, drag.accumulated / root.requiredDeg));

                        var cx = width / 2;
                        var cy = height / 2;
                        var r = width / 2 - 1;
                        var rimW = Math.max(2, r * 0.13);
                        var hubR = r * 0.20;
                        var nSpokes = 4;
                        var nubR = Math.max(2, r * 0.11);
                        var spokeW = Math.max(1.5, r * 0.08);

                        // Progress track ring (static, behind wheel)
                        ctx.beginPath();
                        ctx.arc(cx, cy, r - rimW / 2, 0, Math.PI * 2);
                        ctx.strokeStyle = Colors.withAlpha(Colors.text, 0.08);
                        ctx.lineWidth = rimW;
                        ctx.stroke();

                        // Progress fill, grows clockwise from 12 o'clock
                        if (progress > 0) {
                            ctx.beginPath();
                            ctx.arc(cx, cy, r - rimW / 2, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * progress, false);
                            ctx.strokeStyle = isLatched ? Colors.accent : Colors.withAlpha(Colors.accent, 0.60);
                            ctx.lineWidth = rimW;
                            ctx.stroke();
                        }

                        // Rotating wheel
                        ctx.save();
                        ctx.translate(cx, cy);
                        ctx.rotate(visualAngle * Math.PI / 180);

                        // Spokes
                        ctx.lineWidth = spokeW;
                        ctx.lineCap = "round";
                        ctx.strokeStyle = isLatched ? Colors.withAlpha(Colors.accent, 0.70) : Colors.withAlpha(Colors.text, 0.40);
                        for (var i = 0; i < nSpokes; i++) {
                            var a = (i / nSpokes) * Math.PI * 2;
                            ctx.beginPath();
                            ctx.moveTo(Math.cos(a) * (hubR + 1), Math.sin(a) * (hubR + 1));
                            ctx.lineTo(Math.cos(a) * (r - rimW - nubR + 1), Math.sin(a) * (r - rimW - nubR + 1));
                            ctx.stroke();
                        }

                        // Grip nubs at spoke tips (on the rim)
                        ctx.fillStyle = isLatched ? Colors.accent : Colors.withAlpha(Colors.text, 0.50);
                        for (var j = 0; j < nSpokes; j++) {
                            var na = (j / nSpokes) * Math.PI * 2;
                            ctx.beginPath();
                            ctx.arc(Math.cos(na) * (r - rimW / 2), Math.sin(na) * (r - rimW / 2), nubR, 0, Math.PI * 2);
                            ctx.fill();
                        }

                        // Hub
                        ctx.beginPath();
                        ctx.arc(0, 0, hubR, 0, Math.PI * 2);
                        ctx.fillStyle = isLatched ? Colors.withAlpha(Colors.accent, 0.30) : Colors.withAlpha(Colors.text, 0.10);
                        ctx.fill();
                        ctx.strokeStyle = isLatched ? Colors.withAlpha(Colors.accent, 0.80) : Colors.withAlpha(Colors.text, 0.30);
                        ctx.lineWidth = 1.5;
                        ctx.stroke();

                        ctx.restore();
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    preventStealing: true

                    function angleAt(mx, my) {
                        return Math.atan2(my - height / 2, mx - width / 2) * 180 / Math.PI;
                    }

                    onPressed: mouse => {
                        springAnim.stop();
                        drag.lastAngle = angleAt(mouse.x, mouse.y);
                        drag.active = true;
                    }

                    onPositionChanged: mouse => {
                        if (!drag.active)
                            return;
                        var a = angleAt(mouse.x, mouse.y);
                        var delta = a - drag.lastAngle;
                        if (delta > 180)
                            delta -= 360;
                        if (delta < -180)
                            delta += 360;
                        drag.accumulated = Math.max(0, Math.min(root.requiredDeg, drag.accumulated + delta));
                        drag.lastAngle = a;
                        if (!root.latched && drag.accumulated >= root.requiredDeg)
                            root.latched = true;
                        else if (root.latched && drag.accumulated <= 0)
                            root.latched = false;
                    }

                    onReleased: {
                        drag.active = false;
                        springAnim.to = root.latched ? root.requiredDeg : 0;
                        springAnim.start();
                    }
                }
            }

            // Content area (left of trigger strip)
            Item {
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    left: parent.left
                    right: triggerStrip.left
                }
            }
        }
    }
}
