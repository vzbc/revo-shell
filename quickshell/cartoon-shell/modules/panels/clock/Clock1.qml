import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.components

PanelWindow {
    id: root

    WlrLayershell.exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Bottom

    property string currentTime: "00:00"
    property string currentDateText: ""

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    margins {
        top: ScalerService.s(20)
        bottom: ScalerService.s(20)
        left: ScalerService.s(20)
        right: ScalerService.s(20)
    }

    color: "transparent"

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
        onDateChanged: root.updateDateTime()
    }

    function updateDateTime() {
        const now = new Date();

        // Lấy thứ trong tuần
        const dayData = lang?.dateFormat?.day;
        const weekdays = dayData ? [dayData.sunday || "Sunday", dayData.monday || "Monday", dayData.tuesday || "Tuesday", dayData.wednesday || "Wednesday", dayData.thursday || "Thursday", dayData.friday || "Friday", dayData.saturday || "Saturday"] : ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];

        const dayName = weekdays[now.getDay()];
        const dayNum = now.getDate();

        // Định dạng chuỗi ngày dạng: "Tuesday, 16"
        root.currentDateText = `${dayName}, ${dayNum}`;

        // Định dạng thời gian dạng: "21:30"
        root.currentTime = Qt.formatTime(now, "HH:mm");
    }

    // --- BỐ CỤC CĂN GIỮA NẰM DỌC ---
    ColumnLayout {
        anchors.centerIn: parent
        spacing: -ScalerService.s(10) // Giảm khoảng cách để sát với thiết kế mẫu

        // Hàng 1: Thứ, Ngày (VD: Tuesday, 16)
        CustomText {
            name: root.currentDateText
            isBold: false
            textColor: theme.primary.background
            font.pixelSize: ScalerService.s(28)
            Layout.alignment: Qt.AlignHCenter
        }

        // Hàng 2: Giờ : Phút (VD: 21:30)
        CustomText {
            name: root.currentTime
            isBold: true
            textColor: theme.primary.background
            font.pixelSize: ScalerService.s(120)
            Layout.alignment: Qt.AlignHCenter
        }
    }

    Component.onCompleted: {
        root.updateDateTime();
    }
}
