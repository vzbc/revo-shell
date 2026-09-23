import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.commons
import qs.components
import "." as Com

PanelWindow {
  id: root

  property string selectedFlag: Settings.appearance.countryFlag
  property real animationProgress: 0

  SequentialAnimation on animationProgress {
    running: true

    NumberAnimation {
      from: 0
      to: 1
      duration: 500
      easing.type: Easing.Linear
    }
  }

  implicitWidth: ScalerService.s(600)
  implicitHeight: ScalerService.s(380)

  property var flagList: [
  { name: "britain", displayName: "Britain" },
  { name: "bulgaria", displayName: "Bulgaria" },
  { name: "china", displayName: "China" },
  { name: "czech", displayName: "Czech" },
  { name: "denmark", displayName: "Denmark" },
  { name: "finland", displayName: "Finland" },
  { name: "france", displayName: "France" },
  { name: "german", displayName: "Germany" },
  { name: "greece", displayName: "Greece" },
  { name: "hungary", displayName: "Hungary" },
  { name: "india", displayName: "India" },
  { name: "indonesia", displayName: "Indonesia" },
  { name: "israel", displayName: "Israel" },
  { name: "italy", displayName: "Italy" },
  { name: "japan", displayName: "Japan" },
  { name: "korea", displayName: "Korea" },
  { name: "netherlands", displayName: "Netherlands" },
  { name: "norway", displayName: "Norway" },
  { name: "poland", displayName: "Poland" },
  { name: "portugal", displayName: "Portugal" },
  { name: "romania", displayName: "Romania" },
  { name: "russia", displayName: "Russia" },
  { name: "saudi_arabia", displayName: "Saudi Arabia" },
  { name: "slovakia", displayName: "Slovakia" },
  { name: "spain", displayName: "Spain" },
  { name: "sweden", displayName: "Sweden" },
  { name: "thailand", displayName: "Thailand" },
  { name: "turkey", displayName: "Turkey" },
  { name: "ukraine", displayName: "Ukraine" },
  { name: "vietnam", displayName: "Vietnam" }
  ]

  anchors {
    top: Settings.bar.position === "top"
    bottom: Settings.bar.position === "bottom"
    left: Settings.bar.position === "top" || Settings.bar.position === "bottom" || Settings.bar.position === "left"
    right: Settings.bar.position === "right"
  }

  margins {
    top: Settings.bar.position === "top" ? ScalerService.s(10) : 0
    bottom: Settings.bar.position === "bottom" ? ScalerService.s(10) : 0
    left: (Settings.bar.position === "top" || Settings.bar.position === "bottom") ? ScalerService.s(720) : ScalerService.s(10)
    right: Settings.bar.position === "right" ? ScalerService.s(10) : 0
  }

  exclusiveZone: 0
  color: "transparent"

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
        circleCount: 2
        minOpacity: 0.02
        maxOpacity: 0.04
      }
    }
    color: theme.primary.background
    border.color: theme.button.border
    radius: ScalerService.s(Settings.appearance.radius1)
    border.width: Settings.appearance.enableBorder ? ScalerService.s(3) : 0

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: ScalerService.s(20)
      spacing: ScalerService.s(15)

      Com.FlagHeader {
        animationProgress: root.animationProgress
        Layout.fillWidth: true
        Layout.preferredHeight: ScalerService.s(40)
      }

      Com.FlagGrid {
        Layout.fillWidth: true
        Layout.fillHeight: true
        flagList: root.flagList
        selectedFlag: root.selectedFlag
        animationProgress: root.animationProgress
      }

      Com.FlagFooter {
        selectedFlag: root.selectedFlag
        animationProgress: root.animationProgress
      }
    }
    Loader {
      anchors.fill: parent

      active: !heightAnim.running && !widthAnim.running

      sourceComponent:     StarField {
        starCount: 10
        shootingStarCount: 2
      }
    }
  }
}
