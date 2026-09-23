// components/Settings/AudioSettings.qml
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
      spacing: ScalerService.s(20)

      // Tiêu đề
      RowLayout {
        Layout.fillWidth: true
        spacing: ScalerService.s(10)

        // Button Nâng cao ở góc trái

        Item {
          Layout.fillWidth: true
        }

        // Tiêu đề (được đẩy sang bên phải)
        Text {
          text: "Audio Settings"
          color: theme.primary.foreground
          font.pixelSize: ScalerService.s(24)
          font.bold: true
          font.family: "ComicShannsMono Nerd Font"
        }
      }

      Rectangle {
        Layout.fillWidth: true
        height: ScalerService.s(1)
        color: theme.primary.foreground
      }
    }
  }
}
