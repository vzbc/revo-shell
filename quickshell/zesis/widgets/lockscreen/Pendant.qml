import QtQuick
import "../../"

Canvas {
    id: root

    property color ink: Colors.text
    property real alpha: 0.28
    property real diamondRelPos: 0.58  // 0-1 along the line's length
    property real diamondW: 5          // UIScale units
    property real diamondH: 14         // UIScale units
    property real beadR: 5             // UIScale units, 0 to omit

    property real endX: 0
    property real endY: height

    readonly property real _s: UIScale.value

    implicitWidth: Math.round((diamondW + 8) * _s) * 2 + 1

    onInkChanged: requestPaint()
    onAlphaChanged: requestPaint()
    onDiamondRelPosChanged: requestPaint()
    onEndXChanged: requestPaint()
    onEndYChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        var ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);
        var s = _s;
        var cx = width / 2;
        var ex = cx + endX;
        var ey = endY;

        ctx.strokeStyle = Qt.rgba(ink.r, ink.g, ink.b, alpha);
        ctx.fillStyle = Qt.rgba(ink.r, ink.g, ink.b, alpha);
        ctx.lineWidth = 1;

        ctx.beginPath();
        ctx.moveTo(cx, 0);
        ctx.lineTo(ex, ey);
        ctx.stroke();

        var amidX = cx + endX * diamondRelPos;
        var amidY = ey * diamondRelPos;
        var angle = Math.atan2(ey, ex - cx);
        var aw = Math.round(diamondW * s);
        var ah = Math.round(diamondH * s);
        ctx.save();
        ctx.translate(amidX, amidY);
        ctx.rotate(angle - Math.PI / 2);
        ctx.beginPath();
        ctx.moveTo(0, -ah);
        ctx.lineTo(aw, 0);
        ctx.lineTo(0, ah);
        ctx.lineTo(-aw, 0);
        ctx.closePath();
        ctx.fill();
        ctx.restore();

        if (beadR > 0) {
            var br = Math.round(beadR * s);
            ctx.beginPath();
            ctx.arc(ex, ey, br, 0, 2 * Math.PI);
            ctx.fill();
        }
    }
}
