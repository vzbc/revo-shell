import QtQuick
import qs.services
import qs.components

Item {
  id: header

  CustomText{
    name: lang?.calendar?.title || "Lịch"
    anchors.centerIn: parent

    isBold: true
    size: "large"

  }
  CloseButton{
    onClicked: VisibleService.togglePanel("calendar")
  }
}
