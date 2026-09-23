// components/Settings/[Tên]Settings.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services

Item {
  ScrollView {
    anchors.fill: parent
    anchors.margins: ScalerService.s(20)
    clip: true

    ColumnLayout {
      width: parent.width
      spacing: ScalerService.s(15)

      Text {
        text: "Performance Settings"
        color: theme.primary.foreground
        font.pixelSize: ScalerService.s(24)
        font.bold: true
        Layout.topMargin: ScalerService.s(10)
      }

      Rectangle {
        Layout.fillWidth: true
        height: ScalerService.s(1)
        color: theme.primary.foreground
      }

      // Nội dung cài đặt cụ thể sẽ được thêm ở đây
      Text {
        text: "Cài đặt [tên mục] sẽ được hiển thị ở đây"
        color: theme.primary.dim_foreground
        font.pixelSize: ScalerService.s(14)
        Layout.alignment: Qt.AlignCenter
        Layout.fillHeight: true
      }
    }
  }
}
