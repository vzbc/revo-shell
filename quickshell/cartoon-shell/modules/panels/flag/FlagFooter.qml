import QtQuick
import QtQuick.Layouts
import qs.services
import qs.commons
import qs.components

ColumnLayout {
  id: flagFooter

  property string selectedFlag: ""
  property real animationProgress: 0

  Rectangle {
    Layout.preferredHeight: 1
    Layout.fillWidth: true
    opacity: root.animationProgress > 0.7 ? 0.5 : 0

    Behavior on opacity {
      NumberAnimation {
        duration: 200
      }
    }
    height: 1
    color: theme.primary.foreground
  }

  CustomText {
    name: `Selected: ${Settings.appearance.countryFlag}`
    font.italic: true
    size: "small"
    color: theme.primary.dim_foreground
    Layout.alignment: Qt.AlignHCenter
    opacity: root.animationProgress > 0.7 ? 1 : 0
    Behavior on opacity {
      NumberAnimation {
        duration: 200
      }
    }
  }
}
