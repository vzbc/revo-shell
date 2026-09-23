pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool wifiOn: false
    property bool wifiConnected: false
    property string wifiSsid: ""
    property bool ethernetConnected: false
    property bool bluetoothOn: false
    property var wifiNetworks: []   // list of SSID strings

    function poll() {
        _wifiRadio.running = true;
        _deviceStatus.running = true;
        _wifiList.running = true;
        _wifiScan.running = true;
        _bluetoothShow.running = true;
    }

    function connectSsid(ssid) {
        _connect.command = ["bash", "-c", "timeout 20 nmcli device wifi connect '" + ssid.replace(/'/g, "'\\''") + "'"];
        _connect.running = true;
    }

    function toggleWifi() {
        const on = !root.wifiOn;
        _toggleWifi.command = ["nmcli", "radio", "wifi", on ? "on" : "off"];
        _toggleWifi.running = true;
        root.wifiOn = on;
    }

    function toggleBluetooth() {
        const on = !root.bluetoothOn;
        _toggleBt.command = ["bash", "-c", "timeout 5 bluetoothctl power " + (on ? "on" : "off")];
        _toggleBt.running = true;
        root.bluetoothOn = on;
    }

    Process {
        id: _wifiRadio
        running: false
        command: ["nmcli", "radio", "wifi"]
        environment: ({ LANG: "C", LC_ALL: "C" })
        stdout: StdioCollector {
            onStreamFinished: root.wifiOn = text.trim() === "enabled"
        }
    }

    Process {
        id: _deviceStatus
        running: false
        command: ["nmcli", "-t", "-f", "DEVICE,TYPE,STATE", "device", "status"]
        environment: ({ LANG: "C", LC_ALL: "C" })
        stdout: StdioCollector {
            onStreamFinished: {
                root.wifiConnected = false;
                root.ethernetConnected = false;
                for (const line of text.split("\n")) {
                    const parts = line.split(":");
                    if (parts.length < 3) continue;
                    const device = parts[0];
                    const type = parts[1];
                    const state = parts[2];
                    if (state !== "connected") continue;
                    if (type === "wifi") root.wifiConnected = true;
                    if (type === "ethernet") root.ethernetConnected = true;
                }
            }
        }
    }

    Process {
        id: _wifiList
        running: false
        command: ["nmcli", "-t", "-f", "ACTIVE,SSID", "device", "wifi"]
        environment: ({ LANG: "C", LC_ALL: "C" })
        stdout: StdioCollector {
            onStreamFinished: {
                let found = "";
                for (const line of text.split("\n")) {
                    const i = line.indexOf(":");
                    if (i < 0) continue;
                    if (line.slice(0, i) === "yes") { found = line.slice(i + 1); break; }
                }
                root.wifiSsid = found;
            }
        }
    }

    Process {
        id: _wifiScan
        running: false
        command: ["bash", "-c", "nmcli -t -f SSID device wifi list 2>/dev/null | sort -u"]
        stdout: StdioCollector {
            onStreamFinished: {
                const list = [];
                for (const line of text.split("\n")) {
                    const s = line.trim();
                    if (s && !list.includes(s)) list.push(s);
                }
                root.wifiNetworks = list;
            }
        }
    }

    Process {
        id: _connect
        running: false
        stdout: StdioCollector {}
        stderr: StdioCollector {}
    }

    Process {
        id: _bluetoothShow
        running: false
        command: ["bash", "-c", "timeout 5 bluetoothctl show"]
        stdout: StdioCollector {
            onStreamFinished: root.bluetoothOn = /Powered: yes/.test(text)
        }
    }

    Process {
        id: _toggleWifi
        running: false
        stdout: StdioCollector {}
        stderr: StdioCollector {}
    }

    Process {
        id: _toggleBt
        running: false
        stdout: StdioCollector {}
        stderr: StdioCollector {}
    }

    Timer {
        interval: 4000
        running: true
        repeat: true
        onTriggered: root.poll()
    }

    Component.onCompleted: root.poll()
}
