pragma Singleton
pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // ── Public state ──────────────────────────────────────────────
    readonly property list<AccessPoint> networks: []
    readonly property AccessPoint active: networks.find(n => n.active) ?? null
    property bool wifiEnabled: false
    readonly property bool scanning: rescanProc.running

    // Convenience props (drop-in replacements for old networkName / networkStrength / wifiStatus)
    readonly property bool connected: active !== null
    readonly property string networkName: active?.ssid ?? "Not Connected"
    readonly property int networkStrength: active?.strength ?? 0
    readonly property string wifiStatus: {
        if (!wifiEnabled)
            return "disabled";
        if (active)
            return "connected";
        return "disconnected";
    }

    // ── Public API ────────────────────────────────────────────────
    function toggleWifi(): void {
        enableWifiProc.command = ["nmcli", "radio", "wifi", wifiEnabled ? "off" : "on"];
        enableWifiProc.running = true;
    }

    function rescanWifi(): void {
        rescanProc.running = true;
    }

    function scanNetworks(): void {
        getNetworks.running = true;
    }

    function update(): void {
        wifiStatusProc.running = true;
        getNetworks.running = true;
    }

    // ── nmcli monitor ─────────────────────────────────────────────
    Process {
        id: subscriber
        command: ["nmcli", "monitor"]
        running: true
        stdout: SplitParser {
            onRead: root.update()
        }
    }

    // ── Wifi enabled/disabled ─────────────────────────────────────
    Process {
        id: wifiStatusProc
        running: true
        command: ["nmcli", "radio", "wifi"]
        environment: ({
                LANG: "C.UTF-8",
                LC_ALL: "C.UTF-8"
            })
        stdout: StdioCollector {
            onStreamFinished: {
                root.wifiEnabled = text.trim() === "enabled";
            }
        }
    }

    // ── Toggle wifi on/off ────────────────────────────────────────
    Process {
        id: enableWifiProc
        onExited: root.update()
    }

    // ── Rescan trigger ────────────────────────────────────────────
    Process {
        id: rescanProc
        command: ["nmcli", "dev", "wifi", "list", "--rescan", "yes"]
        onExited: getNetworks.running = true
    }

    // ── Single consolidated network list fetch ────────────────────
    Process {
        id: getNetworks
        running: true
        command: ["nmcli", "-g", "ACTIVE,SIGNAL,FREQ,SSID,BSSID,SECURITY", "d", "w"]
        environment: ({
                LANG: "C.UTF-8",
                LC_ALL: "C.UTF-8"
            })
        stdout: StdioCollector {
            onStreamFinished: {
                const PLACEHOLDER = "STRINGWHICHHOPEFULLYWONTBEUSED";
                const repColon = new RegExp("\\\\:", "g");
                const repBack = new RegExp(PLACEHOLDER, "g");

                const allNetworks = text.trim().split("\n").map(line => {
                    const parts = line.replace(repColon, PLACEHOLDER).split(":");
                    return {
                        active: parts[0] === "yes",
                        strength: parseInt(parts[1]),
                        frequency: parseInt(parts[2]),
                        ssid: parts[3]?.replace(repBack, ":") ?? "",
                        bssid: parts[4]?.replace(repBack, ":") ?? "",
                        security: parts[5] ?? ""
                    };
                }).filter(n => n.ssid && n.ssid.length > 0);

                // Deduplicate by SSID+BSSID+freq, prefer active, then stronger signal
                const networkMap = new Map();
                for (const n of allNetworks) {
                    const key = `${n.ssid}|${n.bssid}|${n.frequency}`;
                    const existing = networkMap.get(key);
                    if (!existing) {
                        networkMap.set(key, n);
                    } else if (n.active && !existing.active) {
                        networkMap.set(key, n);
                    } else if (!n.active && !existing.active && n.strength > existing.strength) {
                        networkMap.set(key, n);
                    }
                }

                const fresh = Array.from(networkMap.values());
                const rNetworks = root.networks;

                // Destroy stale objects
                const stale = rNetworks.filter(rn => !fresh.find(n => n.bssid === rn.bssid && n.ssid === rn.ssid && n.frequency === rn.frequency));
                for (const n of stale)
                    rNetworks.splice(rNetworks.indexOf(n), 1).forEach(o => o.destroy());

                // Update existing or create new
                for (const n of fresh) {
                    const match = rNetworks.find(rn => rn.bssid === n.bssid && rn.ssid === n.ssid && rn.frequency === n.frequency);
                    if (match) {
                        match.lastIpcObject = n;
                    } else {
                        rNetworks.push(apComp.createObject(root, {
                            lastIpcObject: n
                        }));
                    }
                }
            }
        }
    }

    // ── AccessPoint component ─────────────────────────────────────
    component AccessPoint: QtObject {
        required property var lastIpcObject
        readonly property string ssid: lastIpcObject.ssid
        readonly property string bssid: lastIpcObject.bssid
        readonly property int strength: lastIpcObject.strength
        readonly property int frequency: lastIpcObject.frequency
        readonly property bool active: lastIpcObject.active
        readonly property string security: lastIpcObject.security
        readonly property bool isSecure: security.length > 0
    }

    Component {
        id: apComp
        AccessPoint {}
    }

    Component.onCompleted: update()
}
