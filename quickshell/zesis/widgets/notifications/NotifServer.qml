pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import "../wm"

Singleton {
    id: root

    property int count: server.trackedNotifications.values.length
    property int unreadCount: 0
    property bool replyActive: false
    property bool muted: settingsData.muted
    property bool _loaded: false

    onMutedChanged: if (_loaded)
        _write()

    readonly property string _configDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/zesis"
    readonly property string _configPath: _configDir + "/notifications.json"

    readonly property var notifications: server.trackedNotifications
    readonly property ListModel history: historyModel

    Component.onCompleted: Qt.callLater(function () {
        root._loaded = true;
    })

    function clearHistory() {
        historyModel.clear();
        unreadCount = 0;
    }

    function markRead() {
        unreadCount = 0;
    }

    function focusWindow(notification) {
        const pid = notification?.hints?.["sender-pid"] ?? 0;
        if (pid > 0) {
            WmService.focusWindowByPid(pid);
            return;
        }
        const entry = notification?.desktopEntry ?? "";
        const name = notification?.appName ?? "";
        const cls = (entry !== "" ? entry : name).toLowerCase();
        if (cls !== "")
            WmService.focusWindowByClass(cls);
    }

    function _write() {
        writeProc.command = ["sh", "-c", "mkdir -p '" + root._configDir + "' && echo '" + JSON.stringify({
                muted: root.muted
            }) + "' > '" + root._configPath + "'"];
        writeProc.running = true;
    }

    JsonAdapter {
        id: settingsData
        property bool muted: false
    }

    FileView {
        path: root._configPath
        adapter: settingsData // qmllint disable missing-type
    }

    Process {
        id: writeProc
        running: false
    }

    ListModel {
        id: historyModel
    }

    NotificationServer {
        id: server
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: false
        inlineReplySupported: true

        onNotification: n => {
            n.tracked = true;
            historyModel.insert(0, {
                appName: n.appName ?? "",
                summary: n.summary ?? "",
                body: n.body ?? "",
                image: n.image ?? "",
                appIcon: n.appIcon ?? "",
                time: Qt.formatTime(new Date(), "hh:mm")
            });
            if (historyModel.count > 50)
                historyModel.remove(historyModel.count - 1);
            if (!root.muted)
                root.unreadCount++;
        }
    }
}
