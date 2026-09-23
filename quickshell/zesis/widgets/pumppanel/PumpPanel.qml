pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../"

PanelWindow {
    id: root

    readonly property int panelW: Math.round(320 * UIScale.value)
    readonly property int triggerW: Math.round(14 * UIScale.value)

    property real pressure: 0.0
    property bool locked: false

    WlrLayershell.namespace: "zesis:pumpPanel"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    exclusiveZone: -1
    color: "transparent"

    anchors {
        left: true
        top: true
        bottom: true
    }

    implicitWidth: panelW

    mask: Region {
        x: 0
        y: 0
        width: root.triggerW + (root.panelW - root.triggerW) * root.pressure
        height: 4096
    }

    Timer {
        interval: 16
        running: !root.locked && root.pressure > 0
        repeat: true
        onTriggered: root.pressure = Math.max(0.0, root.pressure - 0.005)
    }

    QtObject {
        id: pump
        property real lastY: 0.0
        property int lastDir: 0  // -1 up, +1 down, 0 unknown
        property bool dragging: false
    }

    Item {
        anchors.fill: parent
        clip: true

        Rectangle {
            id: panel
            width: root.panelW
            height: parent.height
            x: -(root.panelW - root.triggerW) * (1.0 - root.pressure)

            color: Colors.bg
            border.color: Colors.outline
            border.width: 1

            // Pressure fill, left edge bar, grows bottom to top
            Rectangle {
                anchors.left: parent.left
                anchors.leftMargin: 1
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 1
                width: Math.round(3 * UIScale.value)
                height: (parent.height - 2) * root.pressure
                color: Colors.accent
                opacity: root.locked ? 0.0 : 1.0
                Behavior on opacity {
                    NumberAnimation {
                        duration: 200
                    }
                }
            }

            // Trigger strip, right edge, sits at screen left when panel is retracted
            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: 1
                anchors.top: parent.top
                anchors.topMargin: 1
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 1
                width: root.triggerW - 2
                color: pump.dragging ? Colors.withAlpha(Colors.accent, 0.15) : Colors.withAlpha(Colors.text, 0.05)
                radius: UIScale.radiusSm

                Behavior on color {
                    ColorAnimation {
                        duration: 80
                    }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: Math.round(5 * UIScale.value)
                    Repeater {
                        model: 5
                        Rectangle {
                            width: Math.round(3 * UIScale.value)
                            height: Math.round(3 * UIScale.value)
                            radius: width / 2
                            color: pump.dragging ? Colors.withAlpha(Colors.accent, 0.8) : Colors.withAlpha(Colors.text, 0.25)
                            Behavior on color {
                                ColorAnimation {
                                    duration: 80
                                }
                            }
                        }
                    }
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: UIScale.spacingMd

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.locked ? "OPEN" : Math.round(root.pressure * 100) + "%"
                    color: root.locked ? Colors.accent : Colors.text
                    font.pixelSize: UIScale.fontHero
                    font.letterSpacing: 2
                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                        }
                    }
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Math.round(90 * UIScale.value)
                    height: Math.round(32 * UIScale.value)
                    radius: UIScale.radiusMd
                    color: closeMa.containsMouse ? Colors.withAlpha(Colors.text, 0.12) : Colors.withAlpha(Colors.text, 0.06)
                    border.color: Colors.withAlpha(Colors.text, 0.10)
                    border.width: 1
                    opacity: root.locked ? 1.0 : 0.0
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 200
                        }
                    }
                    Behavior on color {
                        ColorAnimation {
                            duration: 80
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: I18n.t("pumppanel.deflate")
                        color: Colors.textDim
                        font.pixelSize: UIScale.fontCaption
                        font.letterSpacing: 1
                    }

                    MouseArea {
                        id: closeMa
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: root.locked
                        onClicked: root.locked = false
                    }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            preventStealing: true
            enabled: !root.locked

            onPressed: mouse => {
                pump.lastY = mouse.y;
                pump.lastDir = 0;
                pump.dragging = true;
            }
            onReleased: {
                pump.dragging = false;
            }
            onPositionChanged: mouse => {
                if (!pump.dragging)
                    return;
                const dy = mouse.y - pump.lastY;
                if (Math.abs(dy) < 15)
                    return;
                const dir = dy > 0 ? 1 : -1;
                if (pump.lastDir !== 0 && dir !== pump.lastDir) {
                    root.pressure = Math.min(1.0, root.pressure + 0.20);
                    if (root.pressure >= 1.0)
                        root.locked = true;
                }
                pump.lastDir = dir;
                pump.lastY = mouse.y;
            }
        }
    }
}
