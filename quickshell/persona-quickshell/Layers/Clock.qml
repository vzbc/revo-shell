import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import "../Data" as Dat
import qs.Widgets.Info as Info

Scope {
    id: clockScope

    readonly property real vw: 500 / 26.0417

    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: clockWindow
            required property var modelData
            screen: modelData
            color: "transparent"
            implicitWidth: 500
            implicitHeight: 200

            anchors {
                top: true
                right: true
            }

            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "persona.clock"
            focusable: false

            Item {
                id: clockRoot
                anchors.fill: parent

                Item {
                    id: waveContainerOuter
                    z: 1
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.rightMargin: -clockScope.vw * 1.5625
                    width: clockScope.vw * 26.0417
                    height: clockScope.vw * 7.2917
                    clip: true

                    Repeater {
                        model: ["../Assets/img/wave1.png", "../Assets/img/wave2.png", "../Assets/img/wave3.png", "../Assets/img/wave4.png"]
                        delegate: Item {
                            id: wavePairDelegate
                            required property string modelData
                            required property int index
                            width: waveContainerOuter.width * 2
                            height: waveContainerOuter.height

                            Image {
                                source: wavePairDelegate.modelData
                                width: waveContainerOuter.width
                                height: waveContainerOuter.height
                                fillMode: Image.Stretch
                                x: 0
                            }
                            Image {
                                source: wavePairDelegate.modelData
                                width: waveContainerOuter.width
                                height: waveContainerOuter.height
                                fillMode: Image.Stretch
                                x: waveContainerOuter.width
                            }

                            NumberAnimation on x {
                                from: 0
                                to: -waveContainerOuter.width
                                duration: 10000
                                loops: Animation.Infinite
                                running: true
                            }
                        }
                    }
                }

                WaveTextLayer {
                    z: 5
                    waveSource: "../Assets/img/wave8.png"
                }

                Text {
                    id: timeText
                    z: 50
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.rightMargin: clockScope.vw * 12
                    anchors.topMargin: clockScope.vw * 0.2
                    text: Dat.Time.time
                    font.family: "Microsoft Yahei"
                    font.pixelSize: clockScope.vw * 6
                    font.weight: Font.Bold
                    font.letterSpacing: -clockScope.vw * 0.21
                    color: "#ffffff"
                    style: Text.Raised
                    styleColor: "#d11300b8"
                }

                Text {
                    id: weekdayText
                    z: 50
                    anchors.top: parent.top
                    anchors.topMargin: clockScope.vw * 3.5
                    anchors.right: parent.right
                    anchors.rightMargin: clockScope.vw * 9
                    width: clockScope.vw * 2
                    text: Dat.Time.weekday
                    horizontalAlignment: Text.AlignHCenter
                    font.family: "Bahnschrift Condensed"
                    font.pixelSize: clockScope.vw * 1.45
                    font.weight: Font.Normal
                    font.letterSpacing: -clockScope.vw * 0.1
                    color: "#ffffff"
                    style: Text.Outline
                    styleColor: "#0000ff"
                }

                Text {
                    id: phaseName
                    z: 50
                    anchors.top: parent.top
                    anchors.topMargin: clockScope.vw * 2
                    anchors.right: parent.right
                    anchors.rightMargin: clockScope.vw * 6
                    width: clockScope.vw * 5
                    text: Info.BatteryInfo.icon + " " + Info.BatteryInfo.percentageString
                    font.family: "JetBrainsMono Nerd Font"
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: clockScope.vw * 1.5
                    font.weight: Font.Bold
                    color: "#fffb9f"
                    style: Text.Raised
                    styleColor: "#635400d9"
                }

                Text {
                    id: daytimeText
                    z: 50
                    anchors.top: parent.top
                    anchors.topMargin: clockScope.vw * 5
                    anchors.right: parent.right
                    anchors.rightMargin: clockScope.vw * 6.5
                    width: clockScope.vw * 5.5
                    text: Dat.Time.daytime
                    horizontalAlignment: Text.AlignHCenter
                    font.family: "Microsoft Yahei"
                    font.pixelSize: clockScope.vw * 1.3
                    font.weight: Font.Bold
                    font.letterSpacing: -clockScope.vw * 0.1042
                    color: "#00dbff"
                    style: Text.Outline
                    styleColor: "#002c90"
                }

                Rectangle {
                    id: circle1
                    z: 60
                    anchors.top: parent.top
                    anchors.topMargin: clockScope.vw * 2.34375
                    anchors.right: parent.right
                    anchors.rightMargin: clockScope.vw * 2.0833
                    width: clockScope.vw * 4.1667
                    height: width
                    radius: width / 2
                    color: "#ffd200"
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: "#402b00"
                        shadowHorizontalOffset: clockScope.vw * 0.0521
                        shadowVerticalOffset: clockScope.vw * 0.0521
                        shadowBlur: clockScope.vw * 0.05
                    }
                }

                Rectangle {
                    id: circle2
                    z: 61
                    anchors.top: parent.top
                    anchors.topMargin: clockScope.vw * 2.4479
                    anchors.right: parent.right
                    anchors.rightMargin: clockScope.vw * 2.1875
                    width: clockScope.vw * 3.9583
                    height: width
                    radius: width / 2
                    color: "#ffe500"
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: "#fff72a"
                        shadowBlur: clockScope.vw * 0.3
                    }
                }

                Item {
                    id: moonSphere
                    z: 62
                    anchors.top: parent.top
                    anchors.topMargin: clockScope.vw * 2.4479
                    anchors.right: parent.right
                    anchors.rightMargin: clockScope.vw * 2.16
                    width: clockScope.vw * 3.958
                    height: width
                    clip: true

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        maskEnabled: true
                        maskSource: ShaderEffectSource {
                            sourceItem: Rectangle {
                                width: moonSphere.width
                                height: moonSphere.height
                                radius: moonSphere.width / 2
                                color: "white"
                            }
                        }
                        maskThresholdMin: 0.5
                        maskSpreadAtMin: 1.0
                    }

                    Rectangle {
                        width: parent.width / 2
                        height: parent.height
                        x: 0
                        color: Dat.Time.moonPhaseDegree < 180 ? "#ffe700" : "#302c24"
                    }
                    Rectangle {
                        width: parent.width / 2
                        height: parent.height
                        x: parent.width / 2
                        color: Dat.Time.moonPhaseDegree < 180 ? "#302c24" : "#ffe700"
                    }
                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width
                        height: parent.height
                        radius: width / 2
                        transform: Scale {
                            origin.x: moonSphere.width / 2
                            origin.y: moonSphere.height / 2
                            xScale: Math.cos(Dat.Time.moonPhaseDegree * Math.PI / 180)
                            yScale: 1
                        }
                        color: Math.cos(Dat.Time.moonPhaseDegree * Math.PI / 180) >= 0 ? "#302c24" : "#ffe700"
                    }
                }
            }
        }
    }

    component WaveTextLayer: Item {
        id: waveTextLayer
        required property string waveSource

        anchors.top: parent.top
        anchors.topMargin: -clockScope.vw * 0.5
        anchors.right: parent.right
        anchors.rightMargin: -clockScope.vw * 1.5625
        width: clockScope.vw * 26.0417
        height: clockScope.vw * 6.25
        clip: true

        Item {
            id: scrollingBg
            width: waveTextLayer.width * 2
            height: waveTextLayer.height

            Image {
                source: waveTextLayer.waveSource
                width: waveTextLayer.width
                height: waveTextLayer.height
                fillMode: Image.Stretch
                x: 0
            }
            Image {
                source: waveTextLayer.waveSource
                width: waveTextLayer.width
                height: waveTextLayer.height
                fillMode: Image.Stretch
                x: waveTextLayer.width
            }

            NumberAnimation on x {
                from: 0
                to: -waveTextLayer.width
                duration: 10000
                loops: Animation.Infinite
                running: true
            }
        }

        Text {
            id: textMask
            anchors.top: parent.top
            anchors.right: parent.right
            text: Dat.Time.date
            font.family: "Microsoft Yahei"
            font.pixelSize: clockScope.vw * 6.75
            font.weight: Font.Bold
            font.letterSpacing: -clockScope.vw * 0.75
            color: "white"
            visible: false
        }

        ShaderEffectSource {
            id: textMaskSource
            sourceItem: textMask
            hideSource: true
            visible: false
        }

        MultiEffect {
            source: scrollingBg
            anchors.fill: scrollingBg
            maskEnabled: true
            maskSource: textMaskSource
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0
        }
    }
}
