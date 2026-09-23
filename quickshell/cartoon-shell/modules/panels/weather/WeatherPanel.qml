import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.commons
import qs.components
import "." as Com

PanelWindow {
  id: root

  property real animationProgress: 0
  property bool showWeatherSettings: false  // Property để quản lý trạng thái settings

  SequentialAnimation on animationProgress {
    running: true
    NumberAnimation {
      from: 0
      to: 2
      duration: 1000
      easing.type: Easing.Linear
    }
  }

  implicitWidth: ScalerService.s(1200)
  implicitHeight: ScalerService.s(800)
  focusable: true

  anchors {
    top: Settings.bar.position === "top"
    bottom: Settings.bar.position === "bottom"
    left: Settings.bar.position === "top" || Settings.bar.position === "bottom" || Settings.bar.position === "left"
    right: Settings.bar.position === "right"
  }

  margins {
    top: Settings.bar.position === "top" ? ScalerService.s(10) : 0
    bottom: Settings.bar.position === "bottom" ? ScalerService.s(10) : 0
    left: (Settings.bar.position === "top" || Settings.bar.position === "bottom") ? ScalerService.s(400) : ScalerService.s(10)
    right: Settings.bar.position === "right" ? ScalerService.s(10) : 0
  }

  exclusiveZone: 0
  color: "transparent"

  // Main UI
  Rectangle {
    anchors.centerIn: parent
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

    Loader {
      anchors.fill: parent
      active: !heightAnim.running && !widthAnim.running
      sourceComponent: FloatingCircles {
        circleColor: theme.button.text
        anchors.fill: parent
        circleCount: 4
      }
    }

    border.color: theme.button.border
    radius: ScalerService.s(Settings.appearance.radius1)
    border.width: Settings.appearance.enableBorder ? ScalerService.s(3) : 0
    color: theme.primary.background

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: ScalerService.s(20)
      spacing: ScalerService.s(20)

      // Weather Header với kết nối signal
      Com.WeatherHeader {
        id: weatherHeader
        Layout.fillWidth: true
        Layout.preferredHeight: ScalerService.s(40)

        // Kết nối signal để thay đổi trạng thái
        onShowSettingsChanged: {
          root.showWeatherSettings = showSettings
          if (weatherMainInfo) {
            weatherMainInfo.showSettings = showSettings
          }
        }
      }

      // Weather Main Info
      Com.WeatherMainInfo {
        id: weatherMainInfo
        Layout.fillWidth: true
        Layout.fillHeight: true
        animationProgress: root.animationProgress
        showSettings: root.showWeatherSettings  // Bind property
      }
    }

    Loader {
      anchors.fill: parent
      active: !heightAnim.running && !widthAnim.running
      sourceComponent: StarField {
        starCount: 20
        shootingStarCount: 4
      }
    }
  }
}
