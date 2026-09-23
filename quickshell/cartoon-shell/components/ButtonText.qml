import QtQuick
import qs.services

Rectangle {
  id: root

  // Properties
  property string name: "undefined"
  property string size: "normal"
  property bool isBold: false
  property bool hovered: false
  property color textColor: theme.button.text
  property string fontFamily: "ComicShannsMono Nerd Font"

  radius: ScalerService.s(8)

  border.width: ScalerService.s(1)
  border.color: root.hovered ? theme.button.border_select : theme.button.border

  color: root.hovered ? theme.button.background_select : theme.button.background

  // Fixed size based on the size property (no hover effect)
  implicitWidth: iconText.width + ScalerService.s(5)
  implicitHeight: iconText.height

  Text {
    id: iconText
    anchors.centerIn: parent

    // Font configuration
    font.family: root.fontFamily
    font.bold: root.isBold
    font.pixelSize: {
      switch (root.size) {
        case "xs": return ScalerService.s(16)
        case "small": return ScalerService.s(22)
        case "normal": return ScalerService.s(28)
        case "large": return ScalerService.s(52)
        case "xl": return ScalerService.s(64)
        default: return ScalerService.s(40)
      }
    }

    // Bind to root properties
    text: root.name
    color: root.hovered ? Qt.lighter(root.textColor, 1.2) : root.textColor

    // Smooth animation for color only
    Behavior on color {
      ColorAnimation { duration: 150 }
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    onEntered: root.hovered = true
    onExited: root.hovered = false

    onClicked: {
      root.clicked();
      SoundService.playSound("pick");
    }
    onWheel: event => {
      root.wheel(event);
    }
  }

  signal wheel(var event)
  signal clicked()
}
