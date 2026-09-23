import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    required property QtObject userConfig
    property bool active: false
    property bool loading: false
    property bool available: false
    property bool error: false
    property real value: 0
    property real pendingValue: 0
    property bool applyQueued: false
    property int changeRevision: 0
    property int queryRevision: -1
    readonly property string controllerPath: userConfig.brightnessScript
    readonly property string statusText: loading ? "Checking" : (available ? Math.round(value * 100) + "%" : (error ? "Controller error" : "No brightness controller"))
    property Process queryProcess
    property Process applyProcess
    property Timer pollTimer
    property Timer applyTimer

    function percentFromOutput(output) {
        const match = String(output).trim().match(/^(\d{1,3})$/);
        if (match === null)
            return -1;

        const percent = Number(match[1]);
        return percent >= 0 && percent <= 100 ? percent : -1;
    }

    function refresh() {
        if (queryProcess.running || applyProcess.running || applyQueued || applyTimer.running)
            return ;

        loading = !available;
        queryRevision = changeRevision;
        queryProcess.running = true;
    }

    function setValue(nextValue) {
        if (!available)
            return ;

        value = Math.max(0.05, Math.min(1, nextValue));
        pendingValue = value;
        applyQueued = true;
        changeRevision++;
        applyTimer.restart();
    }

    function startApply() {
        if (!available || applyProcess.running)
            return ;

        if (queryProcess.running) {
            applyTimer.restart();
            return ;
        }
        applyQueued = false;
        const percent = Math.round(pendingValue * 100);
        applyProcess.command = [controllerPath, "set", String(percent)];
        applyProcess.running = true;
    }

    queryProcess: Process {
        id: queryProcess

        command: [root.controllerPath, "get"]
        onExited: (exitCode, exitStatus) => {
            root.loading = false;
            if (exitCode !== 0) {
                root.available = false;
                root.error = true;
                return ;
            }
            const percent = root.percentFromOutput(queryOutput.text);
            if (percent < 0) {
                root.available = false;
                root.error = true;
                return ;
            }
            if (root.queryRevision !== root.changeRevision || root.applyQueued || root.applyProcess.running) {
                if (root.applyQueued)
                    root.applyTimer.restart();

                return ;
            }
            root.value = percent / 100;
            root.pendingValue = root.value;
            root.available = true;
            root.error = false;
        }

        stdout: StdioCollector {
            id: queryOutput
        }

    }

    applyProcess: Process {
        id: applyProcess

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                root.available = false;
                root.error = true;
                root.applyQueued = false;
                return ;
            }
            root.error = false;
            if (root.applyQueued)
                root.applyTimer.restart();
            else
                root.refresh();
        }
    }

    pollTimer: Timer {
        interval: 5000
        repeat: true
        running: root.active
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    applyTimer: Timer {
        interval: 80
        repeat: false
        onTriggered: root.startApply()
    }

}
