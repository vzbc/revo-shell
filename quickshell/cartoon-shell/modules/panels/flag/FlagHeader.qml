import qs.components
import QtQuick.Layouts
import QtQuick
import qs.services

Item {
  property real animationProgress: 0
  CustomText {
    anchors.centerIn: parent
    name: "Country Flag"
    isBold: true
    size: "large"
    opacity: root.animationProgress > 0.3 ? 1 : 0
  }
  CloseButton {
    opacity: root.animationProgress > 0.4 ? 1 : 0
    onClicked: VisibleService.togglePanel("flag")
  }
}
