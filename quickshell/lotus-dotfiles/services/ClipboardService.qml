import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    required property QtObject userConfig
    property bool active: false
    property bool captureEnabled: userConfig.clipboardCaptureEnabled
    property bool loading: true
    property bool error: false
    property bool actionBusy: false
    property string lastError: ""
    property string pendingAction: ""
    property var items: []
    property Process listProcess
    property Process actionProcess
    property Process textCaptureProcess
    property Process imageCaptureProcess
    property Timer pollTimer
    property Timer actionRefreshTimer
    property Timer captureRetryTimer

    signal itemCopied()

    function refresh() {
        if (active && !listProcess.running)
            listProcess.running = true;

    }

    function parseList(output) {
        const parsed = [];
        const lines = String(output).split("\n");
        for (let index = 0; index < lines.length && parsed.length < 100; index++) {
            const separator = lines[index].indexOf("\t");
            if (separator < 1)
                continue;

            const id = lines[index].slice(0, separator).trim();
            const rawPreview = lines[index].slice(separator + 1).trim();
            const binary = rawPreview.indexOf("[[ binary data") === 0;
            const preview = binary ? "Image or rich clipboard data" : rawPreview.replace(/\s+/g, " ");
            parsed.push({
                "id": id,
                "preview": preview.length > 0 ? preview : "Empty text entry",
                "binary": binary
            });
        }
        items = parsed;
    }

    function search(query, limit) {
        const needle = String(query || "").trim().toLowerCase();
        const maximum = Math.max(1, Number(limit) || 8);
        const source = needle.length === 0 ? items : items.filter(function(item) {
            return String(item.preview).toLowerCase().indexOf(needle) >= 0;
        });
        return source.slice(0, maximum);
    }

    function runAction(action, item) {
        if (actionBusy)
            return ;

        const entryId = item === null || item === undefined ? "" : String(item.id || "");
        if ((action === "copy" || action === "delete") && entryId.length === 0)
            return ;

        pendingAction = action;
        lastError = "";
        actionBusy = true;
        actionProcess.command = [Quickshell.shellDir + "/scripts/clipboard-action.sh", action, entryId];
        actionProcess.running = true;
    }

    function copyItem(item) {
        runAction("copy", item);
    }

    function deleteItem(item) {
        runAction("delete", item);
    }

    function wipe() {
        runAction("wipe", null);
    }

    function toggleCapture() {
        captureEnabled = !captureEnabled;
    }

    onActiveChanged: {
        if (active)
            refresh();

    }

    listProcess: Process {
        command: ["cliphist", "list"]
        onExited: (exitCode, exitStatus) => {
            root.loading = false;
            root.error = exitCode !== 0;
            if (exitCode === 0)
                root.parseList(listOutput.text);

        }

        stdout: StdioCollector {
            id: listOutput
        }

    }

    actionProcess: Process {
        onExited: (exitCode, exitStatus) => {
            const completedAction = root.pendingAction;
            root.actionBusy = false;
            root.pendingAction = "";
            root.lastError = exitCode === 0 ? "" : String(actionError.text).trim() || "Clipboard action failed.";
            if (exitCode === 0 && completedAction === "copy")
                root.itemCopied();

            root.actionRefreshTimer.restart();
        }

        stderr: StdioCollector {
            id: actionError
        }

    }

    textCaptureProcess: Process {
        command: ["wl-paste", "--type", "text", "--watch", "cliphist", "-max-items", "100", "store"]
        running: root.captureEnabled
    }

    imageCaptureProcess: Process {
        command: ["wl-paste", "--type", "image", "--watch", "cliphist", "-max-items", "100", "store"]
        running: root.captureEnabled
    }

    pollTimer: Timer {
        interval: 2000
        repeat: true
        running: root.active
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    actionRefreshTimer: Timer {
        interval: 200
        repeat: false
        onTriggered: root.refresh()
    }

    captureRetryTimer: Timer {
        interval: 5000
        repeat: true
        running: root.captureEnabled
        onTriggered: {
            if (!root.textCaptureProcess.running)
                root.textCaptureProcess.running = true;

            if (!root.imageCaptureProcess.running)
                root.imageCaptureProcess.running = true;

        }
    }

}
