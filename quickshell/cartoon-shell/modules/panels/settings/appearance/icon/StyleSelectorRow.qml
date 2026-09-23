import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

RowLayout {
  id: root

  property string title: ""
  property string systemName: ""
  property var styleModel: 0  // Số lượng style hoặc mảng dữ liệu
  property int currentStyle: 0

  CustomText {
    name: root.title
  }

  Item { Layout.fillWidth: true }

  GridLayout {
    columns: 4
    rowSpacing: ScalerService.s(12)
    columnSpacing: ScalerService.s(12)

    Repeater {
      model: root.styleModel

      delegate: ButtonText {
        required property int index

        property int styleIndex: index + 1
        property bool selected: root.currentStyle === styleIndex

        Layout.preferredHeight: ScalerService.s(40)
        Layout.preferredWidth: ScalerService.s(80)

        name: `Style ${index+1}`
        size: "xs"

        color: selected
        ? theme.button.background_select
        : theme.button.background

        textColor: selected
        ? theme.button.text
        : theme.primary.dim_foreground

        border.color: selected
        ? theme.button.border_select
        : theme.primary.foreground

        onClicked: {
          root.changeStyle(styleIndex)
        }
      }
    }
  }

  function changeStyle(styleIndex) {
    // Gọi hàm changeStyle từ component cha
    if (root.onStyleChanged) {
      root.onStyleChanged(styleIndex)
    }
  }

  property var onStyleChanged: null
}
