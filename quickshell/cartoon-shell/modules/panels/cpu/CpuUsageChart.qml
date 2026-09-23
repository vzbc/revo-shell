import QtQuick
import QtQuick.Layouts
import qs.services
import qs.services.cpu
import qs.components

Item {
  property var cpuHistory: CpuSimpleService.cpuHistory

  RowLayout {
    anchors.fill: parent
    anchors.margins: ScalerService.s(16)
    spacing: ScalerService.s(8)

    // Main chart area
    ColumnLayout {
      Layout.fillWidth: true
      Layout.fillHeight: true
      spacing: ScalerService.s(4)

      // Title row
      Item {
        Layout.fillWidth: true
        Layout.preferredHeight: ScalerService.s(50)

        CustomText {
          anchors.centerIn: parent
          name: "CPU Usage History"
          isBold: true
        }
      }
      // Chart area
      Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        Canvas {
          id: cpuChart
          anchors.fill: parent
          antialiasing: true

          onPaint: {
            var ctx = getContext("2d");
            ctx.reset();

            if (cpuHistory.length < 2)
            return;

            var width = cpuChart.width;
            var height = cpuChart.height;
            var paddingLeft = ScalerService.s(60);
            var paddingRight = ScalerService.s(20); // Extra space for percentage labels
            var paddingTop = ScalerService.s(30);
            var paddingBottom = ScalerService.s(20);
            var chartWidth = width - paddingLeft - paddingRight;
            var chartHeight = height - paddingTop - paddingBottom;

            // Draw background

            ctx.globalAlpha = 1.0;

            // Draw horizontal grid lines and percentage labels
            ctx.strokeStyle = theme.button.border;
            ctx.lineWidth = ScalerService.s(1);
            ctx.globalAlpha = 0.6; // Có thể giảm opacity để nhìn nhẹ nhàng hơn
            ctx.font = ScalerService.s(17) + "px 'ComicShannsMono Nerd Font'";
            ctx.fillStyle = theme.primary.foreground;
            ctx.textAlign = "right";
            ctx.textBaseline = "middle";

            // Cấu hình nét đứt cho caro
            ctx.setLineDash([ScalerService.s(5), ScalerService.s(5)]); // [độ dài nét, khoảng trống]

            for (var i = 0; i <= 10; i++) {
              var percentage = i * 10;
              var y = paddingTop + chartHeight - (chartHeight * percentage / 100);

              // Line ngang
              ctx.beginPath();
              ctx.moveTo(paddingLeft, y);
              ctx.lineTo(paddingLeft + chartWidth, y);
              ctx.stroke();

              // Text %
              ctx.fillText(percentage + "%", paddingLeft - ScalerService.s(5), y);
            }

            // ======================
            // Kẻ dọc
            // ======================

            for (var j = 0; j <= 15; j++) {
              var x = paddingLeft + (chartWidth * j / 15);

              ctx.beginPath();
              ctx.moveTo(x, paddingTop);
              ctx.lineTo(x, paddingTop + chartHeight);
              ctx.stroke();
            }

            // Reset lại về nét liền để không ảnh hưởng các phần vẽ khác
            ctx.setLineDash([]);

            ctx.globalAlpha = 1.0;

            // Draw CPU usage line with smooth curve
            if (cpuHistory.length > 0) {
              // Calculate all points first
              var points = [];
              for (var j = 0; j < cpuHistory.length; j++) {
                var x = paddingLeft + (chartWidth * j / (cpuHistory.length - 1));
                var usage = cpuHistory[j].usage;
                var y = paddingTop + chartHeight - (chartHeight * usage / 100);
                points.push({
                    x: x,
                    y: y
                });
              }

              // Fill area under smooth curve
              ctx.globalAlpha = 0.8
              ctx.fillStyle = theme.button.text
              ctx.beginPath();

              // Start from bottom left
              ctx.moveTo(paddingLeft, paddingTop + chartHeight);

              // Draw smooth curve to first point
              ctx.lineTo(points[0].x, paddingTop + chartHeight);
              ctx.lineTo(points[0].x, points[0].y);

              // Draw smooth curve through all points
              for (var j = 0; j < points.length - 1; j++) {
                var xc = (points[j].x + points[j + 1].x) / 2;
                var yc = (points[j].y + points[j + 1].y) / 2;

                if (j === 0) {
                  ctx.quadraticCurveTo(points[j].x, points[j].y, xc, yc);
                } else {
                  var prevXc = (points[j - 1].x + points[j].x) / 2;
                  var prevYc = (points[j - 1].y + points[j].y) / 2;
                  ctx.bezierCurveTo(prevXc, prevYc, points[j].x, points[j].y, xc, yc);
                }
              }

              // Draw last segment
              if (points.length > 1) {
                var lastIndex = points.length - 1;
                var prevXc = (points[lastIndex - 1].x + points[lastIndex].x) / 2;
                var prevYc = (points[lastIndex - 1].y + points[lastIndex].y) / 2;
                ctx.bezierCurveTo(prevXc, prevYc, points[lastIndex].x, points[lastIndex].y, points[lastIndex].x, points[lastIndex].y);
              }

              // Close the path to fill area
              ctx.lineTo(points[points.length - 1].x, paddingTop + chartHeight);
              ctx.lineTo(paddingLeft, paddingTop + chartHeight);
              ctx.closePath();
              ctx.fill();

              // Draw smooth curve line
              ctx.strokeStyle = theme.button.text;
              ctx.lineWidth = ScalerService.s(3);
              ctx.lineJoin = "round";
              ctx.lineCap = "round";
              ctx.beginPath();

              // Move to first point
              ctx.moveTo(points[0].x, points[0].y);

              // Draw smooth curve through all points
              for (var j = 0; j < points.length - 1; j++) {
                var xc = (points[j].x + points[j + 1].x) / 2;
                var yc = (points[j].y + points[j + 1].y) / 2;

                if (j === 0) {
                  ctx.quadraticCurveTo(points[j].x, points[j].y, xc, yc);
                } else {
                  var prevXc = (points[j - 1].x + points[j].x) / 2;
                  var prevYc = (points[j - 1].y + points[j].y) / 2;
                  ctx.bezierCurveTo(prevXc, prevYc, points[j].x, points[j].y, xc, yc);
                }
              }

              // Draw last segment
              if (points.length > 1) {
                var lastIndex = points.length - 1;
                var prevXc = (points[lastIndex - 1].x + points[lastIndex].x) / 2;
                var prevYc = (points[lastIndex - 1].y + points[lastIndex].y) / 2;
                ctx.bezierCurveTo(prevXc, prevYc, points[lastIndex].x, points[lastIndex].y, points[lastIndex].x, points[lastIndex].y);
              }

              ctx.stroke();

              // Draw current usage value
              if (cpuHistory.length > 0) {
                var currentUsage = cpuHistory[cpuHistory.length - 1].usage;
                var currentX = paddingLeft + chartWidth;
                var currentY = points[points.length - 1].y;

                ctx.font = ScalerService.s(15) + "px 'ComicShannsMono Nerd Font'";
                ctx.fillText(currentUsage.toFixed(1) + "%", currentX + ScalerService.s(5), currentY - ScalerService.s(8));
              }
            }

            // Draw chart border
            ctx.strokeStyle = theme.normal.black;
            ctx.lineWidth = ScalerService.s(2);
            ctx.globalAlpha = 0.5;
            ctx.strokeRect(paddingLeft, paddingTop, chartWidth, chartHeight);
            ctx.globalAlpha = 1.0;
          }
        }
      }

    }
  }

  onCpuHistoryChanged: {
    cpuChart.requestPaint();
  }
}
