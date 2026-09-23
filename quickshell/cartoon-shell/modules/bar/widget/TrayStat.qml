import QtQuick
import QtQuick.Layouts
import qs.components
import qs.commons
import Quickshell.Services.Pipewire
import qs.services

Item {
  id: root

  property real currentBrightness: BrightnessService.currentBrightness


  implicitWidth: row.implicitWidth
  implicitHeight: row.implicitHeight


  RowLayout {
    id: row
    anchors.fill: parent
    spacing: ScalerService.s(2)

    IconText {
      name: VisibleService.tray ? "keyboard_arrow_down" : "keyboard_arrow_up"
      textColor: theme.button.text
      size: "normal"
    }
  }

}

