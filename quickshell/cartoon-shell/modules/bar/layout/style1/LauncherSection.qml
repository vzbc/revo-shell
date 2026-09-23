import QtQuick
import QtQuick.Layouts
import Quickshell
import QtQuick.Effects
import Quickshell.Io
import qs.services
import qs.commons
import qs.components

Rectangle {
  id: root
  anchors.centerIn: parent
  property real animationProgress: 0
  implicitWidth: root.animationProgress > 0 ? parent.width : 0
  implicitHeight: root.animationProgress > 0 ? parent.height : 0
  Behavior on implicitHeight {
    NumberAnimation {
      id: heightAnim
      duration: 500
      easing.type: Easing.OutCubic
    }
  }
  Behavior on implicitWidth {
    NumberAnimation {
      id: widthAnim
      duration: 500
      easing.type: Easing.OutCubic
    }
  }
  color: theme.primary.background
  radius: ScalerService.s(Settings.appearance.radius2)
  border.color: theme.button.border
  border.width: Settings.appearance.enableBorder ? ScalerService.s(3) : 0
  property bool isVertical: Settings.bar.position === "left" || Settings.bar.position === "right"
  RowLayout {
    anchors.centerIn: parent
    spacing: ScalerService.s(15)

    ButtonIconImage{
      path: "launcher/dashboard.png"
      size: "large"
      onClicked: VisibleService.togglePanel("launcher");
      opacity: root.animationProgress > 0.1 ? 1 : 0
    }
  }
}
