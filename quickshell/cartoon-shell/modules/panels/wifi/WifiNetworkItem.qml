import QtQuick
import QtQuick.Layouts
import "." as Com
import qs.services
import qs.components
import qs.commons

ColumnLayout {
  id: networkItem
  property var wifiManager
  property var networkData

  spacing: ScalerService.s(4)

  Rectangle {
    id: wifiItem
    width: parent.width
    Layout.fillWidth: true
    Layout.preferredHeight: ScalerService.s(70)
    color: mouseArea.containsMouse
    ? Qt.alpha(theme.button.background_select, 0.5)
    : (networkData.isConnected
      ? Qt.alpha(theme.button.background, 0.5)
      : Qt.alpha(theme.primary.dim_background, 0.5))
    radius: ScalerService.s(Settings.appearance.radius2)
    border.width: Settings.appearance.enableBorder ? ScalerService.s(2) : 0
    border.color: networkData.isConnected ? theme.button.border : theme.normal.black

    RowLayout {
      anchors.margins: ScalerService.s(8)
      anchors.fill: parent

      ColumnLayout {
        CustomText {
          name: networkData.ssid
          size: "small"
          isBold: true
          textColor: networkData.isConnected ? theme.primary.foreground : theme.primary.foreground
        }
        CustomText {
          name: networkData.security + " • " + networkData.signal
          size: "xs"
          textColor: networkData.isConnected ? theme.button.text : theme.primary.dim_foreground
        }
      }
      Item{Layout.fillWidth: true}

      Rectangle {
        color: networkData.isConnected ? theme.normal.green : theme.button.background
        Layout.preferredHeight: iconItem.height
        Layout.preferredWidth: iconItem.height
        radius: ScalerService.s(16)
        IconText{
          anchors.centerIn: parent
          id: iconItem
          name: networkData.isConnected ? "check" : networkData.saved_password != "--" ? "lock_open" : "lock"
          size: "small"
          textColor: networkData.isConnected ? theme.primary.background : theme.button.text
        }

      }

    }

    MouseArea {
      id: mouseArea
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: {
        if (wifiManager.openSsid === networkData.ssid) {
          wifiManager.openSsid = "";
        } else {
          wifiManager.openSsid = networkData.ssid;
        }
      }
    }
  }

  Com.WifiPasswordBox {
    Layout.fillWidth: true
    Layout.preferredHeight: ScalerService.s(70)
    visible: networkItem.networkData.ssid === wifiManager.openSsid
    networkData: networkItem.networkData
    wifiManager: networkItem.wifiManager
    width: parent.width
  }
}
