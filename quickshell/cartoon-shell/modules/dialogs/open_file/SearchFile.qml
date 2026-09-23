import QtQuick
import qs.components
import QtQuick.Layouts
import QtQuick.Controls
import qs.services

Rectangle {
  id: root
  Layout.fillWidth: true
  Layout.fillHeight: true
  radius: ScalerService.s(12)
  color: theme.primary.dim_background
  border.color: theme.button.border
  property string currentPath : ""
  border.width: ScalerService.s(2)
  RowLayout {
    anchors.fill: parent
    anchors.margins: ScalerService.s(2)
    anchors.leftMargin: ScalerService.s(10)
    spacing: ScalerService.s(8)

    IconImage {
      path: "launcher/search.png"
      size: "small"
    }

    TextField {
      id: searchField
      Layout.fillWidth: true
      placeholderText: "Tìm kiếm thư mục..."
      palette.text: theme.primary.foreground       // màu chữ chính
      palette.placeholderText: theme.primary.dim_foreground  // sửa thành dim_foreground
      font.pixelSize: ScalerService.s(14)
      font.family: "ComicShannsMono Nerd Font"
      text: root.currentPath.toString().replace("file://", "")
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
