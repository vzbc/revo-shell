// Device list component for Bluetooth panel
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Bluetooth
import qs.services
import "." as Components

Item {
    id: deviceListRoot
    required property var adapter
    required property int connectedCount

    signal pairError(string message)

    Layout.fillWidth: true
    Layout.fillHeight: true
    clip: true
    visible: adapter?.enabled || false

    ColumnLayout {
        anchors.fill: parent
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            ListView {
                id: deviceList
                model: Bluetooth.devices
                spacing: ScalerService.s(4)
                boundsBehavior: Flickable.StopAtBounds

                delegate: Components.BluetoothDeviceItem {
                    adapter: deviceListRoot.adapter
                    onPairError: function (message) {
                        deviceListRoot.pairError(message);
                    }
                }

                // Empty state message
                Text {
                    anchors.centerIn: parent
                    text: {
                        if (!adapter?.enabled)
                            return lang?.bluetooth?.disabled || "Bluetooth đã tắt";
                        if (adapter?.discovering && deviceList.count === 0)
                            return "🔍 " + (lang?.bluetooth?.searching || "Đang tìm kiếm thiết bị...");
                        if (deviceList.count === 0)
                            return lang?.bluetooth?.no_devices || "Không có thiết bị nào";
                        return "";
                    }
                    color: theme.primary.dim_foreground
                    font.pixelSize: ScalerService.s(13)
                    visible: text !== ""
                }
            }
        }
    }
}
