pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool matugenAvailable: false
    property bool app2unitAvailable: false
    property bool imagemagickAvailable: false
    property bool nmcliAvailable: false

    readonly property var programsToCheck: ({
            "matugenAvailable": ["which", "matugen"],
            "app2unitAvailable": ["which", "app2unit"],
            "imagemagickAvailable": ["which", "magick"],
            "nmcliAvailable": ["which", "nmcli"]
        })

    property var checkQueue: []
    property bool isChecking: false

    function init() {
        checkAllPrograms();
    }

    Process {
        id: checker
        running: false

        property string currentProperty: ""

        onExited: function (exitCode) {
            if (currentProperty !== "") {
                root[currentProperty] = (exitCode === 0);
            }

            root.isChecking = false;
            root.processQueue();
        }

        stdout: StdioCollector {}
        stderr: StdioCollector {}
    }

    function checkAllPrograms() {
        checkQueue = Object.keys(programsToCheck);
        processQueue();
    }

    function processQueue() {
        if (isChecking || checkQueue.length === 0) {
            return;
        }

        isChecking = true;
        const propertyName = checkQueue.shift();
        const command = programsToCheck[propertyName];

        checker.currentProperty = propertyName;
        checker.command = command;
        checker.running = true;
    }
}
