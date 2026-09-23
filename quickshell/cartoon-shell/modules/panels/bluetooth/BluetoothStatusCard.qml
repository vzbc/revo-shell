// Status card component for Bluetooth panel
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components
import qs.commons

Rectangle {
    id: root
    required property var adapter
    required property int connectedCount

    Layout.fillWidth: true
    height: ScalerService.s(82)
    radius: ScalerService.s(Settings.appearance.radius2)
    color: Qt.alpha(theme.primary.dim_background, 0.5)
    border.color: theme.button.border
    border.width: Settings.appearance.enableBorder ? ScalerService.s(2) : 0

    RowLayout {
        anchors.fill: parent
        anchors.margins: ScalerService.s(14)
        spacing: ScalerService.s(12)

        // Left column: status and device count
        ColumnLayout {
            Layout.fillWidth: true
            spacing: ScalerService.s(4)

            CustomText {
                name: adapter?.enabled ? (lang?.bluetooth?.enabled || "Bluetooth đang bật") : (lang?.bluetooth?.disabled || "Bluetooth đang tắt")
                textColor: adapter?.enabled ? theme.button.text : theme.primary.dim_foreground
                isBold: true
            }
            Item {
                Layout.fillHeight: true
            }

            CustomText {
                name: `${connectedCount} ` + (lang?.bluetooth?.devices_connected || "thiết bị đã kết nối")
                textColor: theme.primary.dim_foreground
                size: "small"
                visible: adapter?.enabled || false
            }
        }

        Item {
            Layout.fillWidth: true
        }

        CustomToggleSwitch {
            adapter: root.adapter.enabled
            onClicked: {
                if (root.adapter) {
                    root.adapter.enabled = !root.adapter.enabled;
                    if (root.adapter.enabled) {
                        // When enabling Bluetooth, set necessary modes
                        root.adapter.pairable = true;
                        root.adapter.discoverable = true;
                    }
                }
            }
        }
    }
}
