pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../"

PanelWindow {
    id: root

    readonly property int wheelRadius: Math.round(220 * UIScale.value)

    WlrLayershell.namespace: "zesis:wheelTest"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusiveZone: -1
    color: "transparent"

    anchors {
        top: true
        right: true
    }
    implicitWidth: wheelRadius
    implicitHeight: wheelRadius

    mask: Region {
        shape: RegionShape.Ellipse
        x: 0
        y: -root.wheelRadius
        width: root.wheelRadius * 2
        height: root.wheelRadius * 2
    }

    readonly property real cx: root.wheelRadius
    readonly property real cy: 0.0
    readonly property real focalAngle: 135.0
    readonly property real itemSpacingDeg: 13.0

    // Pill padding, drives item size and background rect
    readonly property real pillH: Math.round(8 * UIScale.value)
    readonly property real pillV: Math.round(4 * UIScale.value)

    readonly property var widgetItems: [
        {
            label: "Tray",
            icon: "󱒔"
        },
        {
            label: "SysMon",
            icon: "󰻠"
        },
        {
            label: "Theme",
            icon: "󰔎"
        },
        {
            label: "Keybinds",
            icon: "󰌌"
        },
        {
            label: "Bluetooth",
            icon: "󰂯"
        },
        {
            label: "AirPods",
            icon: "󰋋"
        },
        {
            label: "Wi-Fi",
            icon: "󰤨"
        },
        {
            label: "Weather",
            icon: "󰖕"
        },
        {
            label: "Brightness",
            icon: "󰃟"
        },
        {
            label: "Sound",
            icon: "󰕾"
        },
        {
            label: "Mic",
            icon: "󰍬"
        },
        {
            label: "Notifs",
            icon: "󰂚"
        },
        {
            label: "Config",
            icon: "󰒓"
        },
        {
            label: "Battery",
            icon: "󰁹"
        },
        {
            label: "Record",
            icon: "󰑊"
        },
        {
            label: "Home",
            icon: ""
        },
        {
            label: "Lock",
            icon: "󰌾"
        },
        {
            label: "Clock",
            icon: "󰥔"
        },
    ]

    readonly property real centerIdx: (widgetItems.length - 1) / 2.0
    property int selectedIndex: Math.floor(widgetItems.length / 2)
    property real angleOffset: 0.0

    readonly property int visualSelectedIndex: {
        const v = Math.round(root.centerIdx - root.angleOffset / root.itemSpacingDeg);
        return Math.max(0, Math.min(root.widgetItems.length - 1, v));
    }

    NumberAnimation {
        id: selectAnim
        target: root
        property: "angleOffset"
        duration: 200
        easing.type: Easing.OutCubic
    }

    QtObject {
        id: drag
        property bool active: false
        property real lastAngle: 0.0
    }

    function angleAt(mx, my) {
        return Math.atan2(my - root.cy, mx - root.cx) * 180.0 / Math.PI;
    }

    function snapToNearest() {
        const v = Math.round(root.centerIdx - root.angleOffset / root.itemSpacingDeg);
        const snapped = Math.max(0, Math.min(root.widgetItems.length - 1, v));
        root.selectedIndex = snapped;
        selectAnim.stop();
        selectAnim.to = -(snapped - root.centerIdx) * root.itemSpacingDeg;
        selectAnim.start();
    }

    function selectAt(idx) {
        const clamped = Math.max(0, Math.min(root.widgetItems.length - 1, idx));
        root.selectedIndex = clamped;
        selectAnim.stop();
        selectAnim.to = -(clamped - root.centerIdx) * root.itemSpacingDeg;
        selectAnim.start();
    }

    Item {
        anchors.fill: parent

        Repeater {
            model: root.widgetItems
            delegate: Item {
                id: del
                required property var modelData
                required property int index

                readonly property real angleDeg: root.focalAngle + (del.index - root.centerIdx) * root.itemSpacingDeg + root.angleOffset

                readonly property real rad: del.angleDeg * Math.PI / 180.0
                readonly property real px: root.cx + root.wheelRadius * Math.cos(del.rad)
                readonly property real py: root.cy + root.wheelRadius * Math.sin(del.rad)

                readonly property real distDeg: {
                    var d = del.angleDeg - root.focalAngle;
                    while (d > 180)
                        d -= 360;
                    while (d < -180)
                        d += 360;
                    return Math.abs(d);
                }

                // Full fade over +-3 slots
                readonly property real proximity: Math.max(0.0, 1.0 - del.distDeg / (root.itemSpacingDeg * 3.0))
                readonly property bool isSelected: del.index === root.visualSelectedIndex

                // Size includes pill padding
                width: row.implicitWidth + root.pillH * 2
                height: row.implicitHeight + root.pillV * 2

                x: del.px - width / 2
                y: del.py - height / 2

                visible: del.proximity > 0 && del.px > -80 && del.px < root.width + 80 && del.py > -80 && del.py < root.height + 80

                scale: del.isSelected ? 1.22 : 1.0
                Behavior on scale {
                    NumberAnimation {
                        duration: 160
                        easing.type: Easing.OutCubic
                    }
                }

                // Background pill
                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: del.isSelected ? Qt.tint(Colors.bg, Colors.withAlpha(Colors.accent, 0.35)) : Colors.bg
                    border.color: del.isSelected ? Colors.withAlpha(Colors.accent, 0.60) : Colors.outline
                    border.width: 1
                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }
                    Behavior on border.color {
                        ColorAnimation {
                            duration: 150
                        }
                    }
                }

                Row {
                    id: row
                    anchors.centerIn: parent
                    spacing: Math.round(5 * UIScale.value)
                    opacity: del.proximity

                    Text {
                        text: del.modelData.icon
                        font.pixelSize: UIScale.fontBody
                        color: del.isSelected ? Colors.accent : Colors.text
                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }
                        }
                    }

                    Text {
                        text: del.modelData.label
                        font.pixelSize: UIScale.fontSmall
                        color: del.isSelected ? Colors.accent : Colors.textDim
                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }
                        }
                    }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            preventStealing: true

            onPressed: mouse => {
                selectAnim.stop();
                drag.lastAngle = root.angleAt(mouse.x, mouse.y);
                drag.active = true;
            }

            onPositionChanged: mouse => {
                if (!drag.active)
                    return;
                var a = root.angleAt(mouse.x, mouse.y);
                var delta = a - drag.lastAngle;
                if (delta > 180)
                    delta -= 360;
                if (delta < -180)
                    delta += 360;
                root.angleOffset += delta;
                drag.lastAngle = a;
            }

            onReleased: {
                drag.active = false;
                root.snapToNearest();
            }

            onWheel: wheel => {
                root.selectAt(root.visualSelectedIndex + (wheel.angleDelta.y > 0 ? 1 : -1));
            }
        }
    }
}
