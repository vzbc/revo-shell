pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property real ramPercent: 0

  property var ramHistory: []

  property int maxHistoryLength: 50

  Process {
    id: ramProcess
    running: false

    command: ["bash", "-c", "awk '/MemTotal/{t=$2}/MemFree/{f=$2}/Buffers/{b=$2}/^Cached:/{c=$2} END{print int(((t-f-b-c)/t)*100)}' /proc/meminfo"]

    stdout: StdioCollector {
      onTextChanged: {
        const value = parseInt(text.trim());
        if (!isNaN(value)) {
          root.ramPercent = value;   // %
        }
      }
    }
  }

  // ===== Top CPU Processes =====

  // ===== Update Timer =====
  Timer {
    interval: 1000
    repeat: true
    running: true
    triggeredOnStart: true

    onTriggered: {
      if (!ramProcess.running)
      ramProcess.running = true;
    }
  }

}
