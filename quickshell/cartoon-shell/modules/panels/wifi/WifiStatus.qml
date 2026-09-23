import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components
import qs.commons

Rectangle {
  id: root
  property var wifiManager

  implicitHeight: ScalerService.s(80)
  color: Qt.alpha(theme.primary.dim_background,0.6)
  radius: ScalerService.s(Settings.appearance.radius2)
  border.width: Settings.appearance.enableBorder ? ScalerService.s(2) : 0
  border.color: theme.normal.black
  property real animationProgress: 0

  RowLayout {
    anchors.fill: parent
    anchors.margins: ScalerService.s(12)

    ColumnLayout {
      Layout.fillHeight: true
      CustomText {
        name: wifiManager.wifiEnabled ? (lang?.wifi?.enabled || "WiFi đang bật") : (lang?.wifi?.disabled || "WiFi đang tắt")
        isBold: true
        textColor: wifiManager.wifiEnabled ? theme.button.text : theme.normal.red
        opacity: root.animationProgress > 0.4 ? 1 : 0
      }
      CustomText {
        name: wifiManager.connectedWifi || (lang?.wifi?.not_connected || "Chưa kết nối")
        size: "small"
        textColor: theme.primary.dim_foreground
        elide: Text.ElideRight
        opacity: root.animationProgress > 0.5 ? 1 : 0
      }
    }
    Item{
      Layout.fillWidth: true
    }
    CustomToggleSwitch {
      opacity: root.animationProgress > 0.6 ? 1 : 0
      adapter: wifiManager.wifiEnabled
      onClicked:{
        wifiManager.toggleWifi();
      }
    }
  }
}
