import QtQuick
import "../../"

// Drop-line from the top edge with N circles hanging in sequence.
// rings: array of { r, gap } where r = radius and gap = space above this
// circle's top edge (ignored for the first ring, use topGap instead).
Canvas {
    id: root

    property color ink: Colors.text
    property real alpha: 0.28
    property real topGap: 110    // UIScale units, space from top to first circle top
    property var rings: [
        {
            r: 58,
            gap: 0
        },
        {
            r: 28,
            gap: 18
        }
    ]

    readonly property real _s: UIScale.value

    implicitWidth: {
        var maxR = 0;
        for (var i = 0; i < rings.length; i++)
            maxR = Math.max(maxR, rings[i].r);
        return Math.round((maxR * 2 + 8) * _s);
    }

    implicitHeight: {
        var s = _s;
        var h = Math.round(topGap * s);
        for (var i = 0; i < rings.length; i++) {
            if (i > 0)
                h += Math.round(rings[i].gap * s);
            h += Math.round(rings[i].r * 2 * s);
        }
        return h;
    }

    onInkChanged: requestPaint()
    onAlphaChanged: requestPaint()
    onTopGapChanged: requestPaint()
    onRingsChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);
        var s = _s;
        var cx = width / 2;

        ctx.strokeStyle = Qt.rgba(ink.r, ink.g, ink.b, alpha);
        ctx.lineWidth = 1;

        var centers = [];
        var radii = [];
        var y = Math.round(topGap * s);

        for (var i = 0; i < rings.length; i++) {
            var r = Math.round(rings[i].r * s);
            if (i > 0)
                y += Math.round(rings[i].gap * s);
            centers.push(y + r);
            radii.push(r);
            y += r * 2;
        }

        ctx.beginPath();
        ctx.moveTo(cx, 0);
        ctx.lineTo(cx, centers[0] - radii[0]);
        ctx.stroke();

        for (var i = 0; i < centers.length - 1; i++) {
            ctx.beginPath();
            ctx.moveTo(cx, centers[i] + radii[i]);
            ctx.lineTo(cx, centers[i + 1] - radii[i + 1]);
            ctx.stroke();
        }

        for (var i = 0; i < centers.length; i++) {
            ctx.beginPath();
            ctx.arc(cx, centers[i], radii[i], 0, 2 * Math.PI);
            ctx.stroke();
        }
    }
}
