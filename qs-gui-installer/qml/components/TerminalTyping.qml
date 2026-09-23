// TerminalTyping.qml - Typing lines + animated outputs (Magic UI Terminal → QML)
import QtQuick

Item {
    id: root

    property var lines: []
    property int visibleCount: 0
    property int charIndex: 0
    property bool running: true
    property int typeSpeed: 45
    property int lineDelay: 400

    readonly property color frameColor: "#0A0A0A"
    readonly property color borderColor: "#222222"
    readonly property color titleBar: "#111111"
    readonly property color promptColor: "#3B82F6"
    readonly property color outputGreen: "#22C55E"
    readonly property color textPrimary: "#E5E5E5"

    signal completed()

    implicitWidth: 520
    implicitHeight: 320

    function restart() {
        visibleCount = 0
        charIndex = 0
        typeTimer.stop()
        if (running && lines.length > 0)
            typeTimer.start()
    }

    function currentLine() {
        if (visibleCount >= lines.length)
            return null
        return lines[visibleCount]
    }

    function displayText(obj) {
        if (obj === null || obj === undefined)
            return ""
        if (typeof obj === "string")
            return obj
        return obj.text !== undefined ? obj.text : ""
    }

    function isCommand(obj) {
        if (obj === null || typeof obj !== "object")
            return false
        return obj.type === "cmd"
    }

    function lineColor(obj) {
        if (obj === null || typeof obj !== "object")
            return textPrimary
        if (obj.color === "blue")
            return promptColor
        if (obj.color === "green")
            return outputGreen
        if (obj.color === "muted")
            return "#666666"
        return textPrimary
    }

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: root.frameColor
        border.width: 1
        border.color: root.borderColor
        clip: true

        Rectangle {
            id: chrome
            width: parent.width
            height: 36
            color: root.titleBar

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Repeater {
                    model: ["#FF5F57", "#FEBC2E", "#28C840"]
                    Rectangle {
                        width: 11
                        height: 11
                        radius: 6
                        color: modelData
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                text: "Terminal"
                font.family: "SF Pro Display"
                font.pixelSize: 12
                color: "#666666"
            }

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: root.borderColor
            }
        }

        Flickable {
            id: flick
            width: parent.width
            height: parent.height - chrome.height
            anchors.top: chrome.bottom
            contentHeight: col.implicitHeight + 24
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: col
                width: parent.width - 28
                x: 14
                y: 12
                spacing: 6

                Repeater {
                    model: root.visibleCount

                    delegate: Text {
                        id: doneLine
                        required property int index
                        width: col.width
                        text: root.displayText(root.lines[doneLine.index])
                        font.family: "SF Mono"
                        font.pixelSize: 13
                        color: root.lineColor(root.lines[doneLine.index])
                        wrapMode: Text.WrapAnywhere
                    }
                }

                Text {
                    id: typingLine
                    width: col.width
                    visible: root.visibleCount < root.lines.length
                    font.family: "SF Mono"
                    font.pixelSize: 13
                    color: {
                        var ln = root.currentLine()
                        return root.lineColor(ln)
                    }
                    wrapMode: Text.WrapAnywhere
                    text: {
                        var ln = root.currentLine()
                        if (ln === null)
                            return ""
                        var full = root.displayText(ln)
                        return full.substring(0, Math.min(root.charIndex, full.length))
                            + (root.charIndex % 2 === 0 && root.charIndex < full.length ? "█" : "▌")
                    }
                }
            }

            onContentHeightChanged: contentY = Math.max(0, contentHeight - height)
        }
    }

    Timer {
        id: typeTimer
        interval: root.typeSpeed
        repeat: true
        running: root.running
        onTriggered: {
            var ln = root.currentLine()
            if (ln === null) {
                stop()
                root.completed()
                return
            }
            var full = root.displayText(ln)
            var isCmd = root.isCommand(ln)
            var delay = ln && ln.delay !== undefined ? ln.delay : 0

            if (root.charIndex === 0 && delay > 0 && !ln._delayed) {
                ln._delayed = true
                root.lines[root.visibleCount] = ln
                pauseTimer.interval = delay
                pauseTimer.start()
                stop()
                return
            }

            if (root.charIndex <= full.length) {
                root.charIndex++
            } else {
                root.visibleCount++
                root.charIndex = 0
                if (root.visibleCount >= root.lines.length) {
                    stop()
                    root.completed()
                }
            }
        }
    }

    Timer {
        id: pauseTimer
        onTriggered: typeTimer.start()
    }

    onRunningChanged: {
        if (running)
            restart()
        else
            typeTimer.stop()
    }

    Component.onCompleted: {
        if (running)
            restart()
    }
}
