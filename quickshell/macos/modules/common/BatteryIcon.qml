import QtQuick
import QtQuick.Shapes

Shape {
    id: root

    property real level: 1.0
    property bool charging: false
    property color color: "#f5f5f7"
    property color lowColor: "#ff453a"
    property color chargeColor: "#30d158"
    property color frameColor: Qt.rgba(255, 255, 255, 0.45)

    antialiasing: true
    preferredRendererType: Shape.GeometryRenderer

    readonly property bool low: root.level < 0.2
    readonly property color bodyColor: root.charging ? root.chargeColor : (root.low ? root.lowColor : root.color)

    function fillPath() {
        const inset = 1.4;
        const innerLeft = 3.5 + inset;
        const innerTop = 7 + inset;
        const innerW = 15.5 - inset * 2;
        const innerH = 7 - inset * 2;
        const w = Math.max(0, Math.min(1, root.level)) * innerW;
        return "M " + innerLeft + " " + innerTop +
               " H " + (innerLeft + w) +
               " V " + (innerTop + innerH) +
               " H " + innerLeft + " Z";
    }

    ShapePath {
        strokeColor: "transparent"
        fillColor: root.bodyColor
        PathSvg { path: root.fillPath() }
    }

    ShapePath {
        strokeColor: root.frameColor
        fillColor: "transparent"
        strokeWidth: 2
        joinStyle: ShapePath.RoundJoin
        PathSvg { path: "M 3.5 7.5 A 2 2 0 0 1 5.5 5.5 H 17.5 A 2 2 0 0 1 19.5 7.5 V 11.5 A 2 2 0 0 1 17.5 13.5 H 5.5 A 2 2 0 0 1 3.5 11.5 Z M 20.3 7.5 H 21.2 A 0.7 0.7 0 0 1 21.9 8.2 V 10.8 A 0.7 0.7 0 0 1 21.2 11.5 H 20.3 Z" }
    }

    ShapePath {
        strokeColor: "transparent"
        fillColor: root.charging ? "#1b1b1e" : "transparent"
        PathSvg { path: "M 10.6 5.4 L 7.2 10.2 H 9.6 L 7.4 14.4 L 12.2 9.4 H 9.7 Z" }
    }
}
