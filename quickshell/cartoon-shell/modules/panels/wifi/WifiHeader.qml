import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components

Item {
  id: header
  property var wifiManager
  property real animationProgress: 0

  CustomText {
    anchors.centerIn: parent
    name: "WIFI"
    size: "large"
    isBold: true
    opacity: root.animationProgress > 0.2 ? 1 : 0
  }
  CloseButton{
    onClicked: VisibleService.togglePanel("wifi")
    opacity: root.animationProgress > 0.15 ? 1 : 0
  }

}
