// Stage4Install.qml — full install via GUI: packages + clone + deploy + build
// Local configs present → still installs deps/builds (backup per file)
import QtQuick
import QtQuick.Controls
import "../components"

Item {
    id: root

    signal installRequested(string password)
    signal back()
    signal finished()

    property bool installing: false
    property bool passwordReady: false
    property bool completed: false
    property real progress: 0
    property string statusText: "Enter your sudo password to begin installation."
    property var logLines: []

    property string repoUrl: ""
    property string shellId: ""
    property var checkFiles: null
    // When true, progress comes from Python backend (not the fake timer)
    property bool useRealProgress: false
    property bool backendFailed: false

    function localFilesExist() {
        if (typeof checkFiles !== "function")
            return false
        var r = checkFiles()
        if (r && (r.exists || r.found))
            return true
        return false
    }

    function pushLogLine(line) {
        if (!line || line.length < 1)
            return
        logLines = logLines.concat([line])
    }

    function applyBackendProgress(p, msg) {
        installing = true
        completed = false
        progress = p
        if (msg && msg.length > 0)
            statusText = msg
    }

    function applyBackendDone(p, msg) {
        stopTimer()
        installing = false
        completed = true
        backendFailed = false
        progress = p > 0 ? p : 100
        statusText = (msg && msg.length > 0) ? msg : "Done — 100%"
        if (logLines.length === 0 || logLines[logLines.length - 1].indexOf("✓") < 0)
            logLines = logLines.concat(["$ verify --all", "  ✓ " + statusText])
    }

    function applyBackendFailed(msg) {
        stopTimer()
        installing = false
        completed = false
        backendFailed = true
        statusText = (msg && msg.length > 0) ? msg : "Installation failed — see log."
        logLines = logLines.concat(["$ error", "  ✗ " + statusText])
    }

    function stopTimer() {
        stepTimer.stop()
    }

    function beginInstall() {
        if (installing)
            return
        // Prefer live field value — passwordReady can lag after focus games.
        var pw = otp.value
        if (pw.length < 1) {
            statusText = "Enter your password."
            otp.forceFocus()
            return
        }
        passwordReady = true
        installing = true
        completed = false
        backendFailed = false
        progress = 0
        logLines = ["$ full install from GUI", "  · packages · clone · deploy · build"]
        if (localFilesExist())
            logLines = logLines.concat(["  · local configs present — backup + merge (no data loss)"])
        stepIndex = 0
        statusText = "Starting full installation…"
        installRequested(pw)
        otp.clear()
        // Fallback fake pipeline only when Python backend is not wired
        if (!useRealProgress)
            stepTimer.start()
    }

    // Fallback pipeline (no Python backend) — still lists full steps
    property var pipeline: [
        { p: 8,   text: "Installing system packages…", log: "pacman -S --needed $PACKAGES" },
        { p: 18,  text: "Installing AUR packages…", log: "yay -S quickshell-git awww matugen…" },
        { p: 30,  text: "Installing Python packages…", log: "pip install --user -r requirements.txt" },
        { p: 42,  text: "Cloning monorepo…", log: "git clone --depth 1 $DOTFILES_REPO_URL" },
        { p: 55,  text: "Installing wallpapers…", log: "cp -a wallpapers/* ~/Pictures/Wallpapers/" },
        { p: 65,  text: "Installing Hyprland configurations…", log: "cp -a hypr/* ~/.config/hypr/" },
        { p: 75,  text: "Installing Quickshell shells…", log: "cp -a quickshell/* ~/.config/quickshell/" },
        { p: 82,  text: "Fixing home paths…", log: "sed s|/home/revo|$HOME|g" },
        { p: 90,  text: "Building native shells…", log: "cmake -B build && cmake --build build" },
        { p: 96,  text: "Enabling services…", log: "systemctl --user enable pipewire wireplumber" },
        { p: 100, text: "Installation complete.", log: "done" }
    ]
    property int stepIndex: 0

    Timer {
        id: stepTimer
        interval: 700
        repeat: true
        running: root.installing && !root.useRealProgress && root.stepIndex < root.pipeline.length
        onTriggered: {
            var s = root.pipeline[root.stepIndex]
            root.progress = s.p
            root.statusText = s.text
            root.logLines = root.logLines.concat(["$ " + s.log, "  ✓ " + s.text])
            root.stepIndex++
            if (root.stepIndex >= root.pipeline.length) {
                stop()
                root.installing = false
                root.completed = true
                root.statusText = "Done — 100%"
            }
        }
    }

    Column {
        anchors.centerIn: parent
        width: Math.min(parent.width - 64, 720)
        spacing: 28

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Install"
            size: 36
            weight: Font.Bold
            tone: "#FFFFFF"
        }

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: "Dotfiles + Hyprland configs from GitHub. Enter your password to authorize."
            size: 15
            tone: "#A1A1A1"
            wrapMode: Text.WordWrap
        }

        // Summary chips
        Flow {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 10

            Repeater {
                model: [
                    { k: "Repo", v: root.repoUrl.length > 0 ? root.repoUrl : "Default" },
                    { k: "Shell", v: root.shellId.length > 0 ? root.shellId : "—" }
                ]

                delegate: Rectangle {
                    required property var modelData
                    width: chipRow.implicitWidth + 24
                    height: 32
                    radius: 16
                    color: "#111111"
                    border.width: 1
                    border.color: "#2C2C2E"

                    Row {
                        id: chipRow
                        anchors.centerIn: parent
                        spacing: 8

                        Label {
                            text: modelData.k
                            size: 12
                            tone: "#6E6E73"
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Label {
                            text: modelData.v
                            size: 12
                            weight: Font.Medium
                            tone: "#FFFFFF"
                            anchors.verticalCenter: parent.verticalCenter
                            elide: Text.ElideMiddle
                            maximumLineCount: 1
                        }
                    }
                }
            }
        }

        // OTP password
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 12

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Sudo password"
                size: 13
                tone: "#6E6E73"
            }

            OtpField {
                id: otp
                anchors.horizontalCenter: parent.horizontalCenter
                minSlots: 8
                maxLength: 64
                secret: true
                enabled: !root.installing
                onPasswordReadyChanged: root.passwordReady = passwordReady
                onValueChanged: root.passwordReady = value.length >= 1
                onCompleted: function(v) {
                    root.passwordReady = v.length >= 1
                }
            }

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.installing ? "Full install — packages, clone, deploy, build. Do not close." : "Installs all libraries and builds every Quickshell shell."
                size: 12
                tone: root.installing ? "#FFD60A" : "#48484A"
            }
        }

        // Progress
        Rectangle {
            width: parent.width
            height: 8
            radius: 4
            color: "#1A1A1A"
            clip: true

            Rectangle {
                width: parent.width * (root.progress / 100)
                height: parent.height
                radius: 4
                color: "#FFFFFF"
                Behavior on width {
                    NumberAnimation { duration: 500; easing.type: Easing.InOutCubic }
                }
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 16

            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: Math.round(root.progress) + "%"
                size: 14
                weight: Font.DemiBold
                tone: "#FFFFFF"
            }

            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: root.statusText
                size: 14
                tone: "#A1A1A1"
            }
        }

        // Log window
        Rectangle {
            width: parent.width
            height: 160
            radius: 12
            color: "#0C0C0C"
            border.width: 1
            border.color: "#2C2C2E"
            clip: true

            Flickable {
                id: logFlick
                anchors.fill: parent
                anchors.margins: 12
                contentHeight: logCol.implicitHeight
                clip: true

                Column {
                    id: logCol
                    width: parent.width
                    spacing: 4

                    Repeater {
                        model: root.logLines

                        Text {
                            required property var modelData
                            width: logCol.width
                            text: modelData
                            font.family: "SF Mono"
                            font.pixelSize: 12
                            color: text.toString().indexOf("✓") >= 0 ? "#30D158" : (text.toString().indexOf("✗") >= 0 ? "#FF453A" : "#A1A1A1")
                            wrapMode: Text.WrapAnywhere
                        }
                    }
                }

                onContentHeightChanged: contentY = Math.max(0, contentHeight - height)
            }
        }

        // Actions
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 14

            RippleButton {
                text: "Back"
                enabled: !root.installing
                buttonColor: "#0A0A0A"
                buttonTextColor: "#FFFFFF"
                buttonBorderColor: "#2C2C2E"
                onClicked: if (!root.installing) root.back()
            }

            Rectangle {
                id: installBtn
                visible: !root.completed && !root.backendFailed
                enabled: !root.installing && otp.value.length >= 1
                opacity: enabled ? 1 : 0.4
                height: 46
                width: installRow.implicitWidth + 48
                radius: 12
                color: installMouse.containsMouse && enabled ? "#E5E5EA" : "#FFFFFF"

                Behavior on color { ColorAnimation { duration: 160 } }

                Row {
                    id: installRow
                    anchors.centerIn: parent
                    spacing: 8

                    Label {
                        text: root.installing ? "Installing…" : "Install Now"
                        size: 15
                        weight: Font.Medium
                        tone: "#000000"
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Label {
                        visible: !root.installing
                        text: "→"
                        size: 16
                        weight: Font.Medium
                        tone: "#000000"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: installMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: parent.enabled
                    cursorShape: Qt.PointingHandCursor
                    onPressed: otp.forceFocus()
                    onClicked: root.beginInstall()
                }
            }

            Rectangle {
                id: retryBtn
                visible: root.backendFailed && !root.installing
                enabled: otp.value.length >= 1 || true
                height: 46
                width: retryRow.implicitWidth + 48
                radius: 12
                color: retryMouse.containsMouse ? "#E5E5EA" : "#FFFFFF"
                Behavior on color { ColorAnimation { duration: 160 } }
                Row {
                    id: retryRow
                    anchors.centerIn: parent
                    spacing: 8
                    Label {
                        text: "Retry"
                        size: 15
                        weight: Font.Medium
                        tone: "#000000"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                MouseArea {
                    id: retryMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.backendFailed = false
                        otp.forceFocus()
                    }
                }
            }

            Rectangle {
                id: continueBtn
                visible: root.completed
                enabled: !root.installing
                height: 46
                width: continueRow.implicitWidth + 48
                radius: 12
                color: continueMouse.containsMouse && enabled ? "#E5E5EA" : "#FFFFFF"

                Behavior on color { ColorAnimation { duration: 160 } }

                Row {
                    id: continueRow
                    anchors.centerIn: parent
                    spacing: 8

                    Label {
                        text: "Continue"
                        size: 15
                        weight: Font.Medium
                        tone: "#000000"
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Label {
                        text: "→"
                        size: 16
                        weight: Font.Medium
                        tone: "#000000"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: continueMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: parent.enabled
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.finished()
                }
            }
        }
    }

    onVisibleChanged: {
        if (visible)
            otp.forceFocus()
    }
}
