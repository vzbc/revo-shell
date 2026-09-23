import QtQuick
import Quickshell.Networking

QtObject {
    id: root

    readonly property bool ready: Networking.backend !== NetworkBackendType.None
    readonly property var devices: Networking.devices.values
    readonly property var wifiDevice: findDevice(DeviceType.Wifi, false)
    readonly property var activeDevice: findDevice(DeviceType.None, true)
    readonly property var activeWifiNetwork: findActiveWifiNetwork()
    readonly property bool wifiAvailable: ready && wifiDevice !== null && Networking.wifiHardwareEnabled
    readonly property bool wifiEnabled: ready && Networking.wifiEnabled
    readonly property bool connected: activeDevice !== null
    readonly property real signalStrength: normalizedSignalStrength()
    readonly property string networkName: activeWifiNetwork !== null ? activeWifiNetwork.name : (connected ? "Wired" : "Offline")
    readonly property string statusText: !ready ? "Network unavailable" : (!wifiEnabled ? "Wi-Fi off" : (activeWifiNetwork !== null ? "Connected to " + networkName : (connected ? networkName + " connected" : "Wi-Fi disconnected")))

    function findDevice(type, connectedOnly) {
        const list = devices || [];
        for (let i = 0; i < list.length; i++) {
            const device = list[i];
            const typeMatches = type === DeviceType.None || device.type === type;
            if (typeMatches && (!connectedOnly || device.connected))
                return device;

        }
        return null;
    }

    function findActiveWifiNetwork() {
        if (wifiDevice === null || wifiDevice.networks === null)
            return null;

        const list = wifiDevice.networks.values || [];
        for (let i = 0; i < list.length; i++) {
            if (list[i].connected)
                return list[i];

        }
        return null;
    }

    function normalizedSignalStrength() {
        if (activeWifiNetwork === null)
            return 0;

        const raw = Number(activeWifiNetwork.signalStrength);
        if (!isFinite(raw))
            return 0;

        return Math.max(0, Math.min(1, raw > 1 ? raw / 100 : raw));
    }

    function toggleWifi() {
        if (wifiAvailable)
            Networking.wifiEnabled = !Networking.wifiEnabled;

    }

}
