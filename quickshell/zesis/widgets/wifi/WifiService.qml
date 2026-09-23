pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Networking

Singleton {
    id: root

    // Set true to use fake networks instead of real NetworkManager
    property bool testMode: false

    // Real WiFi device
    readonly property var _realDevice: {
        for (var i = 0; i < Networking.devices.values.length; i++) {
            var d = Networking.devices.values[i];
            if (d.type === DeviceType.Wifi)
                return d;
        }
        return null;
    }

    // Ethernet (wired) device
    readonly property var wiredDevice: {
        for (var i = 0; i < Networking.devices.values.length; i++) {
            var d = Networking.devices.values[i];
            if (d.type === DeviceType.Wired && d.connected)
                return d;
        }
        return null;
    }

    readonly property bool onEthernet: wiredDevice !== null

    // Public properties
    readonly property bool available: testMode || (_realDevice !== null)
    property bool _testEnabled: true
    readonly property bool enabled: testMode ? _testEnabled : (_realDevice !== null && Networking.wifiEnabled)
    readonly property bool showInBar: available || onEthernet

    readonly property var activeNetwork: {
        if (testMode) {
            for (var i = 0; i < _testNetworks.length; i++)
                if (_testNetworks[i].connected)
                    return _testNetworks[i];
            return null;
        }
        if (!_realDevice)
            return null;
        var nets = _realDevice.networks.values;
        for (var i = 0; i < nets.length; i++)
            if (nets[i].connected)
                return nets[i];
        return null;
    }

    readonly property bool connected: activeNetwork !== null
    readonly property string ssid: activeNetwork ? activeNetwork.name : ""
    readonly property real signalStrength: activeNetwork ? activeNetwork.signalStrength : 0.0

    readonly property var networks: {
        if (testMode)
            return _testNetworks;
        if (!_realDevice)
            return [];
        return _realDevice.networks.values.slice().sort((a, b) => b.signalStrength - a.signalStrength);
    }

    function signalIcon(strength) {
        if (strength >= 0.75)
            return "󰤨";
        if (strength >= 0.5)
            return "󰤥";
        if (strength >= 0.25)
            return "󰤢";
        if (strength > 0)
            return "󰤟";
        return "󰤯";
    }

    function barIcon() {
        if (onEthernet && !connected)
            return "󰈀";
        if (!available || !enabled || !connected)
            return "󰤭";
        return signalIcon(signalStrength);
    }

    function needsPsk(network) {
        if (network.testPsk !== undefined)
            return network.testPsk;
        return network.security === WifiSecurityType.WpaPsk || network.security === WifiSecurityType.Wpa2Psk || network.security === WifiSecurityType.Sae;
    }

    function setEnabled(val) {
        if (testMode)
            _testEnabled = val;
        else
            Networking.wifiEnabled = val;
    }

    readonly property var _testNetworks: [tn1, tn2, tn3, tn4, tn5]

    // Connected, known, secured
    QtObject {
        id: tn1
        property string name: "HomeNetwork_5G"
        property real signalStrength: 0.92
        property bool connected: true
        property bool known: true
        property bool stateChanging: false
        property bool testPsk: true
        signal connectionFailed(var reason)
        function connect() {
        }
        function connectWithPsk(psk) {
        }
        function disconnect() {
            tn1.connected = false;
        }
        function forget() {
            tn1.known = false;
            tn1.connected = false;
        }
    }

    // Open network, unknown
    QtObject {
        id: tn2
        property string name: "CoffeeShop_Guest"
        property real signalStrength: 0.71
        property bool connected: false
        property bool known: false
        property bool stateChanging: false
        property bool testPsk: false
        signal connectionFailed(var reason)
        function connect() {
            tn2.stateChanging = true;
            Qt.callLater(function () {
                tn2.stateChanging = false;
                tn2.connected = true;
                tn2.known = true;
            });
        }
        function connectWithPsk(psk) {
        }
        function disconnect() {
            tn2.connected = false;
        }
        function forget() {
            tn2.known = false;
        }
    }

    // Secured, unknown, needs PSK; password must be ≥8 chars to succeed
    QtObject {
        id: tn3
        property string name: "NeighborNet"
        property real signalStrength: 0.48
        property bool connected: false
        property bool known: false
        property bool stateChanging: false
        property bool testPsk: true
        signal connectionFailed(var reason)
        function connect() {
            Qt.callLater(function () {
                tn3.connectionFailed(null);
            });
        }
        function connectWithPsk(psk) {
            tn3.stateChanging = true;
            Qt.callLater(function () {
                tn3.stateChanging = false;
                if (psk.length >= 8) {
                    tn3.connected = true;
                    tn3.known = true;
                } else
                    tn3.connectionFailed(null);
            });
        }
        function disconnect() {
            tn3.connected = false;
        }
        function forget() {
            tn3.known = false;
        }
    }

    // Secured, already saved, connects directly
    QtObject {
        id: tn4
        property string name: "ApartmentWifi_2G"
        property real signalStrength: 0.29
        property bool connected: false
        property bool known: true
        property bool stateChanging: false
        property bool testPsk: true
        signal connectionFailed(var reason)
        function connect() {
            tn4.stateChanging = true;
            Qt.callLater(function () {
                tn4.stateChanging = false;
                tn4.connected = true;
            });
        }
        function connectWithPsk(psk) {
        }
        function disconnect() {
            tn4.connected = false;
        }
        function forget() {
            tn4.known = false;
        }
    }

    // Weak signal, secured, unknown
    QtObject {
        id: tn5
        property string name: "DIRECT-OfficeNet"
        property real signalStrength: 0.11
        property bool connected: false
        property bool known: false
        property bool stateChanging: false
        property bool testPsk: true
        signal connectionFailed(var reason)
        function connect() {
            Qt.callLater(function () {
                tn5.connectionFailed(null);
            });
        }
        function connectWithPsk(psk) {
            tn5.stateChanging = true;
            Qt.callLater(function () {
                tn5.stateChanging = false;
                if (psk.length >= 8) {
                    tn5.connected = true;
                    tn5.known = true;
                } else
                    tn5.connectionFailed(null);
            });
        }
        function disconnect() {
            tn5.connected = false;
        }
        function forget() {
            tn5.known = false;
        }
    }
}
