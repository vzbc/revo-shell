import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Fusion
import Quickshell.Services.Mpris
import Quickshell.Widgets
import QtQuick.Controls
import Quickshell.Io
import qs.services
import qs.components
import qs.commons

Item {
  id: root
  property var mprisPlayer: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
  property string currentSong: "No song playing"
  property string currentArtist: "Unknown Artist"
  property real animationProgress: 0
  property string albumArt: ""
  property int position: 0
  property int duration: 0

  Layout.preferredHeight: ScalerService.s(220)
  Layout.fillWidth: true

  function formatTime(ms) {
    if (!ms || ms <= 0)
    return "0:00"

    var totalSeconds = Math.floor(ms)
    var minutes = Math.floor(totalSeconds / 60)
    var seconds = totalSeconds % 60

    return minutes + ":" + (seconds < 10 ? "0" + seconds : seconds)
  }

  Rectangle {
    anchors.centerIn: parent
    implicitWidth: root.animationProgress > 0.3 ? parent.width : 0
    implicitHeight: root.animationProgress > 0.3 ? parent.height : 0
    clip: true
    color: theme.primary.background
    radius: ScalerService.s(Settings.appearance.radius1)
    border.width: Settings.appearance.enableBorder ? ScalerService.s(3) : 0
    border.color: theme.button.border
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
        circleCount: 1
      }
    }
    RowLayout {
      anchors.fill: parent
      anchors.margins: ScalerService.s(20)
      spacing: ScalerService.s(25)

      // Album Art (Circular with rotation) - Left Side
      Item {
        Layout.preferredWidth: ScalerService.s(160)
        Layout.preferredHeight: ScalerService.s(160)

        // Rotating container
        Item {
          id: rotatingContainer
          anchors.fill: parent

          RotationAnimation on rotation {
            from: 0
            to: 360
            duration: 10000
            loops: Animation.Infinite
            running: root.mprisPlayer.isPlaying
          }

          ClippingRectangle {
            id: albumArtContainer
            anchors.fill: parent
            radius: width / 2
            color: theme.primary.dim_background
            border.color: theme.normal.black
            border.width: ScalerService.s(3)
            opacity: root.animationProgress > 0.75 ? 1 : 0
            Behavior on opacity {
              NumberAnimation {
                duration: 200
              }
            }

            Image {
              id: albumImage
              anchors.fill: parent
              source: Players.getArtUrl(Players.mprisPlayer)

              fillMode: Image.PreserveAspectCrop
              visible: status === Image.Ready
              cache: false
              asynchronous: true
              smooth: true
            }

            // Placeholder when no album art
            Text {
              anchors.centerIn: parent
              text: "No Art"
              font.family: "ComicShannsMono Nerd Font"
              font.pixelSize: ScalerService.s(14)
              color: theme.primary.dim_foreground
              visible: albumImage.status !== Image.Ready
            }
          }
        }
      }

      // Track Info & Controls - Right Side
      ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: ScalerService.s(8)

        // Song title with marquee
        Item {
          Layout.fillWidth: true
          Layout.preferredHeight: songText.height
          clip: true

          Text {
            id: songText
            opacity: root.animationProgress > 0.8 ? 1 : 0
            Behavior on opacity {
              NumberAnimation {
                duration: 200
              }
            }
            text: root.mprisPlayer ? (root.mprisPlayer.trackTitle || "No song playing") : "No song playing"
            font.family: "ComicShannsMono Nerd Font"
            font.pixelSize: ScalerService.s(20)
            font.bold: true
            color: theme.primary.foreground

            property bool needsMarquee: width > parent.width
            x: 0

            SequentialAnimation on x {
              running: songText.needsMarquee && root.visible
              loops: Animation.Infinite

              PauseAnimation { duration: 2000 }
              NumberAnimation {
                to: -(songText.width - songText.parent.width)
                duration: Math.max(2000, (songText.width - songText.parent.width) * 20)
                easing.type: Easing.Linear
              }
              PauseAnimation { duration: 2000 }
              NumberAnimation {
                to: 0
                duration: Math.max(2000, (songText.width - songText.parent.width) * 20)
                easing.type: Easing.Linear
              }
            }
          }
        }

        // Artist name
        CustomText{
          name: root.mprisPlayer ? (root.mprisPlayer.trackArtist || "Unknown Artist") : "Unknown Artist"
          opacity: root.animationProgress > 0.85 ? 1 : 0
          Behavior on opacity {
            NumberAnimation {
              duration: 200
            }
          }
          elide: Text.ElideRight
          size: "small"
          textColor: theme.primary.dim_foreground
        }

        Item { Layout.fillHeight: true }

        // Controls Row
        RowLayout {
          Layout.fillWidth: true
          Layout.preferredHeight: ScalerService.s(48)
          spacing: ScalerService.s(12)

          Item { Layout.fillWidth: true }

          // Previous button
          Rectangle {
            Layout.preferredWidth: ScalerService.s(48)
            Layout.preferredHeight: ScalerService.s(48)
            radius: ScalerService.s(24)
            color: prevArea.containsMouse ? theme.button.text : theme.button.background
            opacity: root.animationProgress > 0.5 ? 1 : 0
            Behavior on opacity {
              NumberAnimation {
                duration: 200
              }
            }

            IconText {
              opacity: root.animationProgress > 0.88 ? 1 : 0
              Behavior on opacity {
                NumberAnimation {
                  duration: 200
                }
              }
              anchors.centerIn: parent
              name: "skip_previous"
              size: "large"
            }

            MouseArea {
              id: prevArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: Players.mprisPlayer?.previous()
            }

            Behavior on color { ColorAnimation { duration: 150 } }
          }

          // Play/Pause button
          Rectangle {
            Layout.preferredWidth: ScalerService.s(64)
            Layout.preferredHeight: ScalerService.s(64)
            radius: ScalerService.s(32)
            color: playArea.containsMouse ? theme.button.text : theme.button.background
            opacity: root.animationProgress > 0.6 ? 1 : 0
            Behavior on opacity {
              NumberAnimation {
                duration: 200
              }
            }

            IconText {
              anchors.centerIn: parent
              name: Players.mprisPlayer && Players.mprisPlayer.isPlaying ? "pause" : "play_arrow"
              size: "large"
              opacity: root.animationProgress > 0.91 ? 1 : 0
              Behavior on opacity {
                NumberAnimation {
                  duration: 200
                }
              }
            }

            MouseArea {
              id: playArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: Players.mprisPlayer?.togglePlaying()
            }

            Behavior on color { ColorAnimation { duration: 150 } }
          }

          // Next button
          Rectangle {
            Layout.preferredWidth: ScalerService.s(48)
            Layout.preferredHeight: ScalerService.s(48)
            radius: ScalerService.s(24)
            color: nextArea.containsMouse ? theme.button.text : theme.button.background
            opacity: root.animationProgress > 0.7 ? 1 : 0
            Behavior on opacity {
              NumberAnimation {
                duration: 200
              }
            }

            IconText {
              anchors.centerIn: parent
              name: "skip_next"
              size: "large"
              opacity: root.animationProgress > 0.94 ? 1 : 0
              Behavior on opacity {
                NumberAnimation {
                  duration: 200
                }
              }
            }

            MouseArea {
              id: nextArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: Players.mprisPlayer?.next()
            }

            Behavior on color { ColorAnimation { duration: 150 } }
          }

          Item { Layout.fillWidth: true }
        }

        // Progress bar with time
        ColumnLayout {
          Layout.fillWidth: true
          spacing: ScalerService.s(4)
          visible: root.mprisPlayer && root.mprisPlayer.length > 0

          RowLayout {
            Layout.fillWidth: true

            CustomText {
              name: formatTime(root.mprisPlayer ? root.mprisPlayer.position : 0)
              size: "xs"
              textColor: theme.primary.dim_foreground
              opacity: root.animationProgress > 0.95 ? 1 : 0
              Behavior on opacity {
                NumberAnimation {
                  duration: 200
                }
              }

            }

            Item { Layout.fillWidth: true }

            CustomText {
              name: formatTime(root.mprisPlayer ? root.mprisPlayer.length : 0)
              size: "xs"
              textColor: theme.primary.dim_foreground
              opacity: root.animationProgress > 0.97 ? 1 : 0
              Behavior on opacity {
                NumberAnimation {
                  duration: 200
                }
              }

            }
          }

          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: ScalerService.s(6)
            radius: ScalerService.s(3)
            color: theme.primary.dim_background
            opacity: root.animationProgress > 0.7 ? 1 : 0
            Behavior on opacity {
              NumberAnimation {
                duration: 200
              }
            }

            Rectangle {
              id: progressFill
              height: parent.height
              width: root.animationProgress > 1 ? root.mprisPlayer ? Math.min(parent.width, parent.width * (root.mprisPlayer.position / Math.max(1, root.mprisPlayer.length))) : 0 : 0
              radius: parent.radius
              color: theme.button.text

              Behavior on width {
                NumberAnimation { duration: 200 }
              }
            }
          }
        }

        Item { Layout.preferredHeight: ScalerService.s(5) }
      }
    }
    Timer {
      // only emit the signal when the position is actually changing.
      running: mprisPlayer.playbackState == MprisPlaybackState.Playing
      // Make sure the position updates at least once per second.
      interval: 1000
      repeat: true
      // emit the positionChanged signal every second.
      onTriggered: mprisPlayer.positionChanged()
    }
  }
}
