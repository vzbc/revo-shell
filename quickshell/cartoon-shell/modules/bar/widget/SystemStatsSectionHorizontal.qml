import QtQuick
import QtQuick.Layouts
import "." as Com
import qs.services

Item {
  id: root
  property real animationProgress: 0
  RowLayout {
    anchors.fill: parent
    spacing: ScalerService.s(4)

    // CPU Container
    Com.StatContainer {
      Layout.fillWidth: true
      Layout.fillHeight: true
      panelName: "cpu"

      Com.CpuStat {
        anchors.centerIn: parent
      }
    }
    Com.StatContainer {
      Layout.fillWidth: true
      Layout.fillHeight: true
      panelName: "ram"

      Com.RamStat {
        anchors.centerIn: parent
      }
    }
  }

}
