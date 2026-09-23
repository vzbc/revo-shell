import QtQuick
import "../../../../"
import "../"

Item {
    id: root

    property int discRadius: 0
    property int effectiveN: 1

    readonly property real orbitRadius: Math.round(WorkspaceDiscService.chamberRadius * UIScale.value)
    readonly property color activeFill: Colors.accent
    readonly property color inactiveFill: Colors.surfaceHigh
    readonly property color windowsFill: Colors.withAlpha(Colors.accent, 0.4)
    readonly property color activeBorder: Colors.withAlpha(Colors.onAccent, 0.6)
    readonly property color inactiveBorder: Colors.withAlpha(Colors.accent, 0.2)
    readonly property real chamberBorderWidth: 1

    property Component chamberDelegate: Component {
        Rectangle {
            property bool isActive: false
            property bool hasWindows: false
            radius: width / 2
            color: isActive ? Colors.accent : (hasWindows ? Colors.withAlpha(Colors.accent, 0.4) : Colors.surfaceHigh)
            border.color: isActive ? Colors.withAlpha(Colors.onAccent, 0.6) : Colors.withAlpha(Colors.accent, 0.2)
            border.width: 1
            Behavior on color {
                ColorAnimation {
                    duration: Anim.fast
                }
            }
        }
    }

    Canvas {
        anchors.fill: parent
        rotation: (WorkspaceDiscService.toothWidth / 200) * (360 / root.effectiveN)

        readonly property color _surface: Colors.surface
        readonly property color _accent: Colors.accent
        on_SurfaceChanged: requestPaint()
        on_AccentChanged: requestPaint()
        readonly property int _n: root.effectiveN
        on_NChanged: requestPaint()
        readonly property int _r: root.discRadius
        on_RChanged: requestPaint()
        readonly property int _toothWidth: WorkspaceDiscService.toothWidth
        on_ToothWidthChanged: requestPaint()
        readonly property int _valleyDepth: WorkspaceDiscService.valleyDepth
        on_ValleyDepthChanged: requestPaint()

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);

            var W = _toothWidth / 100;
            var D = _valleyDepth / 100;
            var N = _n;
            var rOut = _r;
            var rIn = rOut * (1 - D);
            var cx = _r;
            var cy = _r;

            var steps = N * 64;
            ctx.beginPath();
            for (var i = 0; i <= steps; i++) {
                var angle = -(i / steps) * 2 * Math.PI;
                var t = ((-angle * N) / (2 * Math.PI) % 1 + 1) % 1;
                var blend = (t < W) ? 1.0 : Math.pow(Math.cos(Math.PI * (t - W) / (1 - W)), 4);
                var r = rIn + (rOut - rIn) * blend;
                var x = cx + r * Math.cos(angle);
                var y = cy + r * Math.sin(angle);
                if (i === 0)
                    ctx.moveTo(x, y);
                else
                    ctx.lineTo(x, y);
            }
            ctx.closePath();

            ctx.fillStyle = _surface;
            ctx.fill();
            ctx.strokeStyle = Colors.withAlpha(_accent, 0.4);
            ctx.lineWidth = 1.5 * UIScale.value;
            ctx.lineJoin = "round";
            ctx.stroke();
        }
    }

    Rectangle {
        anchors.centerIn: parent
        width: Math.round(10 * UIScale.value)
        height: Math.round(10 * UIScale.value)
        radius: width / 2
        color: Colors.accent
        opacity: 0.85
    }
}
