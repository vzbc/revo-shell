// ChatThread.qml — vertical list of MessageBubble + optional typing marker
import QtQuick

Item {
    id: root

    // messages: [{ text, alignEnd, muted, sender, footer, initials, avatarImage, reactions, delay }]
    property var messages: []
    property bool autoplay: true
    property int stepDelay: 900
    property bool showTyping: false
    property string typingName: ""
    property string typingAvatarImage: ""
    property string fontFamily: "SF Pro Display"

    property int revealed: 0
    property var shown: []

    clip: true
    implicitWidth: 360
    implicitHeight: 420

    function appendAt(i) {
        if (!messages || i >= messages.length)
            return false
        var m = messages[i]
        var next = shown.slice()
        next.push({
            text: m.text || "",
            alignEnd: !!m.alignEnd,
            muted: !!m.muted,
            sender: m.sender || "",
            footer: m.footer || "",
            initials: m.initials || "",
            avatarImage: m.avatarImage || "",
            reactions: m.reactions || []
        })
        shown = next
        revealed = i + 1
        flick.contentY = Math.max(0, flick.contentHeight - flick.height)
        return true
    }

    function play() {
        revealed = 0
        shown = []
        showTyping = false
        if (!messages || messages.length === 0)
            return
        // First bubble immediately so chat is never empty
        appendAt(0)
        if (messages.length > 1) {
            showTyping = true
            stepTimer.restart()
        }
    }

    Flickable {
        id: flick
        anchors.fill: parent
        contentHeight: col.implicitHeight + 8
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: col
            width: parent.width
            spacing: 14

            Repeater {
                model: root.shown.length

                MessageBubble {
                    id: bubbleDel
                    required property int index
                    width: col.width
                    text: root.shown[index].text || ""
                    alignEnd: !!root.shown[index].alignEnd
                    muted: !!root.shown[index].muted
                    sender: root.shown[index].sender || ""
                    footer: root.shown[index].footer || ""
                    initials: root.shown[index].initials || ""
                    avatarImage: root.shown[index].avatarImage || ""
                    reactions: root.shown[index].reactions || []
                    fontFamily: root.fontFamily
                    opacity: 0

                    Component.onCompleted: appear.restart()

                    // target must be the bubble itself (not parent/ParallelAnimation)
                    ParallelAnimation {
                        id: appear
                        NumberAnimation {
                            target: bubbleDel
                            property: "opacity"
                            from: 0
                            to: 1
                            duration: 280
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }

            // Typing marker
            Row {
                visible: root.showTyping && root.revealed < root.messages.length
                spacing: 8

                Rectangle {
                    width: 28
                    height: 28
                    radius: 14
                    color: "#2C2C2E"
                    anchors.verticalCenter: parent.verticalCenter

                    CircularImage {
                        anchors.fill: parent
                        anchors.margins: 1
                        source: root.typingAvatarImage.length > 0 ? root.typingAvatarImage : ""
                        initials: root.typingName.length > 0 ? root.typingName.charAt(0).toUpperCase() : "?"
                        fontFamily: root.fontFamily
                        fallbackColor: "transparent"
                        fontPixelSize: 12
                    }
                }

                Rectangle {
                    width: typingRow.implicitWidth + 24
                    height: 36
                    radius: 18
                    color: "#1C1C1E"

                    Row {
                        id: typingRow
                        anchors.centerIn: parent
                        spacing: 5

                        Repeater {
                            model: 3

                            Rectangle {
                                width: 7
                                height: 7
                                radius: 4
                                color: "#6E6E73"
                                anchors.verticalCenter: parent.verticalCenter
                                opacity: 0.4

                                SequentialAnimation on opacity {
                                    loops: Animation.Infinite
                                    running: root.showTyping && root.visible
                                    NumberAnimation { to: 1.0; duration: 400 }
                                    NumberAnimation { to: 0.3; duration: 400 }
                                }
                            }
                        }
                    }
                }

                Text {
                    visible: root.typingName.length > 0
                    text: root.typingName + " is typing…"
                    font.family: root.fontFamily
                    font.pixelSize: 12
                    font.italic: true
                    color: "#6E6E73"
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    Timer {
        id: stepTimer
        interval: {
            if (root.revealed <= 0 || root.revealed > root.messages.length)
                return root.stepDelay
            var prev = root.messages[root.revealed - 1]
            return prev && prev.delay !== undefined ? prev.delay : root.stepDelay
        }
        repeat: false
        onTriggered: {
            if (root.revealed >= root.messages.length) {
                root.showTyping = false
                return
            }
            root.appendAt(root.revealed)
            if (root.revealed >= root.messages.length)
                root.showTyping = false
            else
                stepTimer.restart()
        }
    }

    onMessagesChanged: {
        if (autoplay)
            Qt.callLater(play)
    }

    Component.onCompleted: {
        if (autoplay && messages && messages.length > 0)
            Qt.callLater(play)
    }

    onVisibleChanged: {
        if (visible && autoplay && revealed === 0 && messages && messages.length > 0)
            Qt.callLater(play)
        else if (!visible)
            stepTimer.stop()
    }
}
