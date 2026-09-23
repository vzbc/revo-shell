import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs.services
import qs.commons
import "./" as Com

PanelWindow {
  id: batteryDetailPanel

  property var sizes: currentSizes.batteryDetailPanel || {}

  width: ScalerService.s(450)
  height: ScalerService.s(290)
  
  anchors {
    left: Settings.bar.position === "left"
    right: Settings.bar.position === "right" || Settings.bar.position === "top" || Settings.bar.position === "bottom"
    top: Settings.bar.position === "top"
    bottom: Settings.bar.position === "left" || Settings.bar.position === "right" || Settings.bar.position === "bottom"
  }

  margins {
    top: Settings.bar.position === "top" ? ScalerService.s(10) : 0
    bottom: (Settings.bar.position === "bottom" || Settings.bar.position === "left" || Settings.bar.position === "right") ? ScalerService.s(10) : 0
    left: Settings.bar.position === "left" ? ScalerService.s(10) : 0
    right: (Settings.bar.position === "right" || Settings.bar.position === "top" || Settings.bar.position === "bottom") ? ScalerService.s(10) : 0
  }
  
  color: "transparent"

  Rectangle {
    anchors.fill: parent
    radius: ScalerService.s(Settings.appearance.radius1)
    border.width: Settings.appearance.enableBorder ? ScalerService.s(3) : 0
    color: theme.primary.background
    border.color: theme.button.border

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: ScalerService.s(16)
      spacing: ScalerService.s(16)

      Com.BatteryHeader{
        Layout.fillWidth: true
        Layout.preferredHeight: ScalerService.s(40)
      }

      // Battery Panel Component
      Com.BatteryPanel {
        Layout.fillWidth: true
        Layout.fillHeight: true
      }
    }
  }

  // Tự động refresh khi panel hiển thị
  Timer {
    interval: 2000
    running: batteryDetailPanel.visible
    repeat: true
    onTriggered: {
      // Refresh dữ liệu nếu cần
    }
  }
}
