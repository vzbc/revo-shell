pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import "../../"

Singleton {
    id: root

    property BluetoothAdapter activeAdapter: Bluetooth.defaultAdapter

    readonly property string _configPath: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/zesis/bluetooth.json"

    function selectAdapter(adapter) {
        root.activeAdapter = adapter;
        _writeProc.command = ["sh", "-c", "mkdir -p \"$(dirname '" + root._configPath + "')\" && echo '{\"preferredAdapter\":\"" + adapter.dbusPath + "\"}' > '" + root._configPath + "'"];
        _writeProc.running = true;
    }

    function _restoreAdapter() {
        if (!_btConfig.preferredAdapter)
            return;
        const match = Bluetooth.adapters.values.find(a => a.dbusPath === _btConfig.preferredAdapter);
        if (match)
            root.activeAdapter = match;
    }

    JsonAdapter {
        id: _btConfig
        property string preferredAdapter: ""
    }

    FileView {
        path: root._configPath
        adapter: _btConfig
        onLoaded: root._restoreAdapter()
    }

    Connections {
        target: Bluetooth.adapters
        function onValuesChanged() {
            root._restoreAdapter();
        }
    }

    Process {
        id: _writeProc
    }

    function deviceIcon(iconStr, deviceName) {
        var i = (iconStr || "").toLowerCase();
        var n = (deviceName || "").toLowerCase();
        if (i.includes("headphone") || i.includes("headset"))
            return "󰋋";
        if (i.includes("audio"))
            return "󰓃";
        if (i.includes("gaming") || i.includes("joystick"))
            return "󰊱";
        if (i.includes("keyboard"))
            return "󰌌";
        if (i.includes("mouse"))
            return "󰍽";
        if (i.includes("tablet"))
            return "󰓶";
        if (i.includes("phone"))
            return "󰄜";
        if (i.includes("computer") || i.includes("laptop"))
            return "󰌢";
        if (i.includes("camera"))
            return "󰄀";
        if (i.includes("printer"))
            return "󰐪";
        if (i.includes("watch"))
            return "󰖉";
        if (i.includes("multimedia") || i.includes("speaker"))
            return "󰓃";
        if (n.includes("headphone") || n.includes("headset") || n.includes("airpod") || n.includes("earbud") || n.includes("buds"))
            return "󰋋";
        if (n.includes("controller") || n.includes("dualsense") || n.includes("gamepad") || n.includes("xbox"))
            return "󰊱";
        if (n.includes("keyboard"))
            return "󰌌";
        if (n.includes("mouse"))
            return "󰍽";
        if (n.includes("phone"))
            return "󰄜";
        return "󰂯";
    }

    function batteryColor(level) {
        if (level < 0.2)
            return "#e05c5c";
        if (level < 0.35)
            return "#e0a85c";
        return Colors.accent;
    }

    readonly property bool available: Bluetooth.adapters.values.length > 0
    readonly property bool powered: activeAdapter?.enabled ?? false
    readonly property bool scanning: activeAdapter?.discovering ?? false

    readonly property var pairedDevices: {
        if (!activeAdapter)
            return [];
        return activeAdapter.devices.values.filter(d => d.bonded).sort((a, b) => (b.connected - a.connected) || (a.name || a.address).localeCompare(b.name || b.address));
    }

    readonly property var nearbyDevices: {
        if (!activeAdapter)
            return [];
        return activeAdapter.devices.values.filter(d => !d.bonded).sort((a, b) => (b.pairing - a.pairing) || (a.name || a.address).localeCompare(b.name || b.address));
    }

    function startScan() {
        if (activeAdapter?.enabled)
            activeAdapter.discovering = true;
    }

    function stopScan() {
        if (activeAdapter)
            activeAdapter.discovering = false;
    }

    // Battery warning state per device, { [address]: { w15: bool, w5: bool } }
    // Called by Bluetooth.qml delegate on every sysfs poll or GATT battery change.
    property var _battWarnings: ({})

    function checkBatteryWarning(address, pct, name) {
        if (pct < 0)
            return;
        var w = _battWarnings[address] || {
            w15: false,
            w5: false
        };
        if (pct > 0.15) {
            _battWarnings[address] = {
                w15: false,
                w5: false
            };
            return;
        }
        if (pct <= 0.05 && !w.w5) {
            w.w5 = true;
            _battWarnings[address] = w;
            _notifyProc.command = ["notify-send", "-u", "critical", "-i", "battery-caution", "Bluetooth Battery Critical", name + " is at " + Math.round(pct * 100) + "%. Charge it soon."];
            _notifyProc.running = true;
        } else if (pct <= 0.15 && !w.w15) {
            w.w15 = true;
            _battWarnings[address] = w;
            _notifyProc.command = ["notify-send", "-u", "normal", "-i", "battery-low", "Bluetooth Battery Low", name + " is at " + Math.round(pct * 100) + "%."];
            _notifyProc.running = true;
        }
    }

    function _notify(urgency, icon, summary, body) {
        _notifyProc.command = icon !== "" ? ["notify-send", "-u", urgency, "-i", icon, summary, body] : ["notify-send", "-u", urgency, summary, body];
        _notifyProc.running = true;
    }

    property string _pairingAddress: ""

    // bluetoothctl registers itself as a BlueZ pairing agent on startup, which answers
    // the RequestAuthorization D-Bus callback that Quickshell has no agent for.
    // We spawn it for the duration of pairing, then kill it.
    function pairDevice(device) {
        root._pairingAddress = device.address;
        _agentProc.running = true;
        _pairTimeout.restart();
        device.pair();
    }

    function cancelPairDevice(device) {
        root._pairingAddress = "";
        _agentProc.running = false;
        _pairTimeout.stop();
        device.cancelPair();
    }

    Process {
        id: _agentProc
        command: ["bluetoothctl", "--agent", "NoInputNoOutput"]
    }

    Timer {
        id: _pairTimeout
        interval: 30000
        repeat: false
        onTriggered: {
            root._pairingAddress = "";
            _agentProc.running = false;
        }
    }

    Instantiator {
        model: root.activeAdapter?.devices.values ?? []

        delegate: QtObject {
            id: deviceWatcher
            required property var modelData
            property bool deviceConnected: modelData?.connected ?? false
            property bool deviceBonded: modelData?.bonded ?? false
            property bool ready: false

            Component.onCompleted: {
                deviceWatcher.ready = true;
            }

            onDeviceConnectedChanged: {
                if (!deviceWatcher.ready)
                    return;
                const devName = deviceWatcher.modelData.name || deviceWatcher.modelData.address;
                if (deviceWatcher.deviceConnected)
                    root._notify("low", "", "Connected", devName);
                else
                    root._notify("low", "", "Disconnected", devName);
            }

            onDeviceBondedChanged: {
                if (!deviceWatcher.ready || !deviceWatcher.deviceBonded)
                    return;
                if (deviceWatcher.modelData.address === root._pairingAddress) {
                    root._pairingAddress = "";
                    _agentProc.running = false;
                    _pairTimeout.stop();
                }
            }
        }
    }

    onScanningChanged: {
        if (scanning)
            _scanTimeout.restart();
        else
            _scanTimeout.stop();
    }

    Timer {
        id: _scanTimeout
        interval: 30000
        repeat: false
        onTriggered: root.stopScan()
    }

    Process {
        id: _notifyProc
    }
}
