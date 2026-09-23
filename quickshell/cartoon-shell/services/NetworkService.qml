pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: networkService

    // Properties
    property string connectedWifi: "Checking..."
    property string wifi_icon: "wifi/wifi.png"
    property string wifi_icon_text_1: "wifi_1_bar"
    property string wifi_icon_text_2: "network_wifi_1_bar"
    property int signal_current: 0

    // Signals
    signal wifiUpdated

    // Processes
    Process {
        id: connectedWifiProcess
        command: ["nmcli", "-t", "-f", "NAME", "connection", "show", "--active"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text) {
                    const lines = this.text.trim().split('\n');
                    for (var i = 0; i < lines.length; i++) {
                        var conn = lines[i];
                        if (conn && conn !== "lo" && !conn.startsWith("Wired")) {
                            networkService.connectedWifi = conn;
                            return;
                        }
                    }
                    networkService.connectedWifi = "Disconnected";
                    wifi_icon = "wifi/no-wifi.png";
                }
            }
        }
    }

    Process {
        id: wifiSignalProcess
        command: ["bash", "-c", "nmcli -t -f ACTIVE,SIGNAL dev wifi | grep '^yes' | cut -d: -f2"]
        stdout: StdioCollector {}
        running: false
        onRunningChanged: {
            if (!running && stdout.text) {
                var resultText = stdout.text.trim();
                if (resultText) {
                    var result = parseInt(resultText);
                    if (!isNaN(result)) {
                        networkService.signal_current = result;
                    } else {
                        networkService.signal_current = 0;
                    }
                } else {
                    networkService.signal_current = 0;
                }
                networkService.updateWifiIcon();
                networkService.wifiUpdated();
            }
        }
    }

    // Functions
    function updateWifi() {
        if (!connectedWifiProcess.running) {
            connectedWifiProcess.running = true;
        }
    }

    function updateSignalWifi() {
        if (!wifiSignalProcess.running) {
            wifiSignalProcess.running = true;
        }
    }

    function updateWifiIcon() {
        var signal = networkService.signal_current || 0;
        if (signal <= 40) {
            networkService.wifi_icon = "wifi/wifi_1.png";
            networkService.wifi_icon_text_1 = "wifi_1_bar";
            networkService.wifi_icon_text_2 = "network_wifi_1_bar";
        } else if (signal <= 70) {
            networkService.wifi_icon = "wifi/wifi_2.png";
            networkService.wifi_icon_text_1 = "wifi_2_bar";
            networkService.wifi_icon_text_2 = "network_wifi_3_bar";
        } else {
            networkService.wifi_icon = "wifi/wifi.png";
            networkService.wifi_icon_text_1 = "android_wifi_3_bar";
            networkService.wifi_icon_text_2 = "signal_wifi_4_bar";
        }
    }

    // Timers
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: networkService.updateWifi()
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: networkService.updateSignalWifi()
    }
}
