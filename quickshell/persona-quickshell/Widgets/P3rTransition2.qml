import QtQuick
import Quickshell
import Quickshell.Wayland

Scope {
    id: root
    property bool shouldShow: false
    property var targetScreen: null
    signal finished
    signal peaked

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
                if (visible)
                    startDelay.start();
            }

            Timer {
                id: startDelay
                interval: 80
                repeat: false
                onTriggered: {
                    bgBlock.startAnim();
                    blockRepeater.restartAll();
                }
            }

            Timer {
                id: safetyTimer
                interval: 1500
                repeat: false
                onTriggered: {
                    root.shouldShow = false;
                    root.finished();
                }
            }

            Rectangle {
                id: bgBlock
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width
                color: "#000000"
                x: -width
                z: 0
                function startAnim() {
                    bgBlock.opacity = 1;
                    bgBlock.x = -bgBlock.width;
                    bgAnim.restart();
                }
                SequentialAnimation {
                    id: bgAnim
                    running: false
                    NumberAnimation {
                        target: bgBlock
                        property: "x"
                        from: -bgBlock.width
                        to: 0
                        duration: 350
                        easing.type: Easing.OutExpo
                    }
                    PauseAnimation {
                        duration: 400
                    }
                    NumberAnimation {
                        target: bgBlock
                        property: "x"
                        from: 0
                        to: -bgBlock.width
                        duration: 200
                        easing.type: Easing.InExpo
                    }
                }
            }

            Column {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10
                z: 1

                Repeater {
                    id: blockRepeater
                    model: [
                        {
                            color: "#0d1a3a",
                            delay: 0
                        },
                        {
                            color: "#1a6aff",
                            delay: 80
                        },
                        {
                            color: "#7dd4fc",
                            delay: 160
                        },
                    ]

                    function restartAll() {
                        for (var i = 0; i < count; i++)
                            itemAt(i).startAnim();
                    }

                    Item {
                        id: blockItem
                        required property var modelData
                        required property int index
                        width: transitionWindow.width * 0.95
                        height: transitionWindow.height * 0.3
                        x: -width
                        clip: true

                        transform: Matrix4x4 {
                            matrix: Qt.matrix4x4(1, -0.15, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                        }

                        Rectangle {
                            anchors.fill: parent
                            color: blockItem.modelData.color
                        }

                        function startAnim() {
                            blockItem.opacity = 1;
                            blockAnim.restart();
                        }

                        SequentialAnimation {
                            id: blockAnim
                            running: false
                            PauseAnimation {
                                duration: blockItem.modelData.delay
                            }
                            NumberAnimation {
                                target: blockItem
                                property: "x"
                                from: -blockItem.width
                                to: 0
                                duration: 350
                                easing.type: Easing.OutExpo
                            }
                            ScriptAction {
                                script: {
                                    if (blockItem.index === 2) {
                                        safetyTimer.start();
                                        root.peaked();
                                    }
                                }
                            }
                            PauseAnimation {
                                duration: 200
                            }
                            NumberAnimation {
                                target: blockItem
                                property: "opacity"
                                from: 1
                                to: 0
                                duration: 200
                                easing.type: Easing.InQuad
                            }
                            ScriptAction {
                                script: {
                                    if (blockItem.index === 2) {
                                        safetyTimer.stop();
                                        root.shouldShow = false;
                                        root.finished();
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
