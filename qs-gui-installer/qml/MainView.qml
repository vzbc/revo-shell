// MainView.qml — stage orchestrator: Sidebar always + 5 stages with smooth transitions
// UI language: English · Font: SF Pro
import QtQuick
import QtQuick.Controls

import "components"
import "stages"

Rectangle {
    id: root

    width: 1280
    height: 800
    objectName: "mainView"
    color: "#000000"
    property alias title: titleBarLabel.text

    property int stage: 0
    property bool sidebarCollapsed: false
    property string repoUrl: ""
    property string shellId: ""
    property string shellPath: ""

    readonly property int stageCount: 5

    function go(to) {
        to = Math.max(0, Math.min(stageCount - 1, to))
        if (to === stage)
            return
        stage = to
    }

    function next() { go(stage + 1) }
    function back() { go(stage - 1) }

    function resetAll() {
        repoUrl = ""
        shellId = ""
        shellPath = ""
        stage = 0
    }

    // Title bar
    Rectangle {
        id: titleBar
        width: parent.width
        height: 44
        color: "#000000"
        z: 20

        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 1
            color: "#1C1C1E"
        }

        Label {
            id: titleBarLabel
            anchors.centerIn: parent
            text: "Revo Shell Installer"
            size: 14
            weight: Font.DemiBold
            tone: "#FFFFFF"
        }

        // Window controls (host may override) — traffic lights on the left
        Row {
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Repeater {
                model: [
                    { c: "#FF5F57", a: function() {} },
                    { c: "#FEBC2E", a: function() {} },
                    { c: "#28C840", a: function() {} }
                ]

                delegate: Rectangle {
                    id: trafficDot
                    required property var modelData
                    width: 12
                    height: 12
                    radius: 6
                    color: trafficDot.modelData.c
                    opacity: 0.9

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: trafficDot.modelData.a()
                    }
                }
            }
        }
    }

    Row {
        anchors.top: titleBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        spacing: 0

        // Always-visible sidebar
        Sidebar {
            id: sidebar
            height: parent.height
            currentStage: root.stage
            collapsed: root.sidebarCollapsed
            onStageSelected: function(i) { root.go(i) }
            onToggleCollapse: root.sidebarCollapsed = !root.sidebarCollapsed
        }

        // Stage host
        Item {
            id: stageHost
            width: parent.width - sidebar.width
            height: parent.height
            clip: true

            // Current stage
            StackView {
                id: stack
                anchors.fill: parent
                initialItem: stage1Component
                pushEnter: Transition {
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 340; easing.type: Easing.OutCubic }
                        NumberAnimation { property: "x"; from: 40; to: 0; duration: 340; easing.type: Easing.OutCubic }
                    }
                }
                pushExit: Transition {
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 240; easing.type: Easing.InCubic }
                        NumberAnimation { property: "x"; from: 0; to: -30; duration: 240; easing.type: Easing.InCubic }
                    }
                }
                popEnter: Transition {
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 340; easing.type: Easing.OutCubic }
                        NumberAnimation { property: "x"; from: -40; to: 0; duration: 340; easing.type: Easing.OutCubic }
                    }
                }
                popExit: Transition {
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 240; easing.type: Easing.InCubic }
                        NumberAnimation { property: "x"; from: 0; to: 30; duration: 240; easing.type: Easing.InCubic }
                    }
                }
            }

            // Progress strip (bottom, always)
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 36
                color: "#000000"
                z: 15

                Rectangle {
                    anchors.top: parent.top
                    width: parent.width
                    height: 1
                    color: "#1C1C1E"
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 20
                    width: 120
                    height: 4
                    radius: 2
                    color: "#1C1C1E"

                    Rectangle {
                        width: parent.width * ((root.stage + 1) / root.stageCount)
                        height: parent.height
                        radius: 2
                        color: "#FFFFFF"
                        Behavior on width { NumberAnimation { duration: 320; easing.type: Easing.InOutCubic } }
                    }
                }

                Label {
                    anchors.left: parent.left
                    anchors.leftMargin: 156
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Step " + (root.stage + 1) + " of " + root.stageCount
                    size: 12
                    tone: "#6E6E73"
                }

                Label {
                    anchors.right: parent.right
                    anchors.rightMargin: 20
                    anchors.verticalCenter: parent.verticalCenter
                    text: ["Welcome", "Repository", "Shells", "Install", "Done"][root.stage]
                    size: 12
                    weight: Font.Medium
                    tone: "#FFFFFF"
                }
            }
        }
    }

    // Component factories
    Component {
        id: stage1Component

        Stage1Welcome {
            onGetStarted: root.next()
        }
    }

    Component {
        id: stage2Component

        Stage2Repo {
            onNext: function(url) {
                root.repoUrl = url
                root.next()
            }
            onSkipped: {
                root.repoUrl = ""
                root.next()
            }
        }
    }

    Component {
        id: stage3Component

        Stage3Shells {
            onConfirmed: function(id, path) {
                root.shellId = id
                root.shellPath = path
                root.next()
            }
        }
    }

    Component {
        id: stage4Component

        Stage4Install {
            repoUrl: root.repoUrl
            shellId: root.shellId
            checkFiles: root.checkLocalFiles
            useRealProgress: true
            onBack: root.back()
            onFinished: root.next()
            onInstallRequested: function(pw) {
                root.installProgress = 0
                root.installStatus = "Starting…"
                root.installRunning = true
                root.installCompleted = false
                root.installFailed = false
                var b = root.installBackend
                if (!b)
                    return
                if (typeof b === "function")
                    b(pw)
                else if (b.install)
                    b.install(pw)
            }
        }
    }

    Component {
        id: stage5Component

        Stage5Done {
            onRestart: root.resetAll()
            onReboot: {
                var b = root.rebootHost
                if (!b)
                    return
                if (typeof b === "function")
                    b()
                else if (b.reboot)
                    b.reboot()
            }
        }
    }

    property var pendingShells: []

    function _applyShells(item) {
        if (item && item.shells !== undefined && pendingShells && pendingShells.length > 0)
            item.shells = pendingShells
    }

    // Stage switch (single handler)
    onStageChanged: {
        var map = [stage1Component, stage2Component, stage3Component, stage4Component, stage5Component]
        var comp = map[Math.max(0, Math.min(map.length - 1, stage))]
        stack.clear()
        stack.push(comp, StackView.Immediate)
        Qt.callLater(function() { _applyShells(stack.currentItem) })
    }

    // Exposed hooks for Python
    property var installBackend: null
    property var rebootHost: null
    property var shellScanner: null
    property var filesChecker: null

    // Live install progress pushed from Python
    property real installProgress: 0
    property string installStatus: ""
    property string installLogLine: ""
    property bool installRunning: false
    property bool installCompleted: false
    property bool installFailed: false

    onInstallLogLineChanged: {
        if (installLogLine.length > 0 && stage === 3 && stack.currentItem)
            stack.currentItem.pushLogLine(installLogLine)
    }
    onInstallCompletedChanged: {
        if (installCompleted && stage === 3 && stack.currentItem)
            stack.currentItem.applyBackendDone(installProgress, installStatus)
    }
    onInstallFailedChanged: {
        if (installFailed && stage === 3 && stack.currentItem)
            stack.currentItem.applyBackendFailed(installStatus)
    }
    onInstallProgressChanged: {
        if (installRunning && stage === 3 && stack.currentItem)
            stack.currentItem.applyBackendProgress(installProgress, installStatus)
    }
    onInstallStatusChanged: {
        if (installRunning && stage === 3 && stack.currentItem)
            stack.currentItem.applyBackendProgress(installProgress, installStatus)
    }

    function checkLocalFiles() {
        var c = filesChecker
        if (!c)
            return { exists: false, found: false, paths: [], count: 0 }
        if (typeof c === "function")
            return c()
        if (c.check)
            return c.check()
        return { exists: false, found: false, paths: [], count: 0 }
    }

    function setShells(list) {
        pendingShells = list
        _applyShells(stack.currentItem)
    }

    Component.onCompleted: {
        var s = shellScanner
        if (!s)
            return
        if (typeof s === "function")
            s()
        else if (s.scan)
            s.scan()
    }
}
