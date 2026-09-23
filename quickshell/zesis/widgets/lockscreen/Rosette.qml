import QtQuick
import "../../"

// Concentric spoke wheel, full circle or top-half only (flat base at bottom).
// Use halfCircle, true to get the semicircular rose-window shape.
Canvas {
    id: root

    property color ink: Colors.text
    property real alpha: 0.28
    property real outerRadius: 180   // UIScale units
    property int spokes: 16
    property int rings: 3            // concentric rings including outer
    property bool halfCircle: true   // flat side at bottom

    readonly property real _s: UIScale.value

    implicitWidth: Math.round(outerRadius * 2 * _s)
    implicitHeight: Math.round(outerRadius * (halfCircle ? 1.0 : 2.0) * _s)

    onInkChanged: requestPaint()
    onAlphaChanged: requestPaint()
    onSpokesChanged: requestPaint()
    onRingsChanged: requestPaint()
    onHalfCircleChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);
        var s = _s;
        var cx = width / 2;
        var cy = halfCircle ? height : height / 2;
        var R = Math.round(outerRadius * s);
        var hubR = Math.max(2, Math.round(R * 0.04));

        ctx.strokeStyle = Qt.rgba(ink.r, ink.g, ink.b, alpha);
        ctx.fillStyle = Qt.rgba(ink.r, ink.g, ink.b, alpha);
        ctx.lineWidth = 1;

        for (var ri = 1; ri <= rings; ri++) {
            var r = Math.round(R * ri / rings);
            ctx.beginPath();
            if (halfCircle)
                ctx.arc(cx, cy, r, Math.PI, 2 * Math.PI);
            else
                ctx.arc(cx, cy, r, 0, 2 * Math.PI);
            ctx.stroke();
        }

        if (halfCircle) {
            ctx.beginPath();
            ctx.moveTo(cx - R, cy);
            ctx.lineTo(cx + R, cy);
            ctx.stroke();
        }

        var totalAngle = halfCircle ? Math.PI : 2 * Math.PI;
        var startAngle = halfCircle ? Math.PI : 0;
        for (var si = 0; si < spokes; si++) {
            var angle = startAngle + (si / spokes) * totalAngle;
            ctx.beginPath();
            ctx.moveTo(cx + hubR * Math.cos(angle), cy + hubR * Math.sin(angle));
            ctx.lineTo(cx + R * Math.cos(angle), cy + R * Math.sin(angle));
            ctx.stroke();
        }

        ctx.beginPath();
        ctx.arc(cx, cy, hubR, 0, 2 * Math.PI);
        ctx.fill();
    }
}
