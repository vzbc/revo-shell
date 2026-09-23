// StarField.qml
import QtQuick
import qs.services

Item {
  id: root

  property int starCount: 50
  property real starMinSize: ScalerService.s(2)
  property real starMaxSize: ScalerService.s(5)
  property color starColor: theme.button.text
  property real starMinOpacity: 0.3
  property real starMaxOpacity: 1.0
  property int starFadeDuration: 1000

  property int shootingStarCount: 10
  property color shootingStarColor: theme.button.text
  property real shootingStarMinSpeed: 0.4
  property real shootingStarMaxSpeed: 1
  property int shootingStarMinDelay: 2000  // Tăng delay để tránh spam
  property int shootingStarMaxDelay: 7000
  property int shootingStarTrailMinLength: 80
  property int shootingStarTrailMaxLength: 230

  anchors.fill: parent

  // Layer sao cố định
  Item {
    id: starsLayer
    anchors.fill: parent

    Repeater {
      id: starsRepeater
      model: root.starCount

      Rectangle {
        id: star

        property real starOpacity: Math.random() * (root.starMaxOpacity - root.starMinOpacity) + root.starMinOpacity

        x: Math.random() * root.width
        y: Math.random() * root.height
        width: Math.random() * (root.starMaxSize - root.starMinSize) + root.starMinSize
        height: width
        radius: width / 2
        color: root.starColor
        opacity: 0

        SequentialAnimation on opacity {
          id: starAnimation
          loops: Animation.Infinite
          running: true

          PauseAnimation {
            duration: Math.random() * 2000
          }
          NumberAnimation {
            to: star.starOpacity
            duration: root.starFadeDuration
          }
          NumberAnimation {
            to: 0
            duration: root.starFadeDuration
          }
        }
      }
    }
  }

  // Layer sao băng
  Item {
    id: shootingStarsLayer
    anchors.fill: parent

    Repeater {
      id: shootingStarsRepeater
      model: root.shootingStarCount

      Item {
        id: shootingStar

        property real speed: 0
        property real startX: 0
        property real startY: 0
        property real endX: 0
        property real endY: 0
        property int trailLength: 0

        visible: opacity > 0
        opacity: 0
        rotation: 135

        // Thân sao băng
        Rectangle {
          width: ScalerService.s(6)
          height: ScalerService.s(6)
          radius: ScalerService.s(3)
          color: root.shootingStarColor

          // Đuôi sao băng
          Rectangle {
            anchors.right: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: shootingStar.trailLength
            height: ScalerService.s(3)
            opacity: 0.7
            gradient: Gradient {
              orientation: Gradient.Horizontal
              GradientStop { position: 0.0; color: "transparent" }
              GradientStop { position: 1.0; color: root.shootingStarColor }
            }
          }
        }

        // Hàm random giá trị
        function randomRange(min, max) {
          return Math.random() * (max - min) + min
        }

        // Hàm khởi tạo lại sao băng
        function resetShootingStar() {
          var offsetX = randomRange(-300, 300)
          var offsetY = randomRange(-200, 200)

          startX = root.width + 400 + offsetX
          startY = -300 + offsetY
          endX = -1000 + randomRange(-500, 500)
          endY = root.height + 800 + randomRange(-400, 400)

          x = startX
          y = startY
          speed = randomRange(root.shootingStarMinSpeed, root.shootingStarMaxSpeed)
          trailLength = randomRange(root.shootingStarTrailMinLength, root.shootingStarTrailMaxLength)
        }

        // Animation cho sao băng
        SequentialAnimation {
          id: shootingStarAnimation
          loops: Animation.Infinite
          running: true

          // Delay ngẫu nhiên trước khi bay
          PauseAnimation {
            id: delayPause
            duration: randomRange(root.shootingStarMinDelay, root.shootingStarMaxDelay)
          }

          // Reset vị trí
          ScriptAction {
            script: {
              shootingStar.resetShootingStar()
            }
          }

          // Xuất hiện
          NumberAnimation {
            target: shootingStar
            property: "opacity"
            from: 0
            to: 1
            duration: 200
          }

          // Di chuyển
          ParallelAnimation {
            NumberAnimation {
              target: shootingStar
              property: "x"
              to: shootingStar.endX
              duration: 2500 / shootingStar.speed
              easing.type: Easing.Linear
            }
            NumberAnimation {
              target: shootingStar
              property: "y"
              to: shootingStar.endY
              duration: 2500 / shootingStar.speed
              easing.type: Easing.Linear
            }
          }

          // Biến mất
          NumberAnimation {
            target: shootingStar
            property: "opacity"
            to: 0
            duration: 200
          }
        }

        Component.onCompleted: {
          resetShootingStar()
        }
      }
    }
  }
}
