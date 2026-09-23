import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "." as Com
import qs.services
import qs.components

ColumnLayout {
  id: root
  property var wifiManager
  property real animationProgress: 0
  Rectangle {
    Layout.preferredHeight: ScalerService.s(20)
    Layout.fillWidth: true
    color: "transparent"

    CustomText {
      anchors {
        fill: parent
        leftMargin: ScalerService.s(10)
      }
      name: (lang?.wifi?.available_networks || "Mạng có sẵn") + " (" + wifiManager.wifiList.length + ")"
      textColor: theme.primary.dim_foreground
      size: "small"
      opacity: root.animationProgress > 0.7 ? 1 : 0

    }
  }

  Item {
    Layout.fillWidth: true
    Layout.fillHeight: true
    clip: true
    ScrollView {
      anchors.fill: parent

      ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AsNeeded
        background: Rectangle {
          color: theme.primary.dim_background
          radius: ScalerService.s(3)
        }
        contentItem: Rectangle {
          color: theme.normal.blue
          radius: ScalerService.s(3)
        }
      }

      ListView {
        id: wifiListView
        model: wifiManager.wifiList
        spacing: ScalerService.s(6)

        delegate: Com.WifiNetworkItem {
          opacity: root.animationProgress > 0.9 ? 1 : 0

          SequentialAnimation on opacity {
            running: root.animationProgress > 0.8

            PauseAnimation {
              duration: index * 15
            }

            NumberAnimation {
              to: 1
              duration: 200
              easing.type: Easing.OutCubic
            }
          }
          width: wifiListView.width
          networkData: modelData
          wifiManager: root.wifiManager
        }
      }
    }

  }
}
