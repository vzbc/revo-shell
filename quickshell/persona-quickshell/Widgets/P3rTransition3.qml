import QtQuick
import Quickshell
import Quickshell.Wayland

Scope {
    id: root
    property bool shouldShow: false
    property var targetScreen: null
    signal finished
    signal peaked

    readonly property var palette: ["#0d1a3a", "#1a6aff", "#7dd4fc"]

    LazyLoader {
        active: true
        PanelWindow {
            id: transitionWindow
            visible: root.shouldShow
            screen: root.targetScreen
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            anchors {
                left: true
                right: true
                top: true
                bottom: true
            }

            onVisibleChanged: {
                if (visible) {
                    blocksContainer.visible = true;
                    blocksContainer.opacity = 1;
                    bubbleField.visible = false;
                    startDelay.start();
                }
            }

            Timer {
                id: startDelay
                interval: 80
                repeat: false
                onTriggered: {
                    bubbleField.generate();
                    blockRepeater.restartAll();
                }
            }

            Timer {
                id: finishTimer
                interval: 1600
                repeat: false
                onTriggered: {
                    safetyTimer.stop();
                    root.shouldShow = false;
                    root.finished();
                }
            }

            Timer {
                id: safetyTimer
                interval: 3500
                repeat: false
                onTriggered: {
                    finishTimer.stop();
                    root.shouldShow = false;
                    root.finished();
                }
            }

            Item {
                id: blocksContainer
                anchors.fill: parent
                z: 1

                Repeater {
                    id: blockRepeater
                    model: [
                        {
                            color: root.palette[0],
                            delay: 0
                        },
                        {
                            color: root.palette[1],
                            delay: 100
                        },
                        {
                            color: root.palette[2],
                            delay: 200
                        }
                    ]

                    function restartAll() {
                        for (var i = 0; i < count; i++)
                            itemAt(i).startAnim();
                    }

                    Item {
                        id: blockItem
                        required property var modelData
                        required property int index
                        anchors.fill: parent
                        z: 999 - index

                        function startAnim() {
                            blockAnim.restart();
                        }

                        Rectangle {
                            id: block
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            width: parent.width
                            color: blockItem.modelData.color
                            transformOrigin: Item.Left
                            transform: Scale {
                                id: blockScale
                                xScale: 0
                            }
                        }

                        SequentialAnimation {
                            id: blockAnim
                            running: false
                            PauseAnimation {
                                duration: blockItem.modelData.delay
                            }
                            // Wipe in
                            NumberAnimation {
                                target: blockScale
                                property: "xScale"
                                from: 0
                                to: 1
                                duration: 350
                                easing.type: Easing.InOutQuart
                            }
                            // Hold
                            PauseAnimation {
                                duration: 100
                            }
                            ScriptAction {
                                script: {
                                    if (blockItem.index === 2)
                                        controller.startBubbles();
                                }
                            }
                        }
                    }
                }
            }

            Item {
                id: bubbleField
                anchors.fill: parent
                z: 10
                visible: false

                property var bubbles: []
                property int maxDuration: 1600

                function generate() {
                    var w = transitionWindow.width;
                    var h = transitionWindow.height;
                    if (w <= 0 || h <= 0) {
                        bubbles = [];
                        return;
                    }
                    var cell = Math.max(70, Math.round(Math.min(w, h) / 9));
                    var cols = Math.max(6, Math.ceil(w / cell));
                    var rows = Math.max(5, Math.ceil(h / cell));
                    var cw = w / cols;
                    var ch = h / rows;
                    var arr = [];
                    var maxTotal = 0;
                    var colStep = 10;
                    for (var r = 0; r < rows; r++) {
                        for (var c = 0; c < cols; c++) {
                            var size = Math.max(cw, ch) * (1.25 + Math.random() * 0.2);
                            var cx = c * cw + cw / 2 + (Math.random() - 0.5) * cw * 0.3;
                            var cy = r * ch + ch / 2 + (Math.random() - 0.5) * ch * 0.3;
                            var rise = 400 + Math.random() * 250;
                            var delay = (cols - 1 - c) * colStep + Math.random();
                            var drift = (Math.random() - 0.5) * cw * 1.1;
                            var col = root.palette[Math.floor(Math.random() * root.palette.length)];
                            arr.push({
                                homeX: cx - size / 2,
                                homeY: cy - size / 2,
                                size: size,
                                rise: rise,
                                delay: delay,
                                drift: drift,
                                color: col
                            });
                            if (delay + rise > maxTotal)
                                maxTotal = delay + rise;
                        }
                    }
                    maxDuration = maxTotal;
                    bubbles = arr;
                }

                function startAll() {
                    for (var i = 0; i < bubbleRepeater.count; i++)
                        bubbleRepeater.itemAt(i).startAnim();
                }

                Repeater {
                    id: bubbleRepeater
                    model: bubbleField.bubbles

                    Item {
                        id: bubble
                        required property var modelData
                        required property int index
                        x: modelData.homeX
                        y: modelData.homeY
                        width: modelData.size
                        height: modelData.size
                        opacity: 1

                        Rectangle {
                            id: bubbleBg
                            anchors.fill: parent
                            radius: 0
                            color: root.palette[0]

                            // Glossy highlight fades in as the square rounds into a bubble.
                            Rectangle {
                                width: parent.width * 0.32
                                height: parent.height * 0.32
                                radius: width / 2
                                x: parent.width * 0.18
                                y: parent.height * 0.16
                                color: "#ffffff"
                                opacity: parent.width > 0 ? 0.25 * (bubbleBg.radius / (parent.width / 2)) : 0
                            }
                        }

                        function startAnim() {
                            bubble.x = bubble.modelData.homeX;
                            bubble.y = bubble.modelData.homeY;
                            bubble.opacity = 1;
                            bubbleBg.radius = 0;
                            bubbleBg.color = root.palette[0];
                            bubbleAnim.restart();
                        }

                        SequentialAnimation {
                            id: bubbleAnim
                            running: false
                            PauseAnimation {
                                duration: bubble.modelData.delay
                            }
                            ParallelAnimation {
                                // Morph the square into a round bubble.
                                NumberAnimation {
                                    target: bubbleBg
                                    property: "radius"
                                    from: 0
                                    to: bubble.modelData.size / 2
                                    duration: 300
                                    easing.type: Easing.OutQuad
                                }
                                // Bleed from the screen colour into the bubble's colour.
                                ColorAnimation {
                                    target: bubbleBg
                                    property: "color"
                                    from: root.palette[0]
                                    to: bubble.modelData.color
                                    duration: 340
                                    easing.type: Easing.OutQuad
                                }
                                // Float straight up and out of the top of the screen.
                                NumberAnimation {
                                    target: bubble
                                    property: "y"
                                    from: bubble.modelData.homeY
                                    to: -bubble.modelData.size * 2
                                    duration: bubble.modelData.rise
                                    easing.type: Easing.InCubic
                                }
                                // Gentle horizontal sway as it rises.
                                NumberAnimation {
                                    target: bubble
                                    property: "x"
                                    from: bubble.modelData.homeX
                                    to: bubble.modelData.homeX + bubble.modelData.drift
                                    duration: bubble.modelData.rise
                                    easing.type: Easing.InOutSine
                                }
                                // Fade away over the back half of the rise.
                                SequentialAnimation {
                                    PauseAnimation {
                                        duration: bubble.modelData.rise * 0.5
                                    }
                                    NumberAnimation {
                                        target: bubble
                                        property: "opacity"
                                        from: 1
                                        to: 0
                                        duration: bubble.modelData.rise * 0.5
                                        easing.type: Easing.InQuad
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ---- Controller for the entrance -> bubble exit handoff ----
            QtObject {
                id: controller
                function startBubbles() {
                    bubbleField.visible = true;
                    bubbleField.startAll();
                    blocksContainer.visible = false;
                    root.peaked();
                    finishTimer.interval = bubbleField.maxDuration + 250;
                    finishTimer.restart();
                    safetyTimer.interval = bubbleField.maxDuration + 800;
                    safetyTimer.restart();
                }
            }
        }
    }
}
