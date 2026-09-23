import QtQuick
import QtQuick.Layouts
import qs.services

Rectangle {
  id: emptyState
  color: "transparent"

  Column {
    anchors.centerIn: parent
    spacing: ScalerService.s(16)

    Rectangle {
      width: ScalerService.s(80)
      height: ScalerService.s(80)
      radius: ScalerService.s(16)
      color: theme.normal.red
      anchors.horizontalCenter: parent.horizontalCenter
      Text {
        text: "📶"
        font.pixelSize: ScalerService.s(40)
        anchors.centerIn: parent
      }
    }

    Text {
      text: lang?.wifi?.disabled || "WiFi đang tắt"
      font.pixelSize: ScalerService.s(18)
      color: theme.primary.foreground
      font.family: "ComicShannsMono Nerd Font"
    }

    Text {
      text: lang?.wifi?.turn_on || "Bật WiFi để xem mạng khả dụng"
      font.pixelSize: ScalerService.s(14)
      color: theme.primary.dim_foreground
      font.family: "ComicShannsMono Nerd Font"
    }
  }
}
