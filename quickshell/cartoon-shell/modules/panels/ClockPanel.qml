import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import QtQuick.Controls
import qs.services
import qs.components

PanelWindow {
  id: root
  WlrLayershell.exclusiveZone: 0   // không chiếm không gian ứng dụng

  property string currentHour: ""
  property string currentMin: ""
  property string currentDay: ""
  property string currentDate: ""
  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }

  margins {
    top: ScalerService.s(10)
    bottom: ScalerService.s(10)
    left: ScalerService.s(10)
    right: ScalerService.s(10)
  }

  implicitWidth: content.implicitWidth
  implicitHeight: content.implicitHeight

  WlrLayershell.layer: WlrLayer.Bottom

  SystemClock {
    id: clock
    precision: SystemClock.Seconds
    onDateChanged: {
      updateDateTime();
    }
  }

  function updateDateTime() {
    const now = new Date();
    const dayData = lang?.dateFormat?.day;
    const weekdays = dayData ? [dayData.sunday || "CN", dayData.monday || "T2", dayData.tuesday || "T3", dayData.wednesday || "T4", dayData.thursday || "T5", dayData.friday || "T6", dayData.saturday || "T7"] : ["CN", "T2", "T3", "T4", "T5", "T6", "T7"];

    const monthData = lang?.dateFormat?.month;
    const months = monthData ? [monthData.january || "Th1", monthData.february || "Th2", monthData.march || "Th3", monthData.april || "Th4", monthData.may || "Th5", monthData.june || "Th6", monthData.july || "Th7", monthData.august || "Th8", monthData.september || "Th9", monthData.october || "Th10", monthData.november || "Th11", monthData.december || "Th12"] : ["Th1", "Th2", "Th3", "Th4", "Th5", "Th6", "Th7", "Th8", "Th9", "Th10", "Th11", "Th12"];

    root.currentDay = `${weekdays[now.getDay()]}`;
    root.currentHour = Qt.formatTime(now, "HH");
    root.currentMin = Qt.formatTime(now, "mm");
    root.currentDate = `${now.getDate()} ${months[now.getMonth()]} ${now.getFullYear()}`;
  }

  color: "transparent"

  Rectangle {
    id: clockContainer
    anchors.fill: parent
    radius: ScalerService.s(10)
    color: "transparent"

    RowLayout {
      id: content
      anchors.centerIn: parent
      spacing: ScalerService.s(33)

      ColumnLayout {
        spacing: ScalerService.s(5)
        CustomText{
          name: root.currentHour
          isBold: true
          textColor: "#ffffff"
          font.pixelSize: ScalerService.s(124)
        }

        CustomText {
          name: root.currentMin
          color: "#ffffff"
          isBold: true
          font.pixelSize: ScalerService.s(124)
        }
      }

      Rectangle {
        Layout.preferredWidth: ScalerService.s(10)
        Layout.preferredHeight: parent.height/2
        color: "#ffffff"
        radius: ScalerService.s(10)
      }

      // Phần hiển thị ngày tháng
      ColumnLayout {
        spacing: ScalerService.s(5)
        CustomText {
          name: root.currentDay
          isBold: true
          textColor: "#ffffff"
          font.pixelSize: ScalerService.s(124)
        }
        CustomText {
          name: root.currentDate
          isBold: true
          textColor: "#ffffff"
          font.pixelSize: ScalerService.s(64)
        }
      }
    }
  }

  Component.onCompleted: {
    root.updateDateTime(); // Khởi tạo thời gian ban đầu
  }
}
