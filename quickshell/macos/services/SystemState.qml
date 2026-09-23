pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// Local UI state that mirrors macOS Control Center / menu bar toggles
Singleton {
    id: root

    // ---- Battery (menu bar) ----
    property bool showBatteryPercent: false

    // ---- Power Mode (maps to powerprofilesctl) ----
    property string powerMode: "automatic"   // automatic | low | high
    function setPowerMode(m) {
        root.powerMode = m;
        const p = m === "low" ? "power-saver" : (m === "high" ? "performance" : "balanced");
        _pp.command = ["bash", "-c", "timeout 3 powerprofilesctl set " + p + " 2>/dev/null || true"];
        _pp.running = true;
    }

    // ---- AirDrop (no Linux backend; state only, like a toggle) ----
    property string airdropMode: "contacts"   // off | contacts | everyone
    function cycleAirdrop() {
        root.airdropMode = root.airdropMode === "off" ? "contacts"
            : (root.airdropMode === "contacts" ? "everyone" : "off");
    }

    // ---- Focus (best-effort via scripts/focus.sh) ----
    property string focusMode: "off"         // off | dnd | work | sleep | personal | driving
    function setFocus(m) {
        root.focusMode = m;
        _focus.command = ["bash", "-c",
            "f=" + Qt.resolvedUrl("../scripts/focus.sh").toString().replace(/^file:\/\//, "") +
            "; [ -x \"$f\" ] && \"$f\" " + m + " || true"];
        _focus.running = true;
    }

    // ---- Screen Mirroring selection (best-effort) ----
    property string mirroredDisplay: ""

    Process { id: _pp; running: false; stdout: StdioCollector {}
 stderr: StdioCollector {} }
    Process { id: _focus; running: false; stdout: StdioCollector {}
 stderr: StdioCollector {} }
}
