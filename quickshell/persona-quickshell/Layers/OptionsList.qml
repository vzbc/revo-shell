import QtQuick
import Quickshell
import Quickshell.Io
import qs.Data as Dat

Item {
    id: revealRoot
    anchors.fill: parent
    property int activeBar: 0
    property bool revealed: false
    property bool mounted: false
    property int localTab: activeBar
    property int activeShaderIndex: -1
    onActiveBarChanged: localTab = activeBar
    FontLoader {
        id: bebasNeue
        source: Qt.resolvedUrl("../Assets/fonts/BebasNeue-Regular.ttf")
    }
    FontLoader {
        id: montserrat
        source: Qt.resolvedUrl("../Assets/fonts/Montserrat-Light.ttf")
    }
    readonly property var revealContent: [
        {
            upper: ["Filter to reduce Bluelight"],
            lower: "blue light filter",
            portrait: Qt.resolvedUrl("../Assets/components/mainm.jpeg")
        },
        {
            upper: ["Black and white only"],
            lower: "grey scale filter",
            portrait: Qt.resolvedUrl("../Assets/components/mainm2.jpeg")
        },
        {
            upper: ["Invert all the colors cuz why not"],
            lower: "inversion filter",
            portrait: Qt.resolvedUrl("../Assets/components/mainf.jpeg")
        },
    ]

    readonly property var shaderPaths: [Qt.resolvedUrl("../Assets/ScreenShaders/bluelight.frag").toString().replace("file://", ""), Qt.resolvedUrl("../Assets/ScreenShaders/grey.glsl").toString().replace("file://", ""), Qt.resolvedUrl("../Assets/ScreenShaders/invert.glsl").toString().replace("file://", "")]

    readonly property string offShader: Qt.resolvedUrl("../Assets/ScreenShaders/vibrant.glsl").toString().replace("file://", "")

    function toggleShader(index) {
        if (activeShaderIndex === index) {
            activeShaderIndex = -1;
            shaderProc.command = ["hyprctl", "eval", "hl.config({ decoration = { screen_shader = \"\" } })"];
            shaderProc.startDetached();
        } else {
            activeShaderIndex = index;
            shaderProc.command = ["hyprctl", "eval", "hl.config({ decoration = { screen_shader = \"" + shaderPaths[index] + "\" } })"];
            shaderProc.startDetached();
        }
    }

    Process {
        id: shaderProc
        stdout: SplitParser {
            onRead: data => console.log("STDOUT:", data)
        }
        stderr: SplitParser {
            onRead: data => console.log("STDERR:", data)
        }
        onExited: (code, status) => console.log("Exited:", code, status)
    }

    Rectangle {
        anchors.fill: parent
        color: "#ad282d36"
        z: 12
        opacity: revealRoot.revealed ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: 320
            }
        }
    }

    Item {
        id: portraitShell
        z: 50
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        x: parent.width * 0.58
        width: parent.width * 0.52
        clip: true
        opacity: revealRoot.revealed && revealRoot.mounted ? 0.96 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: 350
            }
        }

        transform: [
            Translate {
                x: revealRoot.revealed ? 0 : 78
                Behavior on x {
                    NumberAnimation {
                        duration: 500
                        easing.type: Easing.OutBack
                        easing.overshoot: 2.0
                    }
                }
            },
            Scale {
                xScale: revealRoot.revealed ? 1 : 0.94
                yScale: revealRoot.revealed ? 1 : 0.94
                origin.x: portraitShell.width / 2
                origin.y: portraitShell.height / 2
                Behavior on xScale {
                    NumberAnimation {
                        duration: 500
                        easing.type: Easing.OutBack
                        easing.overshoot: 2.0
                    }
                }
                Behavior on yScale {
                    NumberAnimation {
                        duration: 500
                        easing.type: Easing.OutBack
                        easing.overshoot: 2.0
                    }
                }
            }
        ]

        Image {
            source: revealRoot.revealContent[revealRoot.localTab].portrait
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
            verticalAlignment: Image.AlignTop
            horizontalAlignment: Image.AlignRight
            transform: [
                Rotation {
                    angle: 0
                },
                Scale {
                    xScale: 1.08
                    yScale: 1.0
                    origin.x: portraitShell.width
                }
            ]
        }
    }

    Item {
        id: revealPanel
        z: 20
        x: parent.width * 0.02
        y: parent.height * 0.52
        width: parent.width * 0.90
        height: parent.height * 0.60
        enabled: revealRoot.revealed && revealRoot.mounted
        opacity: revealRoot.revealed && revealRoot.mounted ? 0.92 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: 300
            }
        }

        transform: [
            Rotation {
                angle: -20
                origin.x: 0
                origin.y: revealPanel.height
            },
            Scale {
                xScale: revealRoot.revealed ? 1 : 0.72
                origin.x: 0
                origin.y: revealPanel.height
                Behavior on xScale {
                    NumberAnimation {
                        duration: 460
                        easing.type: Easing.OutBack
                        easing.overshoot: 3.0
                    }
                }
            },
            Translate {
                x: revealRoot.revealed ? 0 : -120
                Behavior on x {
                    NumberAnimation {
                        duration: 460
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.5
                    }
                }
            }
        ]

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: "#f50f1c69"
                }
                GradientStop {
                    position: 1.0
                    color: "#f7081044"
                }
            }
        }

        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 8
            color: "#c4001a"
        }

        Row {
            id: tabRow
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: parent.height * 0.02
            anchors.leftMargin: parent.width * 0.02
            anchors.rightMargin: parent.width * 0.10
            height: parent.height * 0.10
            spacing: 12

            Repeater {
                model: ["Bluelight", "Greyscale", "Inversion"]
                delegate: Item {
                    required property string modelData
                    required property int index

                    width: (tabRow.width - 24) / 3
                    height: tabRow.height

                    Rectangle {
                        id: tabRect
                        anchors.centerIn: parent
                        width: parent.width
                        height: parent.height
                        color: index === revealRoot.localTab ? "#4a8fff" : "#0a0a0a"
                        border.color: index === revealRoot.localTab ? "#4a8fff" : "#26ffffff"
                        border.width: 1
                        transformOrigin: Item.Center

                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }
                        }
                        Behavior on scale {
                            NumberAnimation {
                                duration: 120
                                easing.type: Easing.OutCubic
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: parent.parent.modelData
                            font.pixelSize: 14
                            color: parent.parent.index === revealRoot.localTab ? "#111111" : "#66ffffff"
                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onPressed: tabRect.scale = 0.90
                        onReleased: tabRect.scale = 1.0
                        onCanceled: tabRect.scale = 1.0
                        onClicked: revealRoot.localTab = index
                    }
                }
            }
        }

        Rectangle {
            id: upperBar
            anchors.top: tabRow.bottom
            anchors.topMargin: parent.height * 0.01
            anchors.left: parent.left
            anchors.right: parent.right
            height: parent.height * 0.42
            color: "#eb000000"

            Column {
                anchors.centerIn: parent
                spacing: 10

                Repeater {
                    model: revealRoot.revealContent[revealRoot.localTab].upper
                    delegate: Text {
                        required property string modelData
                        text: modelData
                        font.family: montserrat.name
                        font.pixelSize: 20
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        width: upperBar.width
                    }
                }
            }
        }

        Rectangle {
            id: lowerBar
            anchors.top: upperBar.bottom
            anchors.topMargin: parent.height * 0.04
            anchors.right: parent.right
            anchors.rightMargin: parent.width * 0.05
            width: parent.width * 0.60
            height: parent.height * 0.20
            color: revealRoot.activeShaderIndex === revealRoot.localTab ? "#994a8fff" : "#eb000000"
            border.color: revealRoot.activeShaderIndex === revealRoot.localTab ? "#4a8fff" : "#26ffffff"
            border.width: 1
            transformOrigin: Item.Center

            Behavior on color {
                ColorAnimation {
                    duration: 150
                }
            }
            Behavior on scale {
                NumberAnimation {
                    duration: 120
                    easing.type: Easing.OutCubic
                }
            }

            Row {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 22
                anchors.right: parent.right
                anchors.rightMargin: 28
                spacing: 12

                Text {
                    text: revealRoot.revealContent[revealRoot.localTab].lower
                    font.family: montserrat.name
                    font.pixelSize: 18
                    color: "white"
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignLeft
                }

                Text {
                    text: revealRoot.activeShaderIndex === revealRoot.localTab ? "● ON" : "○ OFF"
                    font.family: bebasNeue.name
                    font.pixelSize: 16
                    color: revealRoot.activeShaderIndex === revealRoot.localTab ? "#4a8fff" : "#66ffffff"
                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                onPressed: lowerBar.scale = 0.97
                onReleased: lowerBar.scale = 1.0
                onCanceled: lowerBar.scale = 1.0
                onClicked: revealRoot.toggleShader(revealRoot.localTab)
            }
        }
    }

    Row {
        z: 14
        x: parent.width * 0.06
        y: parent.height * 0.10
        spacing: 6
        opacity: revealRoot.revealed ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: 300
            }
        }

        transform: Rotation {
            angle: -20
            origin.x: 0
            origin.y: 0
        }
    }
}
