import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "clockTime" as Com
import qs.components
import qs.services

Item {
  id: root
  ScrollView {
    id: scrollView
    anchors.fill: parent
    anchors.margins: ScalerService.s(20)
    clip: true

    ScrollBar.vertical.policy: ScrollBar.AsNeeded
    ScrollBar.horizontal.policy: ScrollBar.AsNeeded

    contentWidth: contentLayout.width
    contentHeight: contentLayout.height

    ColumnLayout {
      id: contentLayout
      width: scrollView.availableWidth
      spacing: ScalerService.s(20)
      anchors.margins: ScalerService.s(20)

      HeaderSettings {
        name: "Clock Time"
      }

      Rectangle {
        Layout.fillWidth: true
        height: ScalerService.s(1)
        color: theme.primary.foreground
        opacity: 0.3
      }

      // Nội dung Clock ở đây
      Text {
        text: "Clock settings content"
        color: theme.primary.foreground
        Layout.alignment: Qt.AlignLeft
        font.pixelSize: ScalerService.s(14)
      }

      Com.ClockPanelToggle {
        Layout.fillWidth: true
      }

      Com.ClockPositionSelector {
        Layout.fillWidth: true
      }

      Item {
        // Spacer để đảm bảo nội dung không bị che
        Layout.fillHeight: true
      }
    }
  }
}
