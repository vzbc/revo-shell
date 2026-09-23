import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Notifications

Item {
    id: root

    required property QtObject userConfig
    required property QtObject theme
    property bool quietMode: false
    property bool serverReady: false
    property string errorText: ""
    property var history: []
    property var visibleToasts: []
    property var toastQueue: []
    readonly property int unreadCount: history.filter((entry) => {
        return entry.unread;
    }).length
    readonly property int count: history.length
    readonly property bool previewMode: userConfig.notificationFixturesEnabled
    readonly property bool nativeEnabled: userConfig.nativeNotificationsEnabled
    readonly property string statusText: previewMode ? "Preview data" : (serverReady ? (quietMode ? "Quiet mode" : "Notifications on") : "Notification server unavailable")

    function focusedScreenName() {
        return Hyprland.focusedMonitor !== null ? Hyprland.focusedMonitor.name : "";
    }

    function hint(notification, name, fallback) {
        if (notification === null || notification.hints === undefined || notification.hints === null)
            return fallback;

        const value = notification.hints[name];
        return value === undefined || value === null ? fallback : value;
    }

    function normaliseCategory(notification) {
        return String(hint(notification, "category", "")).toLowerCase();
    }

    function synchronousKey(notification) {
        const value = String(hint(notification, "x-canonical-private-synchronous", ""));
        return value.length > 0 ? notification.appName + ":" + value : "";
    }

    function copyActions(notification) {
        const result = [];
        if (notification === null || notification.actions === undefined)
            return result;

        for (let index = 0; index < notification.actions.length; index++) result.push(notification.actions[index])
        return result;
    }

    function snapshot(notification) {
        const category = normaliseCategory(notification);
        const syncKey = synchronousKey(notification);
        const rawProgress = Number(hint(notification, "value", -1));
        const ephemeralCategories = ["brightness", "volume", "media"];
        const key = syncKey.length > 0 ? "sync:" + syncKey : "notification:" + notification.id;
        return {
            "key": key,
            "notificationId": notification.id,
            "native": notification,
            "appName": String(notification.appName || "Application"),
            "appIcon": String(notification.appIcon || ""),
            "desktopEntry": String(notification.desktopEntry || ""),
            "summary": String(notification.summary || "Notification"),
            "body": String(notification.body || ""),
            "image": String(notification.image || ""),
            "urgency": notification.urgency,
            "category": category,
            "progress": isFinite(rawProgress) && rawProgress >= 0 ? Math.max(0, Math.min(100, rawProgress)) : -1,
            "receivedAt": new Date(),
            "unread": true,
            "live": true,
            "resident": notification.resident,
            "transient": notification.transient,
            "ephemeral": (notification.transient && notification.urgency !== NotificationUrgency.Critical) || syncKey.length > 0 || ephemeralCategories.indexOf(category) >= 0,
            "actions": copyActions(notification),
            "hasInlineReply": notification.hasInlineReply,
            "inlineReplyPlaceholder": String(notification.inlineReplyPlaceholder || "Reply"),
            "expireTimeout": Number(notification.expireTimeout),
            "screenName": focusedScreenName()
        };
    }

    function fixture(key, appName, summary, body, urgency, progress, unread, live) {
        return {
            "key": key,
            "notificationId": 0,
            "native": null,
            "appName": appName,
            "appIcon": "",
            "desktopEntry": "",
            "summary": summary,
            "body": body,
            "image": "",
            "urgency": urgency,
            "category": "",
            "progress": progress,
            "receivedAt": new Date(),
            "unread": unread,
            "live": live,
            "resident": false,
            "transient": false,
            "ephemeral": false,
            "actions": [],
            "hasInlineReply": false,
            "inlineReplyPlaceholder": "Reply",
            "expireTimeout": -1,
            "screenName": focusedScreenName()
        };
    }

    function replaceByKey(source, entry) {
        const next = source.slice();
        const index = next.findIndex((candidate) => {
            return candidate.key === entry.key;
        });
        if (index >= 0)
            next[index] = entry;
        else
            next.unshift(entry);
        return next;
    }

    function acceptNotification(notification) {
        notification.tracked = true;
        const entry = snapshot(notification);
        notification.closed.connect((reason) => {
            return root.handleClosed(entry.key);
        });
        if (!entry.ephemeral)
            history = replaceByKey(history, entry).slice(0, theme.notificationHistoryLimit);

        const shouldToast = !quietMode || entry.urgency === NotificationUrgency.Critical;
        if (shouldToast)
            enqueueToast(entry);

    }

    function enqueueToast(entry) {
        visibleToasts = visibleToasts.filter((candidate) => {
            return candidate.key !== entry.key;
        });
        toastQueue = toastQueue.filter((candidate) => {
            return candidate.key !== entry.key;
        });
        if (visibleToasts.length < theme.notificationToastLimit) {
            const next = visibleToasts.slice();
            if (entry.urgency === NotificationUrgency.Critical)
                next.unshift(entry);
            else
                next.push(entry);
            visibleToasts = next;
        } else {
            toastQueue = toastQueue.concat([entry]);
        }
    }

    function toastsForScreen(screenName) {
        return visibleToasts.filter((entry) => {
            return entry.screenName.length === 0 || entry.screenName === screenName;
        });
    }

    function showNextToast() {
        if (toastQueue.length === 0 || visibleToasts.length >= theme.notificationToastLimit)
            return ;

        const nextQueue = toastQueue.slice();
        const nextEntry = nextQueue.shift();
        toastQueue = nextQueue;
        visibleToasts = visibleToasts.concat([nextEntry]);
    }

    function removeToast(key, expireNative) {
        const entry = visibleToasts.find((candidate) => {
            return candidate.key === key;
        });
        visibleToasts = visibleToasts.filter((candidate) => {
            return candidate.key !== key;
        });
        toastQueue = toastQueue.filter((candidate) => {
            return candidate.key !== key;
        });
        if (expireNative && entry !== undefined && entry.live && entry.native !== null)
            entry.native.expire();

        Qt.callLater(showNextToast);
    }

    function updateHistoryEntry(key, patch) {
        history = history.map((entry) => {
            if (entry.key !== key)
                return entry;

            return Object.assign({
            }, entry, patch);
        });
    }

    function handleClosed(key) {
        updateHistoryEntry(key, {
            "live": false,
            "native": null,
            "actions": [],
            "hasInlineReply": false
        });
        removeToast(key, false);
    }

    function markAllRead() {
        history = history.map((entry) => {
            return Object.assign({
            }, entry, {
                "unread": false
            });
        });
    }

    function dismiss(key) {
        const entry = history.find((candidate) => {
            return candidate.key === key;
        }) || visibleToasts.find((candidate) => {
            return candidate.key === key;
        });
        history = history.filter((candidate) => {
            return candidate.key !== key;
        });
        removeToast(key, false);
        if (entry !== undefined && entry.live && entry.native !== null)
            entry.native.dismiss();

    }

    function clearHistory() {
        const entries = history.slice();
        history = [];
        for (const entry of entries) {
            if (entry.live && entry.native !== null)
                entry.native.dismiss();

        }
    }

    function invokeAction(key, actionIdentifier) {
        const entry = history.find((candidate) => {
            return candidate.key === key;
        }) || visibleToasts.find((candidate) => {
            return candidate.key === key;
        });
        if (entry === undefined || !entry.live)
            return ;

        const action = entry.actions.find((candidate) => {
            return candidate.identifier === actionIdentifier;
        });
        if (action !== undefined)
            action.invoke();

    }

    function sendReply(key, text) {
        const trimmed = String(text).trim();
        const entry = history.find((candidate) => {
            return candidate.key === key;
        });
        if (entry === undefined || !entry.live || !entry.hasInlineReply || entry.native === null || trimmed.length === 0)
            return false;

        entry.native.sendInlineReply(trimmed);
        return true;
    }

    function toggleQuietMode() {
        quietMode = !quietMode;
        if (quietMode) {
            const critical = visibleToasts.filter((entry) => {
                return entry.urgency === NotificationUrgency.Critical;
            });
            visibleToasts = critical;
            toastQueue = toastQueue.filter((entry) => {
                return entry.urgency === NotificationUrgency.Critical;
            });
        }
    }

    function seedFixtures() {
        const entries = [fixture("fixture:chat", "Discord", "A new message arrived", "Dinner after your last match?", NotificationUrgency.Normal, -1, true, true), fixture("fixture:system", "System", "Backup is ready", "The latest rice snapshot passed its checksum.", NotificationUrgency.Low, -1, true, false), fixture("fixture:critical", "Power", "Battery needs attention", "Connect a charger soon.", NotificationUrgency.Critical, 17, true, true)];
        history = entries;
        visibleToasts = entries.slice(0, theme.notificationToastLimit);
    }

    visible: false
    width: 0
    height: 0
    Component.onCompleted: {
        if (previewMode)
            seedFixtures();

    }

    Loader {
        id: nativeServerLoader

        active: root.nativeEnabled
        onLoaded: {
            root.serverReady = item !== null;
            root.errorText = item === null ? "The notification server could not start" : "";
        }

        sourceComponent: Component {
            NotificationServer {
                keepOnReload: true
                persistenceSupported: false
                bodySupported: true
                bodyMarkupSupported: false
                bodyHyperlinksSupported: false
                bodyImagesSupported: false
                actionsSupported: true
                actionIconsSupported: true
                imageSupported: true
                inlineReplySupported: true
                extraHints: ["category", "value", "x-canonical-private-synchronous"]
                onNotification: (notification) => {
                    return root.acceptNotification(notification);
                }
            }

        }

    }

}
