import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.components
import qs.services

Rectangle {
  id: root
  Layout.fillWidth: true
  Layout.preferredHeight: ScalerService.s(120)

  height: ScalerService.s(30)
  color: theme.primary.dim_background
  signal fileOpened(url fileUrl)
  property var selectedFile: ""

  radius: ScalerService.s(16)
  border.width: ScalerService.s(1)
  border.color: theme.primary.foreground

  ColumnLayout{
    anchors.fill: parent
    anchors.margins: ScalerService.s(20)
    RowLayout {
      Layout.fillWidth: true
      Layout.preferredHeight: parent.width/2
      anchors.margins: ScalerService.s(5)

      CustomText {
        Layout.preferredWidth: parent.width * 0.2
        name: "File open: "
        size: "small"
      }
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: ScalerService.s(35)
        radius: ScalerService.s(12)
        color: theme.primary.dim_background
        border.color: theme.button.border
        border.width: ScalerService.s(2)
        RowLayout {
          anchors.fill: parent
          anchors.margins: ScalerService.s(2)
          anchors.leftMargin: ScalerService.s(10)
          spacing: ScalerService.s(8)

          TextField {
            Layout.fillWidth: true
            placeholderText: "Tìm kiếm thư mục..."
            text: root.selectedFile.toString().replace("file://", "")
            palette.text: theme.primary.foreground       // màu chữ chính
            palette.placeholderText: theme.primary.dim_foreground  // sửa thành dim_foreground
            font.pixelSize: ScalerService.s(14)
            font.family: "ComicShannsMono Nerd Font"
            background: Rectangle {
              color: "transparent"
            }
            selectByMouse: true

            onTextChanged: {
              // restart debounce timer mỗi khi gõ
            }

            Keys.onReturnPressed: {
              // gọi ngay (bỏ qua debounce) khi nhấn Enter

            }

            Keys.onEscapePressed: {
              // Khi nhấn Escape trong search field, đóng panel
            }

            // Helper function để tìm LauncherPanel
          }
        }

      }
      ButtonText{
        Layout.preferredWidth: ScalerService.s(100)
        Layout.preferredHeight: ScalerService.s(35)
        radius: ScalerService.s(12)
        border.width: ScalerService.s(2)
        name: "Open"
        size: "small"
        onClicked: {
          root.fileOpened(root.selectedFile)
        }
      }
    }
    RowLayout {
      Layout.fillWidth: true
      Layout.preferredHeight: parent.width/2
      anchors.margins: ScalerService.s(5)

      CustomText {
        Layout.preferredWidth: parent.width * 0.2
        name: "File of types: "
        size: "small"
      }
      Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: ScalerService.s(35)
        radius: ScalerService.s(12)
        color: theme.primary.dim_background
        border.color: theme.button.border
        border.width: ScalerService.s(2)
        RowLayout {
          anchors.fill: parent
          anchors.margins: ScalerService.s(2)
          anchors.leftMargin: ScalerService.s(10)
          spacing: ScalerService.s(8)

          TextField {
            Layout.fillWidth: true
            placeholderText: "Tìm kiếm thư mục..."
            palette.text: theme.primary.foreground       // màu chữ chính
            palette.placeholderText: theme.primary.dim_foreground  // sửa thành dim_foreground
            font.pixelSize: ScalerService.s(14)
            font.family: "ComicShannsMono Nerd Font"
            background: Rectangle {
              color: "transparent"
            }
            selectByMouse: true

            onTextChanged: {
              // restart debounce timer mỗi khi gõ
            }

            Keys.onReturnPressed: {
              // gọi ngay (bỏ qua debounce) khi nhấn Enter

            }

            Keys.onEscapePressed: {
              // Khi nhấn Escape trong search field, đóng panel
            }

            // Helper function để tìm LauncherPanel
          }
        }

      }
      ButtonText{
        Layout.preferredWidth: ScalerService.s(100)
        Layout.preferredHeight: ScalerService.s(35)
        radius: ScalerService.s(12)
        border.width: ScalerService.s(2)
        name: "Cancel"
        size: "small"
      }
    }
  }
}
