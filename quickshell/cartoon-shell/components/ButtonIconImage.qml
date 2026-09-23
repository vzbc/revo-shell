import QtQuick
import Quickshell
import QtQuick.Layouts
import qs.commons
import qs.services

Item {
  id: root

  property string path: ""
  property string size: "normal"  // xs | small | normal | large | xl
  property bool isVertical: Settings.bar.position === "left" || Settings.bar.position === "right"

  // Forward tín hiệu ra ngoài
  signal clicked
  signal wheel(var event)

  implicitWidth: iconSize
  implicitHeight: iconSize

  readonly property int iconSize: {
    switch (size) {
      case "xs":
      return ScalerService.s(12);
      case "small":
      return ScalerService.s(26);
      case "normal":
      return ScalerService.s(32);
      case "large":
      return ScalerService.s(40);
      case "xl":
      return ScalerService.s(50);
      default:
      return ScalerService.s(32);
    }
  }

  Behavior on scale {
    NumberAnimation {
      duration: 100
    }
  }

  Image {
    id: iconImage
    property bool hovered: false

    anchors.fill: parent

    source: Directories.assetsPath + "/" + root.path
    fillMode: Image.PreserveAspectFit
    smooth: true
    mipmap: true

    scale: hovered ? 1.2 : 1.0

    Behavior on scale {
      NumberAnimation {
        duration: 150
        easing.type: Easing.OutQuad
      }
    }

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor

      onEntered: iconImage.hovered = true
      onExited: iconImage.hovered = false

      onClicked: {
        root.clicked();
        SoundService.playSound("pick");
      }

      onWheel: event => {
        root.wheel(event);
      }
    }
  }
}
