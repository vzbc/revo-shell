// FloatingCircles.qml
import QtQuick

Item {
  id: root

  property color circleColor: theme.button.text
  property int circleCount: 5
  property real minRadius: 80
  property real maxRadius: 250
  property real minOpacity: 0.03
  property real maxOpacity: 0.08
  property real minDuration: 40000
  property real maxDuration: 80000

  anchors.fill: parent
  clip: true

  Repeater {
    id: circlesRepeater
    model: root.circleCount

    Rectangle {
      id: circle

      // Kích thước ngẫu nhiên
      property real circleRadius: Math.random() * (root.maxRadius - root.minRadius) + root.minRadius
      property real circleOpacity: Math.random() * (root.maxOpacity - root.minOpacity) + root.minOpacity
      property real moveDuration: Math.random() * (root.maxDuration - root.minDuration) + root.minDuration

      width: circleRadius * 2
      height: circleRadius * 2
      radius: circleRadius
      color: root.circleColor
      opacity: circleOpacity

      // Vị trí ban đầu ngẫu nhiên
      x: Math.random() * (parent.width - width)
      y: Math.random() * (parent.height - height)

      // Animation di chuyển
      ParallelAnimation {
        id: moveAnimation
        loops: Animation.Infinite
        running: true

        NumberAnimation {
          target: circle
          property: "x"
          to: Math.random() * (circle.parent.width - circle.width)
          duration: circle.moveDuration
          easing.type: Easing.InOutQuad
        }

        NumberAnimation {
          target: circle
          property: "y"
          to: Math.random() * (circle.parent.height - circle.height)
          duration: circle.moveDuration
          easing.type: Easing.InOutQuad
        }
      }

      // Animation scale
      SequentialAnimation {
        loops: Animation.Infinite
        running: true

        NumberAnimation {
          target: circle
          property: "scale"
          to: 1.15
          duration: Math.random() * 8000 + 4000
          easing.type: Easing.InOutSine
        }

        NumberAnimation {
          target: circle
          property: "scale"
          to: 0.85
          duration: Math.random() * 8000 + 4000
          easing.type: Easing.InOutSine
        }
      }

      // Thay đổi hướng di chuyển định kỳ
      Timer {
        interval: circle.moveDuration
        running: true
        repeat: true

        onTriggered: {
          // Lưu vị trí hiện tại
          var currentX = circle.x
          var currentY = circle.y

          // Cập nhật thời gian mới
          circle.moveDuration = Math.random() * (root.maxDuration - root.minDuration) + root.minDuration

          // Tạo target mới
          var newX = Math.random() * (circle.parent.width - circle.width)
          var newY = Math.random() * (circle.parent.height - circle.height)

          // Khởi tạo lại animation
          moveAnimation.stop()
          moveAnimation.restart()
        }
      }

    }
  }
}
