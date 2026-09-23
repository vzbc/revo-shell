import QtQuick
import qs.services
import qs.commons

Text {
  property string name: "undefined"

  property string size: "normal"

  property bool isBold: false
  property color textColor: theme.primary.foreground
  property string fontFamily: Settings.appearance.font
  readonly property var sizeMap: ({
      "4sx": 4,
      "2xs": 8,
      "xs": 12,
      "small": 16,
      "normal": 24,
      "large": 32,
      "xl": 40,
      "2xl": 48,
      "3xl": 70,
      "4xl": 100
  })
  Behavior on opacity {
    NumberAnimation {
      duration: 200
    }
  }
  Behavior on font.bold {
    PropertyAnimation {
      duration: 150
    }
  }
  Behavior on scale {
    NumberAnimation {
      duration: 200
    }
  }
  Behavior on font.pixelSize {
    ColorAnimation {
      duration: 200
    }
  }

  Behavior on rotation {
    NumberAnimation {
      duration: 500
    }
  }

  text: name
  color: textColor

  font.family: fontFamily
  font.bold: isBold

  font.pixelSize: ScalerService.s(sizeMap[size] ?? 32)
}
