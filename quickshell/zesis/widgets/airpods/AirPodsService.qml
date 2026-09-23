pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import "../bluetooth"

Singleton {
    id: root

    readonly property bool connected: _state.connected
    readonly property int leftLevel: _state.left
    readonly property int rightLevel: _state.right
    readonly property int caseLevel: _state.caseVal
    readonly property bool leftCharging: _state.leftCharging
    readonly property bool rightCharging: _state.rightCharging
    readonly property bool caseCharging: _state.caseCharging
    readonly property bool leftEar: _state.leftEar
    readonly property bool rightEar: _state.rightEar
    readonly property string deviceName: _state.deviceName

    // internal state

    property string _activeMac: ""

    QtObject {
        id: _state
        property bool connected: false
        property int left: 0
        property int right: 0
        property int caseVal: 0
        property bool leftCharging: false
        property bool rightCharging: false
        property bool caseCharging: false
        property bool leftEar: false
        property bool rightEar: false
        property string deviceName: ""
    }

    // device watcher
    // For each Bluetooth device: when it connects, check if it's AirPods;
    // when it disconnects and it was our active device, stop the daemon.

    Instantiator {
        model: BluetoothService.activeAdapter?.devices.values ?? []

        delegate: QtObject {
            id: deviceWatcher
            required property var modelData
            property bool deviceConnected: modelData?.connected ?? false
            property bool ready: false
            Component.onCompleted: {
                ready = true;
                if (deviceWatcher.deviceConnected)
                    _checker.check(deviceWatcher.modelData.address, deviceWatcher.modelData.name || deviceWatcher.modelData.address);
            }

            onDeviceConnectedChanged: {
                if (!deviceWatcher.ready)
                    return;
                if (deviceWatcher.deviceConnected) {
                    _checker.check(deviceWatcher.modelData.address, deviceWatcher.modelData.name || deviceWatcher.modelData.address);
                } else if (deviceWatcher.modelData.address === root._activeMac) {
                    root._activeMac = "";
                    _daemon.running = false;
                    _state.connected = false;
                }
            }
        }
    }

    // UUID checker
    // One-shot: bluetoothctl info <mac> - looks for the AAP UUID in output.
    // Checks are queued so concurrent connect events don't race each other.

    Process {
        id: _checker
        property string _mac: ""
        property string _name: ""
        property var _queue: []

        function check(mac, name) {
            if (_daemon.running)
                return;
            if (running) {
                _queue.push({
                    mac: mac,
                    name: name
                });
                return;
            }
            _mac = mac;
            _name = name;
            command = ["bluetoothctl", "info", mac];
            running = true;
        }

        function _runNext() {
            if (_daemon.running || _queue.length === 0)
                return;
            const next = _queue.shift();
            _mac = next.mac;
            _name = next.name;
            command = ["bluetoothctl", "info", next.mac];
            running = true;
        }

        stdout: SplitParser {
            onRead: line => {
                if (!line.includes("74ec2172-0bad-4d01-8f77-997b2be0722a"))
                    return;
                if (_daemon.running)
                    return;
                root._activeMac = _checker._mac;
                _state.deviceName = _checker._name;
                _checker._queue = [];
                _daemon.running = true;
            }
        }

        onRunningChanged: {
            if (!running)
                Qt.callLater(_checker._runNext);
        }
    }

    // daemon
    // Persistent: connects, does AAP handshake, streams JSON on state changes.
    // Has its own reconnect loop, QML just owns start/stop.

    Process {
        id: _daemon
        readonly property string _script: Qt.resolvedUrl("airpods_battery.py").toString().slice(7)
        command: ["python", _script, root._activeMac]

        stdout: SplitParser {
            onRead: line => {
                if (line.startsWith("#"))
                    return;
                try {
                    const d = JSON.parse(line);
                    _state.connected = d.connected ?? false;
                    _state.left = d.left ?? 0;
                    _state.right = d.right ?? 0;
                    _state.caseVal = d.case ?? 0;
                    _state.leftCharging = d.left_charging ?? false;
                    _state.rightCharging = d.right_charging ?? false;
                    _state.caseCharging = d.case_charging ?? false;
                    _state.leftEar = d.left_ear ?? false;
                    _state.rightEar = d.right_ear ?? false;
                } catch (e) {}
            }
        }

        onRunningChanged: {
            if (!running)
                _state.connected = false;
        }
    }
}
