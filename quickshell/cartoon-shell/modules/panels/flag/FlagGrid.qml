import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services
import qs.commons
import "." as Com

Flickable {
  id: root

  property var flagList: []
  property string selectedFlag: ""
  property real animationProgress: 0

  width: parent.width
  height: ScalerService.s(234)
  contentWidth: flowContainer.width
  contentHeight: flowContainer.height
  clip: true

  // Cho phép kéo thả và quán tính
  flickableDirection: Flickable.HorizontalFlick
  boundsBehavior: Flickable.DragAndOvershootBounds
  rebound: Transition {
    NumberAnimation { properties: "x"; duration: 300; easing.type: Easing.OutQuad }
  }

  Flow {
    id: flowContainer
    width: Math.max(root.width, implicitWidth)  // Quan trọng: đảm bảo width đủ lớn
    height: ScalerService.s(234)
    spacing: ScalerService.s(12)
    flow: Flow.TopToBottom

    Repeater {
      model: root.flagList
      Item {
        id: parentItem
        width: ScalerService.s(105)
        height: ScalerService.s(70)
        Com.FlagItem {
          implicitWidth: 0
          implicitHeight: 0
          SequentialAnimation on implicitWidth {
            running: root.animationProgress > 0.5

            PauseAnimation {
              duration: index * 15
            }

            NumberAnimation {
              to: parentItem.width
              duration: 500
              easing.type: Easing.OutCubic
            }
          }
          SequentialAnimation on implicitHeight {
            running: root.animationProgress > 0.5

            PauseAnimation {
              duration: index * 15
            }

            NumberAnimation {
              to: parentItem.height
              duration: 500
              easing.type: Easing.OutCubic
            }
          }

          animationProgress: root.animationProgress
          flagName: modelData.name
          displayName: modelData.displayName
          isSelected: root.selectedFlag === modelData.name

          onClicked: {
            Settings.appearance.countryFlag = flagName
          }
        }
      }
    }
  }
}
