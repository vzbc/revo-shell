// CavaVisualizer.qml
import QtQuick
import QtQuick.Layouts
import qs.services

Rectangle {
  id: visualizer
  Layout.fillWidth: true
  Layout.fillHeight: true
  Layout.minimumHeight: ScalerService.s(100)
  radius: ScalerService.s(12)
  color: Qt.alpha(theme.primary.dim_background, 0.3)

  clip: true
  property real animationProgress: 0

  property var cavaService: null
  opacity: root.animationProgress > 0.7 ? 1 : 0
  Behavior on opacity {
    NumberAnimation {
      duration: 200
    }
  }

  Row {
    id: cavaRow
    anchors.fill: parent
    anchors.margins: ScalerService.s(8)
    spacing: ScalerService.s(2)

    Repeater {
      model: cavaService?.values.length ?? 0

      Rectangle {
        opacity: 0

        SequentialAnimation on opacity {
          running: root.animationProgress > 1.2

          PauseAnimation {
            duration: index * 10
          }

          NumberAnimation {
            to: 1
            duration: 200
            easing.type: Easing.OutCubic
          }
        }
        width: cavaService && cavaService.values.length > 0
        ? (cavaRow.width - (cavaService.values.length - 1) * ScalerService.s(2)) / cavaService.values.length
        : 0
        height: cavaService ? Math.max(ScalerService.s(4), (cavaService.values[index] / 100) * cavaRow.height) : 0
        anchors.bottom: parent.bottom
        radius: ScalerService.s(2)
        color: {
          if (!cavaService) return theme.normal.blue;
          var ratio = cavaService.values[index] / 100;
          if (ratio < 0.3) return theme.normal.blue;
          if (ratio < 0.5) return theme.normal.cyan;
          if (ratio < 0.7) return theme.normal.green;
          if (ratio < 0.85) return theme.normal.yellow;
          return theme.normal.red;
        }

        Behavior on height { NumberAnimation { duration: 50 } }
        Behavior on color { ColorAnimation { duration: 100 } }
      }
    }
  }

  // No music playing overlay
  Rectangle {
    anchors.fill: parent
    color: theme.primary.dim_background
    opacity: 0.8
    visible: !cavaService?.isRunning || !Players.mprisPlayer?.isPlaying

    Text {
      anchors.centerIn: parent
      text: !Players.mprisPlayer?.isPlaying
      ? (lang.musicPanel?.notPlaying || "Not playing")
      : (lang.musicPanel?.loading || "Loading...")
      font.family: "ComicShannsMono Nerd Font"
      font.pixelSize: ScalerService.s(14)
      color: theme.primary.dim_foreground
    }
  }
}
