// KeyBindDisplay.qml
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.services
import qs.components
import "." as Com

Item {
  id: root

  property var shortcutsData: [
  {
    title: "Basic Window Management",
    shortcuts: [
    { key: "SUPER + RETURN", action: "Open Terminal (kitty)" },
    { key: "SUPER + Q", action: "Close Window" },
    { key: "SUPER + M", action: "Exit Hyprland" },
    { key: "SUPER + E", action: "File Manager (thunar)" },
    { key: "SUPER + SPACE", action: "Toggle Launcher Panel" },
    { key: "SUPER + V", action: "Toggle Floating Mode" },
    { key: "SUPER + F", action: "Toggle Fullscreen" },
    { key: "SUPER + P", action: "Toggle Pseudo Tiling" }
    ]
  },
  {
    title: "Window Focus",
    shortcuts: [
    { key: "SUPER + ←", action: "Focus Left Window" },
    { key: "SUPER + →", action: "Focus Right Window" },
    { key: "SUPER + ↑", action: "Focus Up Window" },
    { key: "SUPER + ↓", action: "Focus Down Window" }
    ]
  },
  {
    title: "Workspace Management",
    shortcuts: [
    { key: "SUPER + 1-9", action: "Switch to Workspace 1-9" },
    { key: "SUPER + SHIFT + 1-9", action: "Move Window to Workspace 1-9" },
    { key: "SUPER + S", action: "Toggle Special Workspace (magic)" },
    { key: "SUPER + SHIFT + S", action: "Move Window to Special Workspace" },
    { key: "SUPER + Scroll Down", action: "Next Workspace" },
    { key: "SUPER + Scroll Up", action: "Previous Workspace" }
    ]
  },
  {
    title: "Mouse Window Control",
    shortcuts: [
    { key: "SUPER + Left Click + Drag", action: "Move Window" },
    { key: "SUPER + Right Click + Drag", action: "Resize Window" }
    ]
  },
  {
    title: "Dashboard & Panels",
    shortcuts: [
    { key: "SUPER + D", action: "Toggle Dashboard" },
    { key: "SUPER + L", action: "Lock Screen" },
    { key: "SUPER + A", action: "Toggle Calendar" },
    { key: "SUPER + B", action: "Toggle Bluetooth Panel" },
    { key: "SUPER + C", action: "Toggle CPU Monitor" },
    { key: "SUPER + R", action: "Toggle RAM Monitor" },
    { key: "SUPER + W", action: "Toggle Weather" },
    { key: "SUPER + I", action: "Toggle WiFi Panel" },
    { key: "SUPER + H", action: "Toggle Keybind Help Panel" },
    { key: "SUPER + U", action: "Toggle Volume Mixer" },
    { key: "SUPER + Y", action: "Toggle Battery Info" }
    ]
  },
  {
    title: "Media Control",
    shortcuts: [
    { key: "XF86AudioPlay", action: "Play/Pause" },
    { key: "XF86AudioPause", action: "Play/Pause" },
    { key: "XF86AudioNext", action: "Next Track" },
    { key: "XF86AudioPrev", action: "Previous Track" },
    { key: "XF86AudioRaiseVolume", action: "Volume Up +5%" },
    { key: "XF86AudioLowerVolume", action: "Volume Down -5%" },
    { key: "XF86AudioMute", action: "Toggle Master Mute" },
    { key: "XF86AudioMicMute", action: "Toggle Microphone Mute" }
    ]
  },
  {
    title: "Display Brightness",
    shortcuts: [
    { key: "XF86MonBrightnessUp", action: "Brightness Up +5%" },
    { key: "XF86MonBrightnessDown", action: "Brightness Down -5%" }
    ]
  },
  {
    title: "Screenshots",
    shortcuts: [
    { key: "PRINT", action: "Fullscreen Screenshot (Save & Copy)" },
    { key: "SUPER + PRINT", action: "Area Screenshot (Select region)" }
    ]
  }
  ]

  function parseKey(keyText) {
    var parts = keyText.split("+").map(p => p.trim())
    var result = []
    for (var i = 0; i < parts.length; i++) {
      if (parts[i] === "SUPER") {
        result.push({ type: "icon", value: "window" })
      } else {
        result.push({ type: "text", value: parts[i] })
      }
      if (i < parts.length - 1) {
        result.push({ type: "separator", value: "+" })
      }
    }
    return result
  }

  ScrollView {
    anchors.fill: parent
    anchors.margins: ScalerService.s(10)
    clip: true
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
    ScrollBar.vertical.policy: ScrollBar.AsNeeded

    ColumnLayout {
      width: parent.parent.width - ScalerService.s(20)
      spacing: ScalerService.s(20)
      // Grid Layout for categories
      RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true

        ColumnLayout {
          spacing: ScalerService.s(32)
          Com.ItemCategory {
            categoryData: root.shortcutsData[0]
          }
          Com.ItemCategory {
            categoryData: root.shortcutsData[3]
          }
          Com.ItemCategory {
            categoryData: root.shortcutsData[5]
          }
          Item {
            Layout.fillHeight: true
          }
        }
        Item {
          Layout.fillWidth: true
        }
        ColumnLayout {
          spacing: ScalerService.s(32)
          Com.ItemCategory {
            categoryData: root.shortcutsData[1]
          }
          Com.ItemCategory {
            categoryData: root.shortcutsData[4]
          }
          Com.ItemCategory {
            categoryData: root.shortcutsData[6]
          }
          Item {
            Layout.fillHeight: true
          }
        }
        Item {
          Layout.fillWidth: true
        }
        ColumnLayout {
          spacing: ScalerService.s(32)
          Com.ItemCategory {
            categoryData: root.shortcutsData[2]
          }
          Com.ItemCategory {
            categoryData: root.shortcutsData[4]
          }
          Com.ItemCategory {
            categoryData: root.shortcutsData[7]
          }
          Item {
            Layout.fillHeight: true
          }
        }

      }

      Item {
        Layout.fillHeight: true
        Layout.preferredHeight: ScalerService.s(20)
      }
    }
  }
}
