import QtQuick
import qs.services
import qs.components

Item {
  id: header
  signal closeClicked

  CustomText {
    anchors.centerIn: parent
    name: lang.CpuPane.title
    size: "large"
    isBold: true
  }
  CloseButton{
    onClicked: VisibleService.togglePanel("cpu")
  }
}
