// BatteryIcon.qml - Component riêng cho icon pin
import QtQuick
import QtQuick.Controls
import Quickshell.Services.UPower
import QtQuick.Layouts
import Quickshell
import qs.services

Item {
  id: root
  property int percent: Math.round(UPower.displayDevice.percentage * 100)
  property bool batteryCharging: false
  property color textColor: theme.primary.foreground

  property var status: UPowerDeviceState.toString(UPower.displayDevice.state)
  
  // Kích thước có thể tùy chỉnh
  property real iconWidth: ScalerService.s(40)
  property real iconHeight: ScalerService.s(20)
  
  width: iconWidth
  height: iconHeight
  
  // Battery body
  Rectangle {
    id: batteryBody
    anchors.fill: parent
    radius: ScalerService.s(3)
    border.color: root.textColor
    border.width: ScalerService.s(2)
    color: "transparent"
    
    // Battery tip (phần đầu pin)
    Rectangle {
      id: batteryTip
      x: parent.width + ScalerService.s(1)
      y: parent.height / 2 - ScalerService.s(3)
      width: ScalerService.s(4)
      height: ScalerService.s(6)
      radius: ScalerService.s(1)
      color: root.textColor
    }
    
    // Battery level fill (thanh pin bên trong)
    Rectangle {
      id: batteryFill
      anchors {
        left: parent.left
        top: parent.top
        bottom: parent.bottom
        margins: ScalerService.s(2)
      }
      width: (parent.width - ScalerService.s(4)) * Math.min(1, Math.max(0, root.percent / 100))
      radius: ScalerService.s(1)
      color: getBatteryColor()
      
      Behavior on width {
        NumberAnimation {
          duration: 800
          easing.type: Easing.OutCubic
        }
      }
    }
    
    // Charging bolt icon (tia sét khi đang sạc)
    Text {
      anchors.centerIn: parent
      text: root.status === "Charging" ? "⚡" : ""
      color: theme.primary.background
      font.pointSize: ScalerService.s(10)
      visible: root.status === "Charging"
    }
  }
  
  // Hàm lấy màu sắc dựa trên phần trăm pin
  function getBatteryColor() {
    if (root.percent > 60) 
      return theme.normal.green;
    if (root.percent > 20) 
      return theme.normal.yellow;
    return theme.normal.red;
  }
}
