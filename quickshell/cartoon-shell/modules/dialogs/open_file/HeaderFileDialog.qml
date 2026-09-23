import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

Item {
  id: root
  Layout.fillWidth: true
  Layout.preferredHeight: ScalerService.s(50)

  // Title centered
  CustomText {
    anchors.centerIn: parent

    name: "Open File"
    isBold: true
    size: "large"
  }

  // Close button (right side)
  CloseButton{
    onClicked: VisibleService.togglePanel("filedialog")
  }
}
