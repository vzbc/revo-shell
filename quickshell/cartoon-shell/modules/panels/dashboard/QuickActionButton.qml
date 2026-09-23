import QtQuick
import QtQuick.Controls.Fusion
import QtQuick.Layouts
import qs.services
import qs.commons

Rectangle {
  id: root
  property string icon: ""
  property color iconColor: "white"

  color: theme.primary.background
  radius: ScalerService.s(Settings.appearance.radius1)
  border.width: Settings.appearance.enableBorder ? ScalerService.s(3) : 0
  border.color: theme.button.border
  Behavior on opacity {
    NumberAnimation {
      duration: 200
    }
  }

  Image {
    id: iconImage
    source: root.icon
    anchors.centerIn: parent
    width: ScalerService.s(50)
    height: ScalerService.s(50)
    fillMode: Image.PreserveAspectFit
    smooth: true
    visible: status === Image.Ready

    // Debug placeholder
    Text {
      anchors.centerIn: parent
      text: "?"
      color: theme.primary.dim_foreground
      font.pixelSize: ScalerService.s(24)
      font.family: "ComicShannsMono Nerd Font"
      visible: parent.status !== Image.Ready
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
  }
}
