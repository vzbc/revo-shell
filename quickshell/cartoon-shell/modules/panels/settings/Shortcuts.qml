// components/Settings/ShortcutsSettings.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services

Item {
  ScrollView {
    anchors.fill: parent
    anchors.margins: ScalerService.s(20)
    clip: true
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
    ScrollBar.vertical.policy: ScrollBar.AsNeeded

    ColumnLayout {
      width: parent.parent.width - ScalerService.s(40)
      spacing: ScalerService.s(20)

      // Header
      Text {
        text: "⌨️ Hyprland Shortcuts"
        color: theme.primary.foreground
        font {
          family: "ComicShannsMono Nerd Font"
          pixelSize: ScalerService.s(24)
          bold: true
        }
        Layout.topMargin: ScalerService.s(10)
      }

      Rectangle {
        Layout.fillWidth: true
        height: ScalerService.s(1)
        color: theme.primary.foreground
      }

      // Basic Window Management section - remove the SUPER + J line since it's not standard
      ShortcutCategory {
        title: "🪟 Basic Window Management"
        shortcuts: [
        {
          key: "SUPER + RETURN",
          action: "Open Terminal"
        },
        {
          key: "SUPER + Q",
          action: "Close Window"
        },
        {
          key: "SUPER + M",
          action: "Exit Hyprland"
        },
        {
          key: "SUPER + E",
          action: "File Manager"
        },
        {
          key: "SUPER + SPACE",
          action: "Toggle Launcher Panel"
        },
        {
          key: "SUPER + V",
          action: "Toggle Floating"
        },
        {
          key: "SUPER + F",
          action: "Fullscreen"
        },
        {
          key: "SUPER + P",
          action: "Pseudo Tiling"
        }
        // Removed SUPER + J since it's not defined in your config
        ]
      }

      // Workspace Management - fix to 1-9 (or 1-10 if you add workspace 10)
      ShortcutCategory {
        title: "🎨 Workspace Management"
        shortcuts: [
        {
          key: "SUPER + 1-9",
          action: "Switch to Workspace 1-9"
        },
        {
          key: "SUPER + SHIFT + 1-9",
          action: "Move Window to Workspace 1-9"
        },
        {
          key: "SUPER + S",
          action: "Toggle Special Workspace (magic)"
        },
        {
          key: "SUPER + SHIFT + S",
          action: "Move Window to Special Workspace"
        }
        ]
      }

      // Mouse Actions - fix scroll direction
      ShortcutCategory {
        title: "🖱️ Mouse Actions"
        shortcuts: [
        {
          key: "SUPER + Scroll Down",
          action: "Next Workspace"
        },
        {
          key: "SUPER + Scroll Up",
          action: "Previous Workspace"
        },
        {
          key: "SUPER + Left Click + Drag",
          action: "Move Window"
        },
        {
          key: "SUPER + Right Click + Drag",
          action: "Resize Window"
        }
        ]
      }

      // Add missing Dashboard and Panels section
      ShortcutCategory {
        title: "📊 Dashboard & Panels"
        shortcuts: [
        {
          key: "SUPER + D",
          action: "Toggle Dashboard"
        },
        {
          key: "SUPER + L",
          action: "Lock Screen"
        },
        {
          key: "SUPER + A",
          action: "Toggle Calendar"
        },
        {
          key: "SUPER + B",
          action: "Toggle Bluetooth Panel"
        },
        {
          key: "SUPER + C",
          action: "Toggle CPU Monitor"
        },
        {
          key: "SUPER + R",
          action: "Toggle RAM Monitor"
        },
        {
          key: "SUPER + W",
          action: "Toggle Weather"
        },
        {
          key: "SUPER + I",
          action: "Toggle WiFi Panel"
        },
        {
          key: "SUPER + U",
          action: "Toggle Volume Mixer"
        },
        {
          key: "SUPER + Y",
          action: "Toggle Battery Info"
        }
        ]
      }      Item {
        Layout.fillHeight: true
      } // Spacer
    }
  }

  // Shortcut Category Component
  component ShortcutCategory: ColumnLayout {
    property string title: ""
    property var shortcuts: []

    Layout.fillWidth: true
    spacing: ScalerService.s(10)

    // Category Header
    Rectangle {
      Layout.fillWidth: true
      height: ScalerService.s(50)
      color: theme.primary.dim_background
      radius: ScalerService.s(12)
      border.width: ScalerService.s(2)
      border.color: theme.normal.black

      Text {
        anchors.centerIn: parent
        text: title
        color: theme.primary.foreground
        font {
          family: "ComicShannsMono Nerd Font"
          pixelSize: ScalerService.s(18)
          bold: true
        }
      }
    }

    // Shortcuts List
    ColumnLayout {
      Layout.fillWidth: true
      spacing: ScalerService.s(8)

      Repeater {
        model: shortcuts

        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: ScalerService.s(60)
          color: theme.button.background
          radius: ScalerService.s(10)
          border.width: ScalerService.s(1)
          border.color: theme.button.border

          RowLayout {
            anchors.fill: parent
            anchors.margins: ScalerService.s(15)
            spacing: ScalerService.s(20)

            // Key Badge (Left side)
            Rectangle {
              Layout.preferredWidth: ScalerService.s(220)
              Layout.minimumWidth: ScalerService.s(220)
              Layout.maximumWidth: ScalerService.s(280)
              Layout.preferredHeight: ScalerService.s(35)
              color: theme.normal.blue
              radius: ScalerService.s(8)

              Text {
                id: keyText
                anchors.centerIn: parent
                text: modelData.key
                color: theme.primary.background
                font {
                  family: "ComicShannsMono Nerd Font"
                  pixelSize: ScalerService.s(13)
                  bold: true
                }
              }
            }

            // Action Description (Right side)
            Text {
              text: modelData.action
              color: theme.primary.foreground
              font {
                family: "ComicShannsMono Nerd Font"
                pixelSize: ScalerService.s(15)
              }
              wrapMode: Text.WordWrap
              Layout.fillWidth: true
              Layout.alignment: Qt.AlignVCenter
            }
          }
        }
      }
    }
  }
}
