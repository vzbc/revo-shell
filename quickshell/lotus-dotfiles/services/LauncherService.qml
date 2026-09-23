import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    required property QtObject userConfig
    property bool indexed: false
    property var applications: []
    property bool fallbackChecked: false
    property bool fallbackAvailable: false
    property bool fallbackError: false
    property string lastError: ""
    readonly property bool nativeAvailable: applications.length > 0
    readonly property bool loading: !indexed
    readonly property string statusText: loading ? "Indexing applications" : (nativeAvailable ? "Open application launcher" : (fallbackAvailable ? "Open Rofi launcher" : "No application launcher available"))
    property FileView launcherFile
    property Connections entriesConnections
    property Connections desktopEntriesConnections
    property Timer refreshTimer
    property Timer startupRefreshTimer

    signal applicationsUpdated()

    function scheduleRefresh() {
        refreshTimer.restart();
    }

    function refreshApplications() {
        const source = DesktopEntries.applications.values;
        const visible = [];
        for (let index = 0; index < source.length; index++) {
            const entry = source[index];
            if (entry === null || entry.noDisplay || entry.name.trim().length === 0 || entry.command.length === 0)
                continue;

            visible.push(entry);
        }
        visible.sort((left, right) => {
            return left.name.localeCompare(right.name, Qt.locale(), {
                "sensitivity": "base"
            });
        });
        applications = visible;
        indexed = true;
        applicationsUpdated();
    }

    function searchableText(entry) {
        const parts = [entry.name, entry.genericName, entry.comment, entry.id];
        for (let index = 0; index < entry.keywords.length; index++) parts.push(entry.keywords[index])
        for (let index = 0; index < entry.categories.length; index++) parts.push(entry.categories[index])
        return parts.join(" ").toLowerCase();
    }

    function score(entry, query) {
        const normalizedName = entry.name.toLowerCase();
        if (normalizedName === query)
            return 0;

        if (normalizedName.startsWith(query))
            return 5 + normalizedName.length - query.length;

        const namePosition = normalizedName.indexOf(query);
        if (namePosition >= 0)
            return 20 + namePosition;

        const genericName = entry.genericName.toLowerCase();
        const genericPosition = genericName.indexOf(query);
        if (genericPosition >= 0)
            return 40 + genericPosition;

        const allText = searchableText(entry);
        const tokens = query.split(/\s+/).filter((token) => {
            return token.length > 0;
        });
        let total = 70;
        for (let index = 0; index < tokens.length; index++) {
            const position = allText.indexOf(tokens[index]);
            if (position < 0)
                return -1;

            total += Math.min(position, 40);
        }
        return total;
    }

    function search(query, limit) {
        const normalized = query.trim().toLowerCase();
        if (normalized.length === 0)
            return applications.slice(0, limit);

        const matches = [];
        for (let index = 0; index < applications.length; index++) {
            const entry = applications[index];
            const matchScore = score(entry, normalized);
            if (matchScore >= 0)
                matches.push({
                "entry": entry,
                "score": matchScore
            });

        }
        matches.sort((left, right) => {
            return left.score === right.score ? left.entry.name.localeCompare(right.entry.name) : left.score - right.score;
        });
        return matches.slice(0, limit).map((match) => {
            return match.entry;
        });
    }

    function launch(entry) {
        lastError = "";
        if (entry === null || entry === undefined || entry.command.length === 0) {
            lastError = "This desktop entry has no launch command.";
            return false;
        }
        if (!entry.runInTerminal) {
            entry.execute();
            return true;
        }
        const command = [];
        for (let index = 0; index < userConfig.terminalCommand.length; index++) command.push(userConfig.terminalCommand[index])
        for (let index = 0; index < entry.command.length; index++) command.push(entry.command[index])
        Quickshell.execDetached({
            "command": command,
            "workingDirectory": entry.workingDirectory
        });
        return true;
    }

    function openFallback() {
        if (!fallbackAvailable)
            return false;

        Quickshell.execDetached(["bash", userConfig.launcherScript]);
        return true;
    }

    function checkFallback() {
        fallbackChecked = true;
        fallbackAvailable = launcherFile.text().length > 0;
        fallbackError = !fallbackAvailable;
    }

    Component.onCompleted: {
        checkFallback();
        scheduleRefresh();
        startupRefreshTimer.start();
    }

    refreshTimer: Timer {
        interval: 60
        repeat: false
        onTriggered: root.refreshApplications()
    }

    startupRefreshTimer: Timer {
        interval: 600
        repeat: false
        onTriggered: {
            root.checkFallback();
            root.refreshApplications();
        }
    }

    entriesConnections: Connections {
        function onValuesChanged() {
            root.scheduleRefresh();
        }

        function onObjectInsertedPost() {
            root.scheduleRefresh();
        }

        function onObjectRemovedPost() {
            root.scheduleRefresh();
        }

        target: DesktopEntries.applications
    }

    desktopEntriesConnections: Connections {
        function onApplicationsChanged() {
            root.scheduleRefresh();
        }

        target: DesktopEntries
    }

    launcherFile: FileView {
        path: root.userConfig.launcherScript
        preload: true
        printErrors: false
        onLoaded: {
            root.fallbackChecked = true;
            root.fallbackAvailable = true;
            root.fallbackError = false;
        }
        onLoadFailed: (errorCode) => {
            root.fallbackChecked = true;
            root.fallbackAvailable = false;
            root.fallbackError = true;
        }
    }

}
