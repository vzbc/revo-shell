import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell.Services.UPower
import Quickshell.Io
import Quickshell
import qs.services
import qs.commons
import qs.components

Item {
  id: root

  // Catppuccin Mocha color scheme
  property color batteryHighColor: theme.normal.green
  property color batteryMediumColor: theme.normal.yellow
  property color batteryLowColor: theme.normal.red
  property color batteryBackgroundColor: theme.normal.black
  property color textColor: theme.primary.foreground
  property color dimTextColor: theme.primary.dim_foreground
  property color borderColor: theme.bright.black
  property color separatorColor: theme.normal.black

  property real animationProgress: 0
  SequentialAnimation on animationProgress {
    running: true
    NumberAnimation {
      from: 0
      to: 1
      duration: 500
      easing.type: Easing.Linear
    }
  }

  property int batteryPercent: 0
  property string batteryStatus: "Discharging"
  property bool dataLoaded: false

  // Refresh battery data from UPower
  function refreshBatteryData() {
    var dev = UPower.displayDevice;
    if (!dev || !dev.ready) return;
    
    root.batteryPercent = Math.round(dev.percentage * 100);
    root.batteryStatus = UPowerDeviceState.toString(dev.state);
    root.dataLoaded = true;
  }

  // Initialize and listen to UPower changes
  Timer {
    id: initTimer
    interval: 100
    running: true
    repeat: true
    onTriggered: {
      if (UPower.displayDevice && UPower.displayDevice.ready) {
        stop();
        refreshBatteryData();
      }
    }
  }

  Connections {
    target: UPower.displayDevice
    enabled: UPower.displayDevice && UPower.displayDevice.ready
    function onPercentageChanged() { refreshBatteryData(); }
    function onStateChanged() { refreshBatteryData(); }
    function onEnergyChanged() { refreshBatteryData(); }
    function onEnergyFullChanged() { refreshBatteryData(); }
  }

  Rectangle {
    anchors.centerIn: parent
    implicitWidth: root.animationProgress > 0 ? parent.width : 0
    implicitHeight: root.animationProgress > 0 ? parent.height : 0
    Behavior on implicitHeight {
      NumberAnimation {
        duration: 500
        easing.type: Easing.OutCubic
      }
    }
    Behavior on implicitWidth {
      NumberAnimation {
        duration: 500
        easing.type: Easing.OutCubic
      }
    }
    radius: ScalerService.s(Settings.appearance.radius1)
    border.width: Settings.appearance.enableBorder ? ScalerService.s(1) : 0
    color: theme.primary.background
    border.color: theme.button.border

    // Background pattern nhẹ
    Rectangle {
      anchors.fill: parent
      color: "transparent"
      opacity: 0.1
      radius: ScalerService.s(12)

      Canvas {
        anchors.fill: parent
        onPaint: {
          var ctx = getContext("2d");
          ctx.strokeStyle = theme.primary.foreground;
          ctx.lineWidth = 0.5;

          for (var x = 0; x < width; x += ScalerService.s(15)) {
            ctx.beginPath();
            ctx.moveTo(x, 0);
            ctx.lineTo(x, height);
            ctx.stroke();
          }
          for (var y = 0; y < height; y += ScalerService.s(15)) {
            ctx.beginPath();
            ctx.moveTo(0, y);
            ctx.lineTo(width, y);
            ctx.stroke();
          }
        }
      }
    }
  }

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: ScalerService.s(16)
    spacing: ScalerService.s(16)
    // Battery Level Section
    ColumnLayout {
      Layout.fillWidth: true
      spacing: ScalerService.s(8)

      RowLayout {
        Layout.fillWidth: true
        spacing: ScalerService.s(12)

        BatteryIcon {
          id: batteryIcon
          textColor: root.textColor
          Layout.preferredWidth: ScalerService.s(40)
          Layout.preferredHeight: ScalerService.s(20)
        }

        ColumnLayout {
          spacing: ScalerService.s(2)

          Text {
            text: root.batteryPercent + "%"
            color: getBatteryColor()
            font.bold: true
            font.pointSize: ScalerService.s(16)
          }

          Text {
            text: root.batteryStatus
            color: dimTextColor
            font.pointSize: ScalerService.s(10)
          }
        }

        Item {
          Layout.fillWidth: true
        }

        Text {
          text: getTimeEstimate()
          color: dimTextColor
          font.pointSize: ScalerService.s(10)
          Layout.alignment: Qt.AlignRight
          visible: text !== ""
        }
      }

      Rectangle {
        Layout.fillWidth: true
        height: ScalerService.s(12)
        radius: ScalerService.s(6)
        color: batteryBackgroundColor

        Rectangle {
          width: parent.width * (root.batteryPercent / 100)
          height: parent.height
          radius: ScalerService.s(6)
          gradient: Gradient {
            GradientStop {
              position: 0.0
              color: Qt.lighter(getBatteryColor(), 1.3)
            }
            GradientStop {
              position: 1.0
              color: getBatteryColor()
            }
          }
          Behavior on width {
            NumberAnimation {
              duration: 800
              easing.type: Easing.OutCubic
            }
          }
        }
      }
    }

    // Separator
    Rectangle {
      Layout.fillWidth: true
      height: ScalerService.s(1)
      color: "transparent"

      Rectangle {
        anchors.centerIn: parent
        width: parent.width * 0.8
        height: ScalerService.s(1)
        gradient: Gradient {
          GradientStop {
            position: 0.0
            color: "transparent"
          }
          GradientStop {
            position: 0.2
            color: separatorColor
          }
          GradientStop {
            position: 0.8
            color: separatorColor
          }
          GradientStop {
            position: 1.0
            color: "transparent"
          }
        }
      }
    }

    // Battery Details Section
    GridLayout {
      Layout.fillWidth: true
      columns: 2
      rowSpacing: ScalerService.s(6)
      columnSpacing: ScalerService.s(12)

      // Energy
      Text {
        text: "Energy:"
        color: dimTextColor
        font.pointSize: ScalerService.s(9)
      }
      Text {
        text: UPower.displayDevice.energy + " / " + UPower.displayDevice.energyCapacity + " Wh"
        color: textColor
        font.pointSize: ScalerService.s(9)
        font.bold: true
      }

      Text {
        text: "Status:"
        color: dimTextColor
        font.pointSize: ScalerService.s(9)
      }
      Text {
        text: root.batteryStatus
        color: getBatteryStatusColor()
        font.pointSize: ScalerService.s(9)
        font.bold: true
      }

    }
  }

  // Loading animation
  Rectangle {
    anchors.fill: parent
    color: theme.primary.background
    radius: ScalerService.s(12)
    opacity: dataLoaded ? 0 : 1
    visible: opacity > 0

    Behavior on opacity {
      NumberAnimation {
        duration: 300
      }
    }

    Column {
      anchors.centerIn: parent
      spacing: ScalerService.s(12)

      Text {
        text: "🔋"
        font.pointSize: ScalerService.s(20)
        color: dimTextColor
        anchors.horizontalCenter: parent.horizontalCenter
      }

      Text {
        text: "Loading battery data..."
        color: dimTextColor
        font.pointSize: ScalerService.s(10)
        anchors.horizontalCenter: parent.horizontalCenter
      }
    }
  }

  // Helper functions
  function getBatteryColor() {
    if (root.batteryPercent > 60)
      return batteryHighColor;
    if (root.batteryPercent > 20)
      return batteryMediumColor;
    return batteryLowColor;
  }

  function getBatteryStatusColor() {
    switch (root.batteryStatus) {
      case "Charging":
        return theme.normal.green;
      case "Discharging":
        return getBatteryColor();
      case "Full":
        return theme.normal.cyan;
      default:
        return theme.normal.white;
    }
  }

  function getTimeEstimate() {
    var dev = UPower.displayDevice;
    if (!dev || !dev.ready) return "";

    if (root.batteryStatus === "Charging") {
      var seconds = dev.timeToFull;
      if (seconds <= 0 || seconds === Infinity) return "";
      
      var hours = Math.floor(seconds / 3600);
      var minutes = Math.floor((seconds % 3600) / 60);
      
      if (hours > 0)
        return hours + "h " + minutes + "m to full";
      return minutes + "m to full";
    }

    if (root.batteryStatus === "Discharging") {
      var seconds = dev.timeToEmpty;
      if (seconds <= 0 || seconds === Infinity) return "";
      
      var hours = Math.floor(seconds / 3600);
      var minutes = Math.floor((seconds % 3600) / 60);
      
      if (hours > 0)
        return hours + "h " + minutes + "m remaining";
      return minutes + "m remaining";
    }

    return "";
  }

  Component.onCompleted: {
    if (UPower.displayDevice && UPower.displayDevice.ready) {
      refreshBatteryData();
    }
  }
}
