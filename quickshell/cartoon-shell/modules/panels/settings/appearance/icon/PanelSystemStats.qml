import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components
import qs.commons
import "./" as Com

ColumnLayout {
  id: root
  spacing: ScalerService.s(32)
  Layout.fillWidth: true

  function changeStyle(nameSystem, style) {
    switch(nameSystem) {
      case "cpu": {
        Settings.bar.cpu = {
          "style": style,
          "active": Settings.bar.cpu.active
        }
        return;
      }
      case "ram": {
        Settings.bar.ram = {
          "style": style,
          "active": Settings.bar.ram.active
        }
        return;
      }
      case "bluetooth": {
        Settings.bar.bluetooth = {
          "style": style,
          "active": Settings.bar.bluetooth.active
        }
        return;
      }
      case "wifi": {
        Settings.bar.wifi = {
          "style": style,
          "active": Settings.bar.wifi.active
        }
        return;
      }
      case "volume": {
        Settings.bar.volume = {
          "style": style,
          "active": Settings.bar.volume.active
        }
        return;
      }
    }
  }

  CustomText {
    name: "System Stats"
    isBold: true
  }

  Com.StyleSelectorRow {
    title: "CPU"
    systemName: "cpu"
    styleModel: 8
    currentStyle: Settings.bar.cpu.style
    onStyleChanged: function(style) {
      root.changeStyle("cpu", style)
    }
  }

  Rectangle {
    Layout.preferredWidth: parent.width * 0.8
    Layout.preferredHeight: ScalerService.s(2)
    radius: ScalerService.s(8)
    color: theme.primary.dim_foreground
    Layout.alignment: Qt.AlignHCenter
  }

  Com.StyleSelectorRow {
    title: "Ram"
    systemName: "ram"
    styleModel: 8
    currentStyle: Settings.bar.ram.style
    onStyleChanged: function(style) {
      root.changeStyle("ram", style)
    }
  }
  Rectangle {
    Layout.preferredWidth: parent.width * 0.8
    Layout.preferredHeight: ScalerService.s(2)
    radius: ScalerService.s(8)
    color: theme.primary.dim_foreground
    Layout.alignment: Qt.AlignHCenter
  }

  Com.StyleSelectorRow {
    title: "Bluetooth"
    systemName: "bluetooth"
    styleModel: 2
    currentStyle: Settings.bar.bluetooth.style
    onStyleChanged: function(style) {
      root.changeStyle("bluetooth", style)
    }
  }
  Rectangle {
    Layout.preferredWidth: parent.width * 0.8
    Layout.preferredHeight: ScalerService.s(2)
    radius: ScalerService.s(8)
    color: theme.primary.dim_foreground
    Layout.alignment: Qt.AlignHCenter
  }

  Com.StyleSelectorRow {
    title: "Wifi"
    systemName: "wifi"
    styleModel: 3
    currentStyle: Settings.bar.wifi.style
    onStyleChanged: function(style) {
      root.changeStyle("wifi", style)
    }
  }

  Rectangle {
    Layout.preferredWidth: parent.width * 0.8
    Layout.preferredHeight: ScalerService.s(2)
    radius: ScalerService.s(8)
    color: theme.primary.dim_foreground
    Layout.alignment: Qt.AlignHCenter
  }

  Com.StyleSelectorRow {
    title: "Volume"
    systemName: "volume"
    styleModel: 2
    currentStyle: Settings.bar.volume.style
    onStyleChanged: function(style) {
      root.changeStyle("volume", style)
    }
  }
}
