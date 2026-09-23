import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services

Item {
  id: root

  property string name: ""
  property string value: ""

  implicitWidth: contentRamUsed.implicitWidth + ScalerService.s(20)
  implicitHeight: contentRamUsed.implicitHeight

  Layout.preferredWidth: implicitWidth
  Layout.fillHeight: true

  ColumnLayout {
    id: contentRamUsed

    anchors.centerIn: parent
    spacing: ScalerService.s(2)

    CustomText {
      name: root.name
      size: "small"
      isBold: true
    }

    CustomText {
      name: root.value
      size: "small"
      isBold: true
      textColor: theme.button.text
    }
  }
}
