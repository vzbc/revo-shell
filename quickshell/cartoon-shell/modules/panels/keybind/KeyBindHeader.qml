import QtQuick
import qs.services
import qs.components

Item {
  id: header

  CustomText{
    anchors.centerIn: parent

    name: "All keyboard shortcuts in Hyprland"
    size: "large"
    isBold: true
  }
  CloseButton{
    onClicked: VisibleService.togglePanel("keybind")
  }
}
