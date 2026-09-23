// components/Settings/NetworkSettings.qml
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
      width: parent.width - ScalerService.s(40)
      spacing: ScalerService.s(20)

      Text {
        text: "Network Settings"
        color: theme.primary.foreground
        font.pixelSize: ScalerService.s(24)
        font.bold: true
        font.family: "ComicShannsMono Nerd Font"
        Layout.topMargin: ScalerService.s(10)
      }

      Rectangle {
        Layout.fillWidth: true
        height: ScalerService.s(1)
        color: theme.primary.foreground
      }

      // Thông báo phần đã bị xóa
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: ScalerService.s(100)
        radius: ScalerService.s(8)
        color: theme.primary.background
        border.color: theme.normal.black
        border.width: ScalerService.s(1)

        Column {
          anchors.centerIn: parent
          spacing: ScalerService.s(10)

          Text {
            text: "Network Settings Content"
            color: theme.primary.foreground
            font.pixelSize: ScalerService.s(16)
            font.bold: true
            font.family: "ComicShannsMono Nerd Font"
          }

          Text {
            text: "Network information and controls have been removed."
            color: theme.primary.dim_foreground
            font.pixelSize: ScalerService.s(12)
            font.family: "ComicShannsMono Nerd Font"
            horizontalAlignment: Text.AlignHCenter
            width: parent.width
          }
        }
      }
    }
  }
}
