import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.Mpris
import qs.services
import qs.commons
import qs.components
import "." as Com

PanelWindow {
  id: root

  // Music data
  property int position: 0
  property int duration: 0

  property real animationProgress: 0
  SequentialAnimation on animationProgress {
    running: true

    NumberAnimation {
      from: 0
      to: 2
      duration: 1000
      easing.type: Easing.Linear
    }
  }

  implicitWidth: ScalerService.s(500)
  implicitHeight: ScalerService.s(500)
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

  // CavaService instance
  CavaService {
    id: cavaService
  }

  // Start cava when panel opens
  onVisibleChanged: {
    if (visible) {
      cavaService.open();
    } else {
      cavaService.close();
    }
  }

  // Main content
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
    radius: ScalerService.s(Settings.appearance.radius1)
    border.width: Settings.appearance.enableBorder ? ScalerService.s(3) : 0
    color: theme.primary.background
    border.color: theme.button.border

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

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: ScalerService.s(20)
      spacing: ScalerService.s(16)

      // Header
      Com.MusicHeader {
        Layout.fillWidth: true
        Layout.preferredHeight: ScalerService.s(40)
        animationProgress : root.animationProgress
      }

      // Album art and info section
      RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: ScalerService.s(180)
        spacing: ScalerService.s(20)

        // Album art
        Com.AlbumArt {
          animationProgress : root.animationProgress
        }

        // Song info
        Com.SongInfo {
          animationProgress : root.animationProgress
        }
      }

      // Controls
      Com.MusicControls {
        animationProgress : root.animationProgress
      }
      Com.MusicProgressBar{
        animationProgress : root.animationProgress
      }

      // Cava Visualizer
      Com.CavaVisualizer {
        cavaService: cavaService
        animationProgress : root.animationProgress
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
