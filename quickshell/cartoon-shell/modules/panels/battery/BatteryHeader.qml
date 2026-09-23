// BatteryHeader.qml
import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

Item {
  id: root

  // Title centered
  CustomText {
    anchors.centerIn: parent
    name: "Battery"
    isBold: true
    size: "large"

  }

  // Close button (right side)
  CloseButton{
    onClicked: VisibleService.togglePanel("battery")
  }
}
