// qmllint disable import
pragma Singleton
// qmllint enable import
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var mounts: []
    property string _buf: ""

    function refresh() {
        dfProc.running = true;
    }

    Component.onCompleted: refresh()

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Process {
        id: dfProc
        command: ["df", "--output=target,size,used,avail", "--block-size=1", "-x", "tmpfs", "-x", "devtmpfs", "-x", "squashfs", "-x", "efivarfs"]
        running: false
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => root._buf += data
        }
        onRunningChanged: {
            if (!running && root._buf !== "") {
                root.mounts = root._parseDf(root._buf);
                root._buf = "";
            }
        }
    }

    function _parseDf(text) {
        var lines = text.split("\n");
        var result = [];
        for (var i = 1; i < lines.length; i++) {
            var line = lines[i].trim();
            if (!line)
                continue;
            var parts = line.split(/\s+/);
            if (parts.length < 4)
                continue;
            var total = parseInt(parts[1]);
            var used = parseInt(parts[2]);
            var avail = parseInt(parts[3]);
            if (isNaN(total) || isNaN(used) || isNaN(avail) || total <= 0)
                continue;
            result.push({
                mountpoint: parts[0],
                total: total,
                used: used,
                avail: avail
            });
        }
        return result;
    }
}
