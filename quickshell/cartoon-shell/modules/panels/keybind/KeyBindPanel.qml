import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs.services
import qs.commons
import "." as Com
import qs.components

PanelWindow {
  id: root

  property real animationProgress: 0
  SequentialAnimation on animationProgress {
    running: true

    NumberAnimation {
      from: 0
      to: 1
      duration: 1000
      easing.type: Easing.Linear
    }
  }

  implicitWidth: ScalerService.s(1500)
  implicitHeight: ScalerService.s(900)

  exclusiveZone: 0
  color: "transparent"

  // Background layer với các hình tròn di chuyển

  // Main content layer
  Rectangle {
    anchors.centerIn: parent
    implicitWidth: root.animationProgress > 0 ? parent.width : 0
    implicitHeight: root.animationProgress > 0 ? parent.height : 0

    color: theme.primary.background
    border.color: theme.button.border
    radius: ScalerService.s(Settings.appearance.radius1)
    border.width: Settings.appearance.enableBorder ? ScalerService.s(3) : 0

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
    Loader {
      anchors.fill: parent

      active: !heightAnim.running && !widthAnim.running

      sourceComponent: FloatingCircles {
        circleColor: theme.button.text
        anchors.fill: parent
        circleCount: 5
        minOpacity: 0.02
        maxOpacity: 0.04
      }
    }

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: ScalerService.s(20)
      spacing: ScalerService.s(16)
      Com.KeyBindHeader{
        Layout.fillWidth: true
        Layout.preferredHeight: ScalerService.s(40)
      }
      Com.KeyBindDisplay{
        Layout.fillWidth: true
        Layout.fillHeight: true
      }
    }

    Loader {
      anchors.fill: parent

      active: !heightAnim.running && !widthAnim.running

      sourceComponent: StarField {
        starCount: 10
        shootingStarCount: 2
      }
    }
  }
}
