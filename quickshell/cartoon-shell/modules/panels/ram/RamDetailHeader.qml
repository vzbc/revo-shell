import QtQuick
import qs.services
import qs.components

Item {
  id: header
  signal closeClicked

  property real animationProgress: 0

  CustomText{
    anchors.centerIn: parent

    name: lang?.ram?.panel_title || "Quản lí Ram"
    size: "large"
    isBold: true
    opacity: root.animationProgress > 0.1 ? 1 : 0
  }
  CloseButton{
    onClicked: VisibleService.togglePanel("ram")
    opacity: root.animationProgress > 0.15 ? 1 : 0
  }
}
