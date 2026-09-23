import QtQuick
import Quickshell.Bluetooth

QtObject {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool available: adapter !== null
    readonly property bool enabled: available && adapter.enabled
    readonly property var connectedDevices: findConnectedDevices()
    readonly property int connectedCount: connectedDevices.length
    readonly property string connectedName: connectedCount > 0 ? connectedDevices[0].name : ""
    readonly property string statusText: !available ? "Bluetooth unavailable" : (!enabled ? "Bluetooth off" : (connectedCount > 0 ? connectedName + " connected" : "Bluetooth on"))

    function findConnectedDevices() {
        const devices = Bluetooth.devices.values || [];
        const connected = [];
        for (let i = 0; i < devices.length; i++) {
            if (devices[i].connected)
                connected.push(devices[i]);

        }
        return connected;
    }

    function toggleEnabled() {
        if (available)
            adapter.enabled = !adapter.enabled;

    }

}
