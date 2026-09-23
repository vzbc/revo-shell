// TemperatureChart.qml
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.services
import qs.components

Item {
  id: chart
  clip: true

  // Expects an array of 12 numbers (hours 0,2,4,...,22)
  property var temperatures: []

  // --- Color Scheme ---
  property string lineColor: theme.button.text  // Màu xanh dương cho đường
  property string pointColor: theme.button.text  // Màu điểm
  property string gridColor: theme.primary.dim_foreground // Màu lưới xanh nhạt
  property string textColor: theme.primary.foreground  // Màu chữ trắng mờ
  property string backgroundColor1: "#0a0e27"  // Màu nền trên cùng (xanh đậm)
  property string backgroundColor2: theme.button.text  // Màu nền dưới cùng (xanh nhạt hơn)

  // --- Line Style ---
  property real lineWidth: ScalerService.s(2.5)

  // --- Chart Margins ---
  property real paddingLeft: ScalerService.s(50)
  property real paddingRight: ScalerService.s(30)
  property real paddingTop: ScalerService.s(50)
  property real paddingBottom: ScalerService.s(40)

  // --- Feature Toggles ---
  property bool showPoints: true
  property bool showFill: true
  property bool showGrid: true
  property bool showTemperatureLabels: true

  // --- Temperature Axis Limits ---
  property real minTemp: -10
  property real maxTemp: 45

  // ==================== INTERNAL PROPERTIES ====================
  property int pointCount: 12
  property real chartWidth: width - paddingLeft - paddingRight
  property real chartHeight: height - paddingTop - paddingBottom
  property real tempRange: maxTemp - minTemp

  // ==================== DATA VALIDATION ====================
  function isValidData() {
    return temperatures && temperatures.length === pointCount && temperatures.every(t => typeof t === 'number' && !isNaN(t))
  }

  // ==================== COORDINATE HELPERS ====================
  function getX(index) {
    return paddingLeft + (index / (pointCount - 1)) * chartWidth
  }

  function getHourFromIndex(index) {
    return index * 2
  }

  function getY(temp) {
    var y = paddingTop + chartHeight - ((temp - minTemp) / tempRange) * chartHeight
    return Math.max(paddingTop - 5, Math.min(height - paddingBottom + 5, y))
  }

  // ==================== CANVAS RENDERING ====================
  Canvas {
    id: canvas
    anchors.fill: parent

    renderStrategy: Canvas.Cooperative
    renderTarget: Canvas.Image

    onPaint: {
      if (!isValidData()) return

      var ctx = getContext("2d")
      ctx.reset()
      ctx.clearRect(0, 0, width, height)

      if (showGrid) drawGrid(ctx)
      if (showFill) drawFill(ctx)
      drawLine(ctx)
      if (showPoints) drawPoints(ctx)
      if (showTemperatureLabels) drawTemperatureLabels(ctx)
    }

    function drawGrid(ctx) {
      ctx.save()
      ctx.strokeStyle = Qt.alpha(theme.primary.dim_foreground, 0.3)
      ctx.lineWidth = ScalerService.s(1)
      ctx.fillStyle = textColor
      ctx.font = `${ScalerService.s(11)}px "Segoe UI", sans-serif`

      // Horizontal Grid Lines
      ctx.textAlign = "right"
      ctx.textBaseline = "middle"

      for (var i = 0; i <= 4; i++) {
        var temp = minTemp + (i / 4) * tempRange
        var y = getY(temp)

        // Vẽ đường kẻ ngang đứt nét (giống trong ảnh)
        ctx.beginPath()
        ctx.setLineDash([])
        ctx.moveTo(paddingLeft, y)
        ctx.lineTo(width - paddingRight, y)
        ctx.stroke()

        // Reset line dash cho các đường khác
        ctx.setLineDash([])

        // Label nhiệt độ bên trái
        ctx.fillStyle = textColor
        ctx.fillText(temp.toFixed(1) + "°", paddingLeft - 8, y)
      }

      // Vertical Grid Lines
      ctx.textAlign = "center"
      ctx.textBaseline = "top"
      ctx.setLineDash([])

      for (var i = 0; i < pointCount; i++) {
        var x = getX(i)
        var hour = getHourFromIndex(i)

        // Chỉ vẽ đường kẻ dọc cho các giờ chẵn
        if (i === 0) {
          ctx.beginPath()
          ctx.moveTo(x, paddingTop)
          ctx.lineTo(x, height - paddingBottom)
          ctx.stroke()
        }

        // Label giờ
        ctx.fillStyle = textColor
        ctx.fillText(hour + "h", x, height - paddingBottom + 20)
      }

      ctx.setLineDash([])
      ctx.restore()
    }

    function drawLine(ctx) {
      ctx.save()
      ctx.beginPath()
      ctx.strokeStyle = lineColor
      ctx.lineWidth = lineWidth
      ctx.lineCap = "round"
      ctx.lineJoin = "round"

      var firstPoint = true
      for (var i = 0; i < pointCount; i++) {
        var x = getX(i)
        var y = getY(temperatures[i])

        if (firstPoint) {
          ctx.moveTo(x, y)
          firstPoint = false
        } else {
          var prevX = getX(i - 1)
          var prevY = getY(temperatures[i - 1])
          var cp1x = prevX + (x - prevX) / 3
          var cp1y = prevY
          var cp2x = x - (x - prevX) / 3
          var cp2y = y
          ctx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, x, y)
        }
      }
      ctx.stroke()
      ctx.restore()
    }

    function drawFill(ctx) {
      ctx.save()
      ctx.beginPath()

      var firstPoint = true
      for (var i = 0; i < pointCount; i++) {
        var x = getX(i)
        var y = getY(temperatures[i])

        if (firstPoint) {
          ctx.moveTo(x, y)
          firstPoint = false
        } else {
          var prevX = getX(i - 1)
          var prevY = getY(temperatures[i - 1])
          var cp1x = prevX + (x - prevX) / 3
          var cp1y = prevY
          var cp2x = x - (x - prevX) / 3
          var cp2y = y
          ctx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, x, y)
        }
      }

      ctx.lineTo(getX(pointCount - 1), height - paddingBottom)
      ctx.lineTo(getX(0), height - paddingBottom)
      ctx.closePath()

      // Gradient fill dưới đường (màu xanh mờ)
      var gradient = ctx.createLinearGradient(0, paddingTop, 0, height - paddingBottom)
      gradient.addColorStop(0, Qt.alpha(theme.button.text, 0.3))
      gradient.addColorStop(1, Qt.alpha(theme.button.text, 0.02))
      ctx.fillStyle = gradient
      ctx.fill()
      ctx.restore()
    }

    function drawPoints(ctx) {
      ctx.save()
      ctx.shadowBlur = 0

      for (var i = 0; i < pointCount; i++) {
        var x = getX(i)
        var y = getY(temperatures[i])

        // Outer glow
        ctx.beginPath()
        ctx.arc(x, y, ScalerService.s(8), 0, Math.PI * 2)
        ctx.fillStyle = "rgba(74, 158, 255, 0.2)"
        ctx.fill()

        // Main point
        ctx.beginPath()
        ctx.arc(x, y, ScalerService.s(5), 0, Math.PI * 2)
        ctx.fillStyle = lineColor
        ctx.fill()

        // Inner white dot
        ctx.beginPath()
        ctx.arc(x, y, ScalerService.s(2), 0, Math.PI * 2)
        ctx.fillStyle = "#ffffff"
        ctx.fill()
      }

      ctx.restore()
    }

    function drawTemperatureLabels(ctx) {
      ctx.save()
      ctx.font = `${ScalerService.s(11)}px "Segoe UI", sans-serif`
      ctx.fillStyle = textColor
      ctx.textAlign = "center"
      ctx.textBaseline = "bottom"
      ctx.shadowBlur = ScalerService.s(2)
      ctx.shadowColor = "rgba(0,0,0,0.5)"

      for (var i = 0; i < pointCount; i++) {
        var x = getX(i)
        var y = getY(temperatures[i])
        var tempValue = temperatures[i].toFixed(1)

        // Vẽ text
        ctx.fillStyle = textColor
        ctx.fillText(tempValue + "°", x, y - ScalerService.s(12))
      }

      ctx.restore()
    }

    function updateCanvas() {
      requestPaint()
    }
  }

  // ==================== UPDATE TRIGGERS ====================
  Timer {
    id: updateTimer
    interval: 20
    running: false
    onTriggered: canvas.updateCanvas()
  }

  onWidthChanged: updateTimer.start()
  onHeightChanged: updateTimer.start()
  onTemperaturesChanged: updateTimer.start()
  onLineColorChanged: updateTimer.start()
  onPointColorChanged: updateTimer.start()
  onGridColorChanged: updateTimer.start()
  onTextColorChanged: updateTimer.start()
  onLineWidthChanged: updateTimer.start()
  onPaddingLeftChanged: updateTimer.start()
  onPaddingRightChanged: updateTimer.start()
  onPaddingTopChanged: updateTimer.start()
  onPaddingBottomChanged: updateTimer.start()
  onShowPointsChanged: updateTimer.start()
  onShowFillChanged: updateTimer.start()
  onShowGridChanged: updateTimer.start()
  onShowTemperatureLabelsChanged: updateTimer.start()
  onMinTempChanged: updateTimer.start()
  onMaxTempChanged: updateTimer.start()

  Component.onCompleted: canvas.updateCanvas()

  // ==================== PUBLIC API ====================
  function updateData(newTemperatures) {
    if (newTemperatures.length === 12) {
      temperatures = newTemperatures
    } else {
      console.warn("TemperatureChart: Expected 12 values (every 2 hours), got", newTemperatures.length)
    }
  }

  function setMinMax(min, max) {
    minTemp = min
    maxTemp = max
  }
}
