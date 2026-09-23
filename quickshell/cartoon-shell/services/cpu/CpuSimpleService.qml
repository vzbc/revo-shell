pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property real cpuPercent: 0

  property var cpuHistory: []

  property int maxHistoryLength: 50

  Process {
    id: cpuProcess

    command: [
    "sh",
    "-c",
    "vmstat 1 2 | awk 'NR==4 {print 100-$15}'"
    ]

    running: false

    stdout: StdioCollector {
      onTextChanged: {
        const value = parseFloat(text.trim());

        if (isNaN(value))
        return;

        root.cpuPercent = value;

        const history = root.cpuHistory.slice();

        history.push({
            usage: value
        });

        if (history.length > root.maxHistoryLength)
        history.shift();

        root.cpuHistory = history;
      }
    }
  }

  Timer {
    interval: 1000
    repeat: true
    running: true
    triggeredOnStart: true

    onTriggered: {
      if (!cpuProcess.running)
      cpuProcess.running = true;
    }
  }

}
