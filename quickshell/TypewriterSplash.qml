import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root

    property color base: "#1e1e2e"
    property color text: "#cdd6f4"
    property color blue: "#89b4fa"
    property color mauve: "#cba6f7"
    property color green: "#a6e3a1"
    property color peach: "#fab387"
    property color yellow: "#f9e2af"
    property color red: "#f38ba8"
    property color pink: "#f5c2e7"
    property color teal: "#94e2d5"
    property color surface0: "#313244"

    property int phase: 0
    property int stageIndex: 0
    property int visibleChars: 0
    property int contentChars: 0
    property bool stageFinished: false
    property bool contentDone: false
    property real pulse: 0
    property bool cursorVisible: true
    property string promptHeader: ""
    property bool promptDone: false
    property int typewriterOpacity: 0
    property int promptOpacity: 0
    property int contentOpacity: 0
    property int terminalOpacity: 0
    property int beadsOpacity: 0
    property int beadsCount: 0
    property bool holding: false
    property real loadingProgress: 0
    property bool loadingBarFull: false

    property var stages: [
        { text: "Welcome", delay: 150, hold: 800, color: "blue" },
        { text: "A desktop shell built for YOU!!", delay: 80, hold: 1000, color: "mauve", highlight: "YOU!!", highlightColor: "peach" },
        { text: "made by @Revo", delay: 100, hold: 1000, color: "green" },
    ]

    property string promptTarget: "REVO SHELL"
    property string curTime: ""
    property string curDate: ""

    function updateClock() {
        let d = new Date();
        curTime = d.toLocaleTimeString('en-US', { hour12: false });
        curDate = d.toLocaleDateString('en-US', { weekday: 'long', month: 'long', day: 'numeric' });
    }

    Process {
        id: themeReader
        command: ["cat", Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/qs_colors.json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let c = JSON.parse(this.text.trim());
                    if (c.base) root.base = c.base;
                    if (c.text) root.text = c.text;
                    if (c.blue) root.blue = c.blue;
                    if (c.mauve) root.mauve = c.mauve;
                    if (c.green) root.green = c.green;
                    if (c.peach) root.peach = c.peach;
                    if (c.yellow) root.yellow = c.yellow;
                    if (c.red) root.red = c.red;
                    if (c.pink) root.pink = c.pink;
                    if (c.teal) root.teal = c.teal;
                    if (c.surface0) root.surface0 = c.surface0;
                } catch(e) {}
            }
        }
    }

    PanelWindow {
        id: window
        color: base
        anchors { top: true; bottom: true; left: true; right: true }

        WlrLayershell.namespace: "qs-splash"
        WlrLayershell.layer: WlrLayer.Overlay
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        Item {
            anchors.fill: parent
            focus: true
            Keys.onPressed: (event) => {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    root.holding = true;
                    event.accepted = true;
                }
            }
            Keys.onReleased: (event) => {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    root.holding = false;
                    event.accepted = true;
                }
            }
        }

        // Intro/outro terminal screen
        Item {
            anchors.fill: parent
            opacity: terminalOpacity
            Behavior on opacity { NumberAnimation { duration: 400 } }

            Column {
                anchors.centerIn: parent
                spacing: 8
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.family: "monospace"
                    font.pixelSize: 14
                    color: root.blue
                    lineHeight: 1.0
                    text: [
                        "  ██████  ███████ ██    ██  ██████  ",
                        "  ██   ██ ██      ██    ██ ██   ██ ",
                        "  ██████  █████   ██    ██ ██   ██ ",
                        "  ██   ██ ██       ██  ██  ██   ██ ",
                        "  ██   ██ ███████   ████    ██████  ",
                        "                                    ",
                        "  ███████ ██   ██ ███████ ██      ██ ",
                        "  ██      ██   ██ ██      ██      ██ ",
                        "  ███████ ███████ █████   ██      ██ ",
                        "       ██ ██   ██ ██      ██      ██ ",
                        "  ███████ ██   ██ ███████ ███████ ███████",
                        "",
                        "",
                        "  " + root.curTime,
                        "",
                        "  " + root.curDate
                    ].join('\n')
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        // Beads loading overlay
        Item {
            anchors.fill: parent
            opacity: beadsOpacity
            Behavior on opacity { NumberAnimation { duration: 200 } }

            Column {
                anchors.centerIn: parent
                spacing: 16

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 12
                    Repeater {
                        model: 10
                        delegate: Rectangle {
                            width: 10; height: 10; radius: 5
                            color: index < root.beadsCount ? root.green : root.surface0
                            opacity: index < root.beadsCount ? 1 : 0.3
                            Behavior on color { ColorAnimation { duration: 100 } }
                        }
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.family: "monospace"
                    font.pixelSize: 14
                    color: root.text
                    opacity: 0.5
                    text: "loading..."
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        // Typewriter stage
        Item {
            anchors.fill: parent
            opacity: typewriterOpacity
            Behavior on opacity { NumberAnimation { duration: 300 } }

            Column {
                anchors.centerIn: parent
                spacing: 32

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.pixelSize: 48
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    textFormat: Text.RichText
                    color: root.text
                    text: {
                        let st = root.stages[root.stageIndex];
                        if (!st) return "";
                        let full = st.text.substring(0, root.visibleChars);
                        let hl = st.highlight || "";
                        if (!hl || !full.includes(hl)) return full;
                        let i = full.indexOf(hl);
                        return full.substring(0, i) +
                            "<span style='color:" + (root[st.highlightColor] || root.peach) +
                            ";text-decoration:underline;font-weight:bold;'>" + hl +
                            "</span>" + full.substring(i + hl.length);
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.bottom
                        anchors.topMargin: 4
                        width: parent.paintedWidth * 0.7
                        height: 2
                        color: root[root.stages[root.stageIndex]?.color] || root.text
                        visible: parent.text.length > 0
                        opacity: 0.5
                    }
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 8
                    visible: root.stageIndex < root.stages.length - 1
                    Repeater {
                        model: 6
                        delegate: Rectangle {
                            width: 8; height: 8; radius: 4
                            color: Math.min(root.visibleChars / 3, 6) > index
                                ? (root[root.stages[root.stageIndex]?.color] || root.text)
                                : root.surface0
                            opacity: Math.min(root.visibleChars / 3, 6) > index ? 1 : 0.3
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }
                }
            }
        }

        // Prompt / Hold to enter
        Item {
            anchors.fill: parent
            opacity: promptOpacity
            Behavior on opacity { NumberAnimation { duration: 300 } }

            Column {
                anchors.centerIn: parent
                spacing: 8

                // Flame logo with segmented colors (5 vertical bands)
                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 160
                    height: 170
                    visible: root.promptHeader.length > 0

                    Item { x: 0; y: parent.height * 0.00; width: parent.width; height: parent.height * 0.2; clip: true
                        Image { source: "file:///home/revo/.config/quickshell/flame_mask.png"; sourceSize: Qt.size(160, 170); width: parent.parent.width; height: parent.parent.height; y: -parent.y }
                        layer.enabled: true; layer.effect: ColorOverlay { color: root.blue } }
                    Item { x: 0; y: parent.height * 0.20; width: parent.width; height: parent.height * 0.2; clip: true
                        Image { source: "file:///home/revo/.config/quickshell/flame_mask.png"; sourceSize: Qt.size(160, 170); width: parent.parent.width; height: parent.parent.height; y: -parent.y }
                        layer.enabled: true; layer.effect: ColorOverlay { color: root.teal } }
                    Item { x: 0; y: parent.height * 0.40; width: parent.width; height: parent.height * 0.2; clip: true
                        Image { source: "file:///home/revo/.config/quickshell/flame_mask.png"; sourceSize: Qt.size(160, 170); width: parent.parent.width; height: parent.parent.height; y: -parent.y }
                        layer.enabled: true; layer.effect: ColorOverlay { color: root.green } }
                    Item { x: 0; y: parent.height * 0.60; width: parent.width; height: parent.height * 0.2; clip: true
                        Image { source: "file:///home/revo/.config/quickshell/flame_mask.png"; sourceSize: Qt.size(160, 170); width: parent.parent.width; height: parent.parent.height; y: -parent.y }
                        layer.enabled: true; layer.effect: ColorOverlay { color: root.peach } }
                    Item { x: 0; y: parent.height * 0.80; width: parent.width; height: parent.height * 0.2; clip: true
                        Image { source: "file:///home/revo/.config/quickshell/flame_mask.png"; sourceSize: Qt.size(160, 170); width: parent.parent.width; height: parent.parent.height; y: -parent.y }
                        layer.enabled: true; layer.effect: ColorOverlay { color: root.mauve } }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.family: "monospace"
                    font.pixelSize: 36
                    font.bold: true
                    color: root.blue
                    text: root.promptHeader + (root.promptHeader.length < root.promptTarget.length ? "" : (root.cursorVisible ? "▎" : " "))
                    horizontalAlignment: Text.AlignHCenter
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.family: "monospace"
                    font.pixelSize: 20
                    color: root.green
                    text: root.promptDone ? "> START PREVIEW" : ""
                    visible: root.promptDone
                    horizontalAlignment: Text.AlignHCenter

                    Rectangle {
                        anchors.left: parent.right
                        anchors.leftMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                        width: 12; height: 20
                        color: root.green
                        visible: root.cursorVisible && !root.loadingBarFull
                    }
                }

                // Hold loading bar
                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 260; height: 6
                    visible: root.promptDone

                    Rectangle {
                        anchors.fill: parent
                        color: root.surface0; radius: 3
                    }

                    Rectangle {
                        width: parent.width * root.loadingProgress
                        height: parent.height
                        color: root.green; radius: 3
                        Behavior on width { SmoothedAnimation { duration: 150 } }
                    }

                    Text {
                        anchors.centerIn: parent
                        font.family: "monospace"; font.pixelSize: 9
                        color: root.base
                        text: Math.round(root.loadingProgress * 100) + "%"
                        visible: root.loadingProgress > 0 && root.loadingProgress < 1
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.family: "monospace"; font.pixelSize: 13
                    color: root.text; opacity: 0.5
                    text: root.holding && !root.loadingBarFull ? "[ hold ENTER to continue ]" : root.loadingBarFull ? "" : "[ hold ENTER ]"
                    visible: root.promptDone && !root.loadingBarFull
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        // Content display
        Item {
            anchors.fill: parent
            opacity: contentOpacity
            Behavior on opacity { NumberAnimation { duration: 500 } }

            Column {
                anchors.centerIn: parent
                spacing: 8

                // Flame logo in content
                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 120
                    height: 128
                    visible: root.contentChars > 0

                    Item { x: 0; y: parent.height * 0.00; width: parent.width; height: parent.height * 0.2; clip: true
                        Image { source: "file:///home/revo/.config/quickshell/flame_mask.png"; sourceSize: Qt.size(120, 128); width: parent.parent.width; height: parent.parent.height; y: -parent.y }
                        layer.enabled: true; layer.effect: ColorOverlay { color: root.blue } }
                    Item { x: 0; y: parent.height * 0.20; width: parent.width; height: parent.height * 0.2; clip: true
                        Image { source: "file:///home/revo/.config/quickshell/flame_mask.png"; sourceSize: Qt.size(120, 128); width: parent.parent.width; height: parent.parent.height; y: -parent.y }
                        layer.enabled: true; layer.effect: ColorOverlay { color: root.teal } }
                    Item { x: 0; y: parent.height * 0.40; width: parent.width; height: parent.height * 0.2; clip: true
                        Image { source: "file:///home/revo/.config/quickshell/flame_mask.png"; sourceSize: Qt.size(120, 128); width: parent.parent.width; height: parent.parent.height; y: -parent.y }
                        layer.enabled: true; layer.effect: ColorOverlay { color: root.green } }
                    Item { x: 0; y: parent.height * 0.60; width: parent.width; height: parent.height * 0.2; clip: true
                        Image { source: "file:///home/revo/.config/quickshell/flame_mask.png"; sourceSize: Qt.size(120, 128); width: parent.parent.width; height: parent.parent.height; y: -parent.y }
                        layer.enabled: true; layer.effect: ColorOverlay { color: root.peach } }
                    Item { x: 0; y: parent.height * 0.80; width: parent.width; height: parent.height * 0.2; clip: true
                        Image { source: "file:///home/revo/.config/quickshell/flame_mask.png"; sourceSize: Qt.size(120, 128); width: parent.parent.width; height: parent.parent.height; y: -parent.y }
                        layer.enabled: true; layer.effect: ColorOverlay { color: root.mauve } }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.family: "monospace"
                    font.pixelSize: 28
                    font.bold: true
                    color: root.blue
                    text: "REVO SHELL"
                    horizontalAlignment: Text.AlignHCenter
                    scale: 1 + root.pulse * 0.02
                    opacity: 0.9 + root.pulse * 0.1
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.family: "monospace"; font.pixelSize: 18
                    color: root.text
                    text: "A modern desktop shell built for YOU!!".substring(0, root.contentChars)
                    horizontalAlignment: Text.AlignHCenter
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.family: "monospace"; font.pixelSize: 14
                    color: root.text; opacity: root.contentChars > 30 ? 0.7 : 0
                    text: root.contentChars > 30 ? "made by @Revo" : ""
                    horizontalAlignment: Text.AlignHCenter
                    Behavior on opacity { NumberAnimation { duration: 300 } }
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 200; height: 1
                    color: root.text; opacity: root.contentChars > 35 ? 0.3 : 0
                    Behavior on opacity { NumberAnimation { duration: 300 } }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.family: "monospace"; font.pixelSize: 14
                    color: root.blue
                    text: root.contentChars > 35 ? "> system ready" : ""
                    horizontalAlignment: Text.AlignHCenter
                    Behavior on opacity { NumberAnimation { duration: 300 } }
                }
            }
        }
    }

    // === TIMERS ===

    Timer {
        id: pulseTimer
        interval: 32; repeat: true; running: false
        property real t: 0
        onTriggered: { t += 0.08; root.pulse = Math.sin(t); }
    }

    Timer {
        id: cursorBlinkTimer
        interval: 500; repeat: true; running: false
        onTriggered: { root.cursorVisible = !root.cursorVisible; }
    }

    Timer {
        interval: 1000; repeat: true; running: true; triggeredOnStart: true
        onTriggered: root.updateClock()
    }

    Timer {
        id: beadsTimer
        interval: 60; repeat: true; running: false
        onTriggered: {
            if (root.beadsCount < 10) root.beadsCount++;
            else running = false;
        }
    }

    Timer {
        id: promptTyper
        interval: 100; repeat: true; running: false
        onTriggered: {
            if (root.promptHeader.length < root.promptTarget.length) {
                root.promptHeader = root.promptTarget.substring(0, root.promptHeader.length + 1);
            } else {
                running = false;
                root.promptDone = true;
                cursorBlinkTimer.running = true;
                loadingBarTimer.running = true;
            }
        }
    }

    Timer {
        id: loadingBarTimer
        interval: 40; repeat: true; running: false
        onTriggered: {
            if (root.loadingBarFull) return;
            if (root.holding) {
                root.loadingProgress = Math.min(1, root.loadingProgress + 0.025);
                if (root.loadingProgress >= 1) {
                    root.loadingBarFull = true;
                    root.holding = false;
                    running = false;
                    cursorBlinkTimer.running = false;
                    root.promptOpacity = 0;
                    root.phase = 3;
                    root.contentChars = 0;
                    root.contentDone = false;
                    root.contentOpacity = 1;
                    contentTyper.running = true;
                    pulseTimer.running = true;
                }
            } else if (root.loadingProgress > 0) {
                root.loadingProgress = Math.max(0, root.loadingProgress - 0.04);
            }
        }
    }

    Timer {
        id: contentTyper
        interval: 40; repeat: true; running: false
        onTriggered: {
            let total = "A modern desktop shell built for YOU!!".length;
            if (root.contentChars < total) {
                root.contentChars++;
            } else {
                running = false;
                root.contentDone = true;
                contentFadeTimer.running = true;
            }
        }
    }

    Timer {
        id: typeTimer
        interval: 80; repeat: true; running: false
        onTriggered: {
            if (!root.stages[root.stageIndex]) return;
            root.visibleChars++;
            if (root.visibleChars >= root.stages[root.stageIndex].text.length) {
                running = false;
                root.stageFinished = true;
            }
        }
    }

    Timer {
        id: stageTimer
        interval: 100; repeat: false; running: false
        onTriggered: {
            root.stageIndex++;
            if (root.stageIndex < root.stages.length) {
                root.visibleChars = 0;
                root.stageFinished = false;
                typeTimer.interval = root.stages[root.stageIndex].delay;
                typeTimer.running = true;
            } else {
                root.phase = 2;
                root.promptHeader = "";
                root.promptDone = false;
                root.loadingProgress = 0;
                root.loadingBarFull = false;
                root.typewriterOpacity = 0;
                root.promptOpacity = 1;
                promptTyper.running = true;
            }
        }
    }

    // Intro: terminal screen → beads → typewriter
    Timer {
        id: introFadeTimer
        interval: 1500; repeat: false; running: false
        onTriggered: {
            root.terminalOpacity = 0;
            beadsFadeIn.start();
        }
    }

    Timer {
        id: beadsFadeIn
        interval: 400; repeat: false; running: false
        onTriggered: {
            root.beadsOpacity = 1;
            root.beadsCount = 0;
            beadsTimer.running = true;
            beadsHold.start();
        }
    }

    Timer {
        id: beadsHold
        interval: 800; repeat: false; running: false
        onTriggered: {
            root.beadsOpacity = 0;
            beadsFadeOut.start();
        }
    }

    Timer {
        id: beadsFadeOut
        interval: 300; repeat: false; running: false
        onTriggered: {
            root.phase = 1;
            root.typewriterOpacity = 1;
            typeTimer.interval = root.stages[0].delay;
            typeTimer.running = true;
        }
    }

    // Outro: content → beads → terminal
    Timer {
        id: contentFadeTimer
        interval: 2500; repeat: false; running: false
        onTriggered: {
            root.contentOpacity = 0;
            outroBeadsIn.start();
        }
    }

    Timer {
        id: outroBeadsIn
        interval: 400; repeat: false; running: false
        onTriggered: {
            root.beadsOpacity = 1;
            root.beadsCount = 0;
            beadsTimer.running = true;
            outroBeadsHold.start();
        }
    }

    Timer {
        id: outroBeadsHold
        interval: 800; repeat: false; running: false
        onTriggered: {
            root.beadsOpacity = 0;
            outroTerminal.start();
        }
    }

    Timer {
        id: outroTerminal
        interval: 300; repeat: false; running: false
        onTriggered: {
            root.phase = 4;
            root.terminalOpacity = 1;
            terminalExitTimer.running = true;
        }
    }

    Timer {
        id: terminalExitTimer
        interval: 3000; repeat: false; running: false
        onTriggered: {
            root.terminalOpacity = 0;
            quitTimer.running = true;
        }
    }

    Timer {
        id: quitTimer
        interval: 500; repeat: false; running: false
        onTriggered: { Qt.quit(); }
    }

    onStageFinishedChanged: {
        if (root.stageFinished && root.stages[root.stageIndex]) {
            stageTimer.interval = root.stages[root.stageIndex].hold;
            stageTimer.running = true;
        }
    }

    Component.onCompleted: {
        root.phase = 0;
        root.terminalOpacity = 1;
        themeReader.running = true;
        introFadeTimer.running = true;
    }
}
