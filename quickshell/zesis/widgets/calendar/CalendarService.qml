pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string _scriptPath: Qt.resolvedUrl("cal_fetch.py").toString().replace("file://", "")
    readonly property string _writeScriptPath: Qt.resolvedUrl("cal_write.py").toString().replace("file://", "")
    readonly property string _configDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/zesis"
    readonly property string _configPath: _configDir + "/calendar.json"

    property string calendarDir: calConfig.calendarDir
    property int syncIntervalMin: calConfig.syncIntervalMin

    property var events: []
    property bool syncing: false
    property bool loading: false
    property string lastError: ""
    property string lastSynced: ""
    property bool writing: false

    readonly property var availableCalendars: {
        var seen = {}, out = [];
        for (var i = 0; i < root.events.length; i++) {
            var c = root.events[i].calendar;
            if (c && !seen[c]) {
                seen[c] = true;
                out.push(c);
            }
        }
        return out.length > 0 ? out : ["personal"];
    }

    JsonAdapter {
        id: calConfig
        property string calendarDir: (Quickshell.env("HOME") || "") + "/.local/share/vdirsyncer/calendar"
        property int syncIntervalMin: 10
    }

    FileView {
        path: root._configPath
        watchChanges: true
        adapter: calConfig
        onFileChanged: reload()
    }

    Component.onCompleted: {
        writeConfig(calConfig.calendarDir, calConfig.syncIntervalMin);
        root.fetch();
    }

    function fetch() {
        if (root.loading)
            return;
        root.loading = true;
        root.lastError = "";
        fetchProc._buf = "";
        fetchProc.command = ["python3", root._scriptPath, root.calendarDir];
        fetchProc.running = false;
        fetchProc.running = true;
    }

    function syncAndFetch() {
        if (root.syncing)
            return;
        root.syncing = true;
        root.lastError = "";
        syncProc.running = false;
        syncProc.running = true;
    }

    function createEvent(ev, calendar) {
        if (root.writing)
            return;
        root.writing = true;
        root.lastError = "";
        ev.calendar = calendar;
        manageProc._buf = "";
        manageProc.command = ["python3", root._writeScriptPath, "create", root.calendarDir, JSON.stringify(ev)];
        manageProc.running = false;
        manageProc.running = true;
    }

    function deleteEvent(filePath) {
        if (root.writing)
            return;
        root.writing = true;
        root.lastError = "";
        manageProc._buf = "";
        manageProc.command = ["python3", root._writeScriptPath, "delete", filePath];
        manageProc.running = false;
        manageProc.running = true;
    }

    function editEvent(filePath, ev) {
        if (root.writing)
            return;
        root.writing = true;
        root.lastError = "";
        manageProc._buf = "";
        manageProc.command = ["python3", root._writeScriptPath, "edit", filePath, JSON.stringify(ev)];
        manageProc.running = false;
        manageProc.running = true;
    }

    function writeConfig(dir, intervalMin) {
        root.calendarDir = dir;
        root.syncIntervalMin = intervalMin;
        syncTimer.interval = intervalMin * 60000;
        var esc = function (s) {
            return s.replace(/\\/g, "\\\\").replace(/"/g, '\\"');
        };
        var payload = '{"calendarDir":"' + esc(dir) + '","syncIntervalMin":' + intervalMin + '}';
        writeProc.command = ["sh", "-c", "mkdir -p '" + root._configDir.replace(/'/g, "'\\''") + "' && printf '%s' '" + payload.replace(/'/g, "'\\''") + "' > '" + root._configPath.replace(/'/g, "'\\''") + "'"];
        writeProc.running = false;
        writeProc.running = true;
    }

    Timer {
        id: syncTimer
        interval: root.syncIntervalMin * 60000
        repeat: true
        running: true
        onTriggered: root.syncAndFetch()
    }

    Process {
        id: fetchProc
        property string _buf: ""
        stdout: SplitParser {
            onRead: data => fetchProc._buf += data
        }
        stderr: SplitParser {
            onRead: line => console.log("[CalendarService] python:", line)
        }
        onExited: code => {
            root.loading = false;
            if (code !== 0) {
                root.lastError = "fetch_error:" + code;
                return;
            }
            try {
                var result = JSON.parse(fetchProc._buf);
                if (Array.isArray(result)) {
                    root.events = result;
                } else if (result && result.error) {
                    root.lastError = result.error;
                }
            } catch (e) {
                root.lastError = "parse_error";
            }
        }
    }

    Process {
        id: syncProc
        command: ["sh", "-c", "vdirsyncer sync"]
        stderr: SplitParser {
            onRead: line => console.log("[CalendarService] vdirsyncer:", line)
        }
        onExited: code => {
            root.syncing = false;
            if (code === 0) {
                var now = new Date();
                root.lastSynced = String(now.getHours()).padStart(2, "0") + ":" + String(now.getMinutes()).padStart(2, "0");
            } else {
                root.lastError = code === 127 ? "vdirsyncer_missing" : "sync_error:" + code;
            }
            root.fetch();
        }
    }

    Process {
        id: writeProc
    }

    Process {
        id: manageProc
        property string _buf: ""
        stdout: SplitParser {
            onRead: data => manageProc._buf += data
        }
        stderr: SplitParser {
            onRead: line => console.log("[CalendarService] cal_write:", line)
        }
        onExited: code => {
            root.writing = false;
            if (code !== 0) {
                root.lastError = "write_error:" + code;
                return;
            }
            try {
                var result = JSON.parse(manageProc._buf);
                if (result.error) {
                    root.lastError = result.error;
                } else {
                    root.fetch();
                }
            } catch (e) {
                root.lastError = "parse_error";
            }
        }
    }
}
