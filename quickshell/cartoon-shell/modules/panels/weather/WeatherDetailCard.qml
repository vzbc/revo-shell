import QtQuick
import QtQuick.Layouts
import qs.services
import qs.commons
import qs.components

Rectangle {
  id: root
  property string icon: ""
  property string label: ""
  property string value: ""
  property real animationProgress: 0

  Layout.preferredWidth: ScalerService.s(150)
  Layout.preferredHeight: ScalerService.s(80)
  radius: ScalerService.s(Settings.appearance.radius3)
  color: Qt.alpha(theme.button.background,0.4)

  RowLayout {
    anchors.fill: parent
    anchors.margins: ScalerService.s(12)
    spacing: ScalerService.s(8)

    IconText {
      name: root.icon
      textColor: theme.button.text
    }

    ColumnLayout {
      spacing: 0

      CustomText {
        name: root.label
        size: "xs"
        textColor: theme.primary.dim_foreground
      }

      CustomText {
        name: root.value
        size: "small"
        isBold: true
      }
    }
  }
}
