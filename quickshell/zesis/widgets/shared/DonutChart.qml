import QtQuick
import "../../"

Item {
    id: root

    property var segments: []  // [{ color: color, value: real }]
    property real total: 100
    property string centerText: "0%"
    property string subText: ""

    onSegmentsChanged: canvas.requestPaint()
    onTotalChanged: canvas.requestPaint()
    Component.onCompleted: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);

            var cx = root.width / 2;
            var cy = root.height / 2;
            var outerR = Math.min(root.width, root.height) / 2 - 2;
            var ringW = Math.max(10, outerR * 0.34);
            var midR = outerR - ringW / 2;

            ctx.lineCap = "butt";
            ctx.lineWidth = ringW;

            // Background ring
            ctx.beginPath();
            ctx.arc(cx, cy, midR, 0, 2 * Math.PI);
            ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.07);
            ctx.stroke();

            var segs = root.segments;
            if (!segs || segs.length === 0 || root.total <= 0)
                return;
            var TAU = 2 * Math.PI;
            var angle = -Math.PI / 2;
            for (var i = 0; i < segs.length; i++) {
                var span = segs[i].value / root.total * TAU;
                if (span < 0.04) {
                    angle += span;
                    continue;
                }
                var pad = 0.018;
                ctx.beginPath();
                ctx.arc(cx, cy, midR, angle + pad, angle + span - pad);
                ctx.strokeStyle = segs[i].color;
                ctx.stroke();
                angle += span;
            }
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 2

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.centerText
            color: Colors.text
            font.pixelSize: Math.max(10, (Math.min(root.width, root.height) / 2 - 2) * 0.32)
            font.weight: Font.Bold
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.subText
            color: Colors.textDim
            font.pixelSize: Math.max(8, (Math.min(root.width, root.height) / 2 - 2) * 0.16)
            visible: root.subText !== ""
        }
    }
}
