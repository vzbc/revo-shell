import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import qs.services
import qs.commons
import qs.components
import "."

RowLayout {
    id: root
    property bool isVertical: false
    property real animationProgress: 0
    anchors.fill: parent
    spacing: ScalerService.s(5)

    Item {
        Layout.fillWidth: true
    }

    // Tray
    StatContainer {
        Layout.fillWidth: true
        Layout.fillHeight: true
        panelName: "tray"

        visible: TrayService.hasTray
        opacity: root.animationProgress > 0.55 ? 1 : 0

        TrayStat {
            anchors.centerIn: parent
        }
    }

    Item {
        visible: TrayService.hasTray
        Layout.fillWidth: true
    }

    // Bluetooth
    StatContainer {
        Layout.fillWidth: true
        Layout.fillHeight: true
        panelName: "bluetooth"
        opacity: root.animationProgress > 0.6 ? 1 : 0

        BluetoothStat {
            anchors.centerIn: parent
        }
    }

    Item {
        Layout.fillWidth: true
    }

    // Wifi
    StatContainer {
        Layout.fillWidth: true
        Layout.fillHeight: true
        panelName: "wifi"
        opacity: root.animationProgress > 0.65 ? 1 : 0

        WifiStat {
            anchors.centerIn: parent
        }
    }

    Item {
        Layout.fillWidth: true
    }

    // Volume
    StatContainer {
        Layout.fillWidth: true
        Layout.fillHeight: true
        panelName: "mixer"
        opacity: root.animationProgress > 0.7 ? 1 : 0

        VolumeStat {
            anchors.centerIn: parent
        }
    }

    Item {
        Layout.fillWidth: true
    }

    // Brightness
    StatContainer {
        Layout.fillWidth: true
        Layout.fillHeight: true
        opacity: root.animationProgress > 0.75 ? 1 : 0

        BrightnessStat {
            anchors.centerIn: parent
        }
    }

    Item {
        Layout.fillWidth: true
        visible: UPower.displayDevice.isLaptopBattery
    }

    // Battery
    StatContainer {
        Layout.fillWidth: true
        Layout.fillHeight: true
        opacity: root.animationProgress > 0.8 ? 1 : 0
        panelName: "battery"
        visible: UPower.displayDevice.isLaptopBattery

        BatteryStat {
            anchors.centerIn: parent
        }
    }

    Item {
        Layout.fillWidth: true
    }

    // Power Off
    StatContainer {
        Layout.fillWidth: true
        Layout.fillHeight: true
        panelName: "dashboard"
        opacity: root.animationProgress > 0.85 ? 1 : 0

        IconImage {
            path: '/system/poweroff.png'
            anchors.centerIn: parent
        }
    }
    Item {
        Layout.fillWidth: true
    }
}
