import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.commons
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import qs.components
import qs.services

Scope {
  id: root

  property var theme: ThemeService.theme
  property var lang: LanguageService.translations
  property bool shouldShowOsd: false
  property real currentVolume: Pipewire.defaultAudioSink?.audio.volume ?? 0
  property bool isMuted: Pipewire.defaultAudioSink?.audio.mute ?? false

  PwObjectTracker {
    objects: [Pipewire.defaultAudioSink]
  }

  Connections {
    target: Pipewire.defaultAudioSink.audio ?? null

    function onVolumeChanged() {
      root.shouldShowOsd = true;
      hideTimer.restart();
    }
  }

  Timer {
    id: hideTimer
    interval: 1000
    onTriggered: root.shouldShowOsd = false
  }

  function lerpColor(a, b, t) {
    const ar = parseInt(a.slice(1,3),16), ag = parseInt(a.slice(3,5),16), ab = parseInt(a.slice(5,7),16);
    const br = parseInt(b.slice(1,3),16), bg = parseInt(b.slice(3,5),16), bb = parseInt(b.slice(5,7),16);
    const r  = Math.round(ar + (br-ar)*t);
    const g  = Math.round(ag + (bg-ag)*t);
    const bl = Math.round(ab + (bb-ab)*t);
    return `#${r.toString(16).padStart(2,'0')}${g.toString(16).padStart(2,'0')}${bl.toString(16).padStart(2,'0')}`;
  }

  function barColor() {
    if (isMuted) return theme.normal.black;
    const v = Math.min(currentVolume / 1.5, 1.0);
    if (v < 0.20) return lerpColor(theme.normal.blue, theme.normal.cyan, v / 0.20);
    if (v < 0.40) return lerpColor(theme.normal.cyan, theme.normal.green, (v-0.20) / 0.20);
    if (v < 0.58) return lerpColor(theme.normal.green, theme.normal.yellow, (v-0.40) / 0.18);
    if (v < 0.73) return lerpColor(theme.normal.yellow, theme.normal.red, (v-0.58) / 0.15);
    if (v < 0.88) return lerpColor(theme.normal.red, theme.bright.red, (v-0.73) / 0.15);
    return lerpColor(theme.bright.red, theme.bright.red, (v-0.88) / 0.12);
  }

  LazyLoader {
    active: root.shouldShowOsd

    PanelWindow {
      anchors {
        bottom: true
      }
      margins {
        bottom: ScalerService.s(120)
      }
      exclusiveZone: 0
      implicitWidth: ScalerService.s(280)
      implicitHeight: ScalerService.s(100)
      color: "transparent"
      mask: Region {}

      Rectangle {
        anchors.fill: parent
        border.color: theme.button.border
        radius: ScalerService.s(Settings.appearance.radius1)
        border.width: Settings.appearance.enableBorder ? ScalerService.s(3) : 0
        color: theme.primary.background

        ColumnLayout {
          anchors {
            fill: parent
            leftMargin: ScalerService.s(15)
            rightMargin: ScalerService.s(15)
            bottomMargin: ScalerService.s(15)
          }
          spacing: ScalerService.s(12)

          RowLayout {
            IconImage {
              path: root.getVolumeIcon()
              size: "large"
            }
            CustomText {
              name: Math.round(currentVolume * 100) + "%"
              color:  currentVolume > 1.0 ? theme.normal.red : theme.primary.foreground
              size: "large"
              isBold: true
              Behavior on color {
                ColorAnimation { duration: 150 }
              }
            }
            Rectangle {
              color: "transparent"
              Layout.fillWidth: true
              Layout.fillHeight: true
              CustomText {
                name: " " + (lang?.volume?.title || "Âm thanh")
                anchors.margins: ScalerService.s(10)
                anchors.top: parent.top
                anchors.right: parent.right
              }
            }
          }

          // Thanh volume
          ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: ScalerService.s(4)

            Rectangle {
              Layout.fillWidth: true
              Layout.preferredHeight: ScalerService.s(20)
              radius: ScalerService.s(20)
              color: theme.primary.dim_background
              Rectangle {
                anchors {
                  left: parent.left
                  top: parent.top
                  bottom: parent.bottom
                }
                width: parent.width * Math.min(currentVolume / 1.5, 1.0)
                radius: parent.radius
                color: root.barColor()
                Behavior on width {
                  NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                }
                Behavior on color {
                  ColorAnimation { duration: 100 }
                }
              }

              // 100% marker
              Rectangle {
                visible: currentVolume > 1.0
                x: parent.width * (1.0 / 1.5) - width / 2
                width: ScalerService.s(3)
                height: parent.height
                radius: ScalerService.s(1.5)
                color: "white"
                opacity: 0.6
              }
            }
          }
        }
      }
    }
  }

  function getVolumeIcon() {
    if (isMuted || currentVolume == 0)
    return "volume/volume_0.png";
    if (currentVolume <= 0.25)
    return "volume/volume_1.png";
    if (currentVolume <= 0.50)
    return "volume/volume_2.png";
    if (currentVolume <= 0.75)
    return "volume/volume_3.png";
    if (currentVolume <= 1)
    return "volume/volume_4.png";
    return "volume/volume_5.png";
  }
}
