import QtQuick
import QtQuick.Shapes

Shape {
    id: root

    property string path: ""
    property color color: "#e8e8e8"
    property color fill: "transparent"
    property real strokeWidth: 1.5

    antialiasing: true
    preferredRendererType: Shape.GeometryRenderer

    ShapePath {
        strokeColor: root.color
        fillColor: root.fill
        strokeWidth: root.strokeWidth
        joinStyle: ShapePath.RoundJoin
        PathSvg { path: root.path }
    }
}
