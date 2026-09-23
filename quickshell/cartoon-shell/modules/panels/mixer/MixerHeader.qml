import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

Item {
  id: root

  CustomText {
    name: lang.mixer.title
    size: "large"
    isBold: true
    anchors.centerIn: parent
  }
  CloseButton{
    onClicked: VisibleService.togglePanel("mixer")
  }
}
