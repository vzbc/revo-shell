import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import qs.services

Item {
  id: sineCookie
  property real sides: 5
  property color color: theme.button.text
  property real amplitude: root.width / ScalerService.s(50)
  property int renderPoints: 360

  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    ShapePath {
      strokeWidth: 0
      fillColor: sineCookie.color
      pathHints: ShapePath.PathSolid & ShapePath.PathNonIntersecting
      PathPolyline {
        path: {
          var points = []
          var cx = sineCookie.width / 2
          var cy = sineCookie.height / 2
          var steps = sineCookie.renderPoints
          var radius = sineCookie.width / 2 - sineCookie.amplitude
          for (var i = 0; i <= steps; i++) {
            var angle = (i / steps) * 2 * Math.PI
            var wave = Math.sin(angle * sineCookie.sides + Math.PI / 2) * sineCookie.amplitude
            var x = Math.cos(angle) * (radius + wave) + cx
            var y = Math.sin(angle) * (radius + wave) + cy
            points.push(Qt.point(x, y))
          }
          return points
        }
      }
    }
  }
}
