import QtQuick
import "../../"

// Canvas bar chart for DiasporaStatsService.dailyHistory.
Item {
    id: root

    property var points: []  // [{ dayStartUnix, total, verified, active }, ...], oldest first

    onPointsChanged: canvas.requestPaint()
    Component.onCompleted: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);

            var pts = root.points;
            if (!pts || pts.length === 0)
                return;

            var maxTotal = 1;
            for (var i = 0; i < pts.length; i++)
                maxTotal = Math.max(maxTotal, pts[i].total);

            var n = pts.length;
            var slot = width / n;
            var barW = Math.max(1, Math.min(slot * 0.6, Math.round(10 * UIScale.value)));
            var baseY = height;

            for (var j = 0; j < n; j++) {
                var p = pts[j];
                var cx = slot * j + slot / 2;

                var totalH = (p.total / maxTotal) * height;
                ctx.fillStyle = Colors.withAlpha(Colors.text, 0.12);
                ctx.fillRect(cx - barW / 2, baseY - totalH, barW, totalH);

                var activeH = (p.active / maxTotal) * height;
                if (activeH > 0.5) {
                    var activeW = Math.max(1, barW * 0.55);
                    ctx.fillStyle = Colors.accent;
                    ctx.fillRect(cx - activeW / 2, baseY - activeH, activeW, activeH);
                }
            }
        }
    }
}
