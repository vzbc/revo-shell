import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components

Rectangle {
  id: waterFillContainer
  clip: true
  color: theme.button.background
  property real fillValue: 20
  property string fillColor: theme.button.text
  property string waveColor: theme.button.text
  property real phase1: 0

  Timer {
    interval: 64
    running: true
    repeat: true
    onTriggered: {
      phase1 += 0.05
      if (phase1 > Math.PI * 2) phase1 -= Math.PI * 2
      canvas1.requestPaint()
    }
  }

  // Phần nước (fill)
  Item {
    id: waterFill
    anchors.bottom: parent.bottom
    width: parent.width
    height: parent.height * (waterFillContainer.fillValue / 100)
    clip: true

    Behavior on height {
      NumberAnimation { duration: 500; easing.type: Easing.OutCubic }
    }

    // Sóng thứ nhất
    Canvas {
      id: canvas1
      anchors.fill: parent
      onPaint: {
        var ctx = getContext("2d");
        ctx.reset();
        ctx.beginPath();

        var width = canvas1.width;
        var height = canvas1.height;
        var phase = waterFillContainer.phase1;

        for(var x = 0; x <= width; x += 5) {
          var y = Math.sin(x * 0.02 + phase) * ScalerService.s(8) + ScalerService.s(15);
          if(x === 0) {
            ctx.moveTo(x, y);
          } else {
            ctx.lineTo(x, y);
          }
        }

        ctx.lineTo(width, height);
        ctx.lineTo(0, height);
        ctx.closePath();

        ctx.fillStyle = waterFillContainer.waveColor;
        ctx.fill();
        ctx.globalAlpha = 0.6;
      }
    }

  }

  ColumnLayout {
    anchors.centerIn: parent
    IconText {
      name: "humidity_mid"
      size: "large"
      Layout.alignment: Qt.AlignHCenter
    }
    CustomText {
      Layout.alignment: Qt.AlignHCenter
      text: Math.round(waterFillContainer.fillValue) + "%"
      size: "large"
      isBold: true
      z: 10
    }

  }

}
