import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root

    // ── tuneable ──────────────────────────────────────────────
    property string ollamaModel: "anthropic/claude-Sonnet-4-5"
    property string ollamaUrl:   "https://api.anthropic.com/v1/messages"
    // Set via env ANTHROPIC_API_KEY or edit locally — never commit secrets
    property string apiKey:      ""
    // ─────────────────────────────────────────────────────────

    property var messages: []        // { role, content, thinking }
    property bool isLoading: false
    property string streamBuffer: ""

    // ── colours (match your theme) ───────────────────────────
    readonly property color bgColor:      "#0d0d0d"
    readonly property color surfaceColor: "#1a1a1a"
    readonly property color userBubble:   "#2563eb"
    readonly property color aiBubble:     "#1e1e1e"
    readonly property color borderColor:  "#2a2a2a"
    readonly property color textColor:    "#e2e2e2"
    readonly property color mutedColor:   "#666666"
    readonly property color accentColor:  "#3b82f6"
    // ─────────────────────────────────────────────────────────

    Rectangle {
        anchors.fill: parent
        color: bgColor
        radius: 16
        border.color: borderColor
        border.width: 1
        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 0
            spacing: 0

            // ── Header ────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                height: 52
                color: surfaceColor
                radius: 16
                // bottom corners square
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left:   parent.left
                    anchors.right:  parent.right
                    height: 16
                    color: surfaceColor
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 12

                    // status dot
                    Rectangle {
                        width: 8; height: 8; radius: 4
                        color: root.isLoading ? "#f59e0b" : "#22c55e"
                        Behavior on color { ColorAnimation { duration: 300 } }
                    }

                    Text {
                        text: "AI Assistant"
                        color: textColor
                        font.pixelSize: 14
                        font.weight: Font.Medium
                        Layout.leftMargin: 8
                    }

                    Text {
                        text: root.ollamaModel
                        color: mutedColor
                        font.pixelSize: 11
                        Layout.leftMargin: 4
                    }

                    Item { Layout.fillWidth: true }

                    // Clear button
                    Rectangle {
                        width: 28; height: 28; radius: 8
                        color: clearHover.containsMouse ? "#2a2a2a" : "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            color: mutedColor
                            font.pixelSize: 12
                        }

                        HoverHandler { id: clearHover }
                        TapHandler {
                            onTapped: {
                                root.messages = [];
                                messagesModel.clear();
                                root.isLoading = false;
                                root.streamBuffer = "";
                            }
                        }
                    }
                }
            }

            // ── Messages ──────────────────────────────────────
            ListView {
                id: messageList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 10
                topMargin: 12
                bottomMargin: 8
                leftMargin: 12
                rightMargin: 12

                model: ListModel { id: messagesModel }

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    contentItem: Rectangle {
                        implicitWidth: 3
                        radius: 2
                        color: mutedColor
                        opacity: 0.5
                    }
                }

                delegate: Item {
                    width: messageList.width - 24
                    height: bubbleCol.height + 6

                    property bool isUser: model.role === "user"

                    Column {
                        id: bubbleCol
                        anchors.right: isUser ? parent.right : undefined
                        anchors.left:  isUser ? undefined      : parent.left
                        width: Math.min(parent.width * 0.85, 400)
                        spacing: 4

                        // role label
                        Text {
                            text: isUser ? "You" : root.ollamaModel
                            color: mutedColor
                            font.pixelSize: 10
                            anchors.right: isUser ? parent.right : undefined
                        }

                        // bubble
                        Rectangle {
                            width: parent.width
                            height: msgText.implicitHeight + 18
                            radius: 12
                            color: isUser ? userBubble : aiBubble
                            border.color: isUser ? "transparent" : borderColor
                            border.width: 1

                            Text {
                                id: msgText
                                anchors {
                                    left: parent.left; right: parent.right
                                    top: parent.top
                                    margins: 10
                                    topMargin: 9
                                }
                                text: model.content
                                color: textColor
                                font.pixelSize: 13
                                wrapMode: Text.Wrap
                                lineHeight: 1.4
                            }
                        }
                    }
                }

                // auto-scroll
                onCountChanged:        Qt.callLater(() => positionViewAtEnd())
                onContentHeightChanged: Qt.callLater(() => positionViewAtEnd())
            }

            // ── Loading indicator ─────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                height: root.isLoading ? 32 : 0
                color: "transparent"
                clip: true
                Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6
                    visible: root.isLoading

                    Repeater {
                        model: 3
                        Rectangle {
                            width: 6; height: 6; radius: 3
                            color: accentColor
                            SequentialAnimation on opacity {
                                loops: Animation.Infinite
                                NumberAnimation { to: 0.2; duration: 400; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 1.0; duration: 400; easing.type: Easing.InOutSine }
                                PauseAnimation { duration: index * 150 }
                            }
                        }
                    }

                    Text {
                        text: "Thinking..."
                        color: mutedColor
                        font.pixelSize: 12
                    }
                }
            }

            // ── Input bar ─────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                Layout.margins: 10
                height: Math.max(44, inputField.implicitHeight + 20)
                radius: 12
                color: surfaceColor
                border.color: inputField.activeFocus ? accentColor : borderColor
                border.width: 1
                Behavior on border.color { ColorAnimation { duration: 200 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 6

                    TextArea {
                        id: inputField
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        placeholderText: "Message..."
                        placeholderTextColor: mutedColor
                        color: textColor
                        font.pixelSize: 13
                        wrapMode: TextArea.Wrap
                        background: null
                        padding: 4

                        Keys.onReturnPressed: (event) => {
                            if (event.modifiers & Qt.ShiftModifier) {
                                event.accepted = false;
                            } else {
                                event.accepted = true;
                                sendMessage();
                            }
                        }
                    }

                    // Send button
                    Rectangle {
                        width: 32; height: 32; radius: 10
                        color: sendHover.containsMouse ? Qt.lighter(accentColor, 1.2) : accentColor
                        opacity: (inputField.text.trim().length > 0 && !root.isLoading) ? 1.0 : 0.35
                        Behavior on color   { ColorAnimation { duration: 150 } }
                        Behavior on opacity { NumberAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: "↑"
                            color: "white"
                            font.pixelSize: 16
                            font.weight: Font.Bold
                        }

                        HoverHandler { id: sendHover }
                        TapHandler {
                            onTapped: sendMessage()
                        }
                    }
                }
            }
        } // ColumnLayout
    } // Rectangle

    // ── IPC process: call Ollama ───────────────────────────────
    Process {
        id: ollamaProcess

        property string responseText: ""
        property int   assistantIndex: -1

        stdout: StdioCollector {
            onStreamFinished: {
                // stream ended — finalise
                ollamaProcess.responseText = "";
                root.isLoading = false;
            }
        }

        // We read line-by-line via stderr trick — actually use onStdout signal
        // Quickshell Process doesn't give us line signals, so we poll via StdioCollector
        // and parse the full JSON at the end.
        // For true streaming use a small python helper (see comment below).
    }

    // ── HTTP helper script (writes final answer to /tmp/qs_ai_response) ──
    // We launch a bash+curl one-liner; when done we read the file.
    Process {
        id: curlProcess
        property int assistantIndex: -1

        stdout: StdioCollector {
            onStreamFinished: {
                let raw = this.text.trim();
                if (raw === "") { root.isLoading = false; return; }

                // Ollama returns one JSON object per line (streaming=false gives one object)
                try {
                    let obj = JSON.parse(raw);
                    let answer = obj.message ? obj.message.content
                                : (obj.choices ? obj.choices[0].message.content : raw);

                    if (curlProcess.assistantIndex >= 0 &&
                        curlProcess.assistantIndex < messagesModel.count) {
                        messagesModel.set(curlProcess.assistantIndex, {
                            "role": "assistant",
                            "content": answer
                        });
                    }
                } catch(e) {
                    if (curlProcess.assistantIndex >= 0) {
                        messagesModel.set(curlProcess.assistantIndex, {
                            "role": "assistant",
                            "content": raw
                        });
                    }
                }
                root.isLoading = false;
            }
        }
    }

    // ── sendMessage() ─────────────────────────────────────────
    function sendMessage() {
        let text = inputField.text.trim();
        if (text === "" || root.isLoading) return;

        inputField.text = "";
        root.isLoading  = true;

        // add user bubble
        messagesModel.append({ "role": "user", "content": text });

        // add placeholder assistant bubble
        let idx = messagesModel.count;
        messagesModel.append({ "role": "assistant", "content": "..." });
        curlProcess.assistantIndex = idx;

        // build messages array for Ollama
        let msgs = [{ "role": "system", "content": root.systemPrompt }];
        // include last 10 turns for context
        let start = Math.max(0, messagesModel.count - 12);
        for (let i = start; i < messagesModel.count - 1; i++) {
            let m = messagesModel.get(i);
            msgs.push({ "role": m.role, "content": m.content });
        }

        let payload = JSON.stringify({
            "model":    root.ollamaModel,
            "messages": msgs,
            "stream":   false
        });

       curlProcess.command = [
    "bash", "-c",
    "curl -s -X POST '" + root.ollamaUrl + "' " +
    "-H 'Content-Type: application/json' " +
    "-H 'Authorization: Bearer " + root.apiKey + "' " +
    "-H 'HTTP-Referer: https://localhost' " +
    "-d '" + payload.replace(/'/g, "'\\''") + "'"

        ];
        curlProcess.running = false;
        curlProcess.running = true;
    }
}
