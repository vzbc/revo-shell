import QtQuick
import QtQuick.Shapes

Shape {
    id: root

    property bool connected: false
    property bool on: true
    property color color: "#f5f5f7"
    property color offColor: Qt.rgba(255, 255, 255, 0.45)

    antialiasing: true
    preferredRendererType: Shape.GeometryRenderer

    readonly property color stroke: root.on ? (root.connected ? root.color : root.offColor) : root.offColor

    ShapePath {
        strokeColor: root.stroke
        fillColor: "transparent"
        strokeWidth: 2.4
        PathSvg { path: "M 5 12.2 A 7.5 7.5 0 0 1 19 12.2 M 8.3 12.2 A 4 4 0 0 1 15.7 12.2 M 11.2 12.2 A 1.1 1.1 0 0 1 12.8 12.2" }
    }

    ShapePath {
        strokeColor: "transparent"
        fillColor: root.connected ? root.stroke : "transparent"
        PathSvg { path: "M 12 15.9 m -1.5 0 a 1.5 1.5 0 1 0 3 0 a 1.5 1.5 0 1 0 -3 0" }
    }

    ShapePath {
        strokeColor: root.on ? "transparent" : root.offColor
        fillColor: "transparent"
        strokeWidth: 2.4
        PathSvg { path: "M 4.5 4.5 L 19.5 19.5" }
    }
}
