import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import qs.services
import qs.commons
import qs.components
import "."

ColumnLayout {
    id: root
    property bool isVertical: true
    property real animationProgress: 0
    anchors.fill: parent
    spacing: ScalerService.s(8)
    Item {
        visible: TrayService.hasTray
        Layout.fillHeight: true
    }

    // System Tray Icons
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
        Layout.fillHeight: true
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
        Layout.fillHeight: true
    }

    // Wifi
    StatContainer {
        Layout.fillWidth: true
        Layout.fillHeight: true
        opacity: root.animationProgress > 0.65 ? 1 : 0
        panelName: "wifi"

        WifiStat {
            anchors.centerIn: parent
        }
    }

    Item {
        Layout.fillHeight: true
    }

    // Volume
    StatContainer {
        Layout.fillWidth: true
        Layout.fillHeight: true
        opacity: root.animationProgress > 0.7 ? 1 : 0
        panelName: "mixer"

        VolumeStat {
            anchors.centerIn: parent
        }
    }

    Item {
        Layout.fillHeight: true
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
        Layout.fillHeight: true
        visible: UPower.displayDevice.isLaptopBattery
    }

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
        Layout.fillHeight: true
    }

    StatContainer {
        Layout.fillWidth: true
        Layout.fillHeight: true
        opacity: root.animationProgress > 0.85 ? 1 : 0
        panelName: "dashboard"

        IconImage {
            path: '/system/poweroff.png'
            anchors.centerIn: parent
        }
    }
    Item {
        visible: TrayService.hasTray
        Layout.fillHeight: true
    }
}
