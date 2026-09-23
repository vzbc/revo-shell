import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components
import qs.services.cpu
import "." as Com

Item {
  id: root
  property real animationProgress: 0
  ColumnLayout {
    anchors.fill: parent
    spacing: ScalerService.s(8)

    Item {
      id: cpuContainerVertical
      Layout.fillWidth: true
      Layout.fillHeight: true

      Item {
        anchors.centerIn: parent
        width: parent.height  // Đảo width và height
        height: parent.width
        transformOrigin: Item.Center

        ColumnLayout {
          anchors.centerIn: parent
          spacing: ScalerService.s(4)

          ColumnLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: 0
            CustomText {
              name: "CPU"
              Layout.alignment: Qt.AlignHCenter
              textColor: theme.primary.dim_foreground
              size: "xs"
            }
            CustomText {
              name: CpuSimpleService.cpuPercent + "%"
              size: "small"
              isBold: true
              Layout.alignment: Qt.AlignHCenter
            }
          }
        }
      }

      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          VisibleService.togglePanel("cpu");
        }
      }
    }

    Item {
      id: memoryContainerVertical
      Layout.fillWidth: true
      Layout.fillHeight: true
      // Xoay container để hiển thị dọc
      Item {
        anchors.centerIn: parent
        width: parent.height  // Đảo width và height
        height: parent.width
        transformOrigin: Item.Center

        ColumnLayout {
          anchors.centerIn: parent
          spacing: ScalerService.s(4)

          ColumnLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: 0

            CustomText {
              name: "RAM"
              textColor: theme.primary.dim_foreground
              size: "xs"
              Layout.alignment: Qt.AlignHCenter
            }
            CustomText {
              name: ramService.memPercent + "%"
              size: "small"
              isBold: true
              Layout.alignment: Qt.AlignHCenter
            }
          }
        }
      }

      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          VisibleService.togglePanel("ram");
        }
      }
    }
  }

}
