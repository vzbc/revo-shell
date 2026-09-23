import QtQuick
import QtQuick.Layouts
import "../../"

// HSV color picker: saturation/value field, hue strip and a hex field.
ColumnLayout {
    id: root

    // Color being edited, as "#rrggbb". Driven from outside - the picker never
    // assigns to it, so the binding survives and an external reset re-syncs the
    // handles.
    property string value: "#000000"

    // Emitted continuously while dragging, so callers can show a live preview.
    // Debounce before persisting.
    signal picked(string hex)

    readonly property bool _dragging: svArea.pressed || hueArea.pressed

    property real _hue: 0
    property real _sat: 0
    property real _val: 0

    spacing: UIScale.spacingSm

    // Incoming value only drives the handles when the user isn't holding one,
    // otherwise the round trip through the caller would fight the drag.
    onValueChanged: if (!root._dragging)
        root._sync()
    Component.onCompleted: root._sync()

    function _sync() {
        if (!/^#[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/.test(root.value))
            return;
        var c = Qt.color(root.value);
        // Greys report hue -1; keep whatever the strip was on so the handle
        // doesn't jump to red when the user drags saturation to zero.
        if (c.hsvHue >= 0)
            root._hue = c.hsvHue;
        root._sat = c.hsvSaturation;
        root._val = c.hsvValue;
    }

    function _hex(h, s, v) {
        var c = Qt.hsva(h, s, v, 1);
        return "#" + root._byte(c.r) + root._byte(c.g) + root._byte(c.b);
    }

    function _byte(f) {
        var s = Math.round(f * 255).toString(16);
        return s.length < 2 ? "0" + s : s;
    }

    function _emit() {
        root.picked(root._hex(root._hue, root._sat, root._val));
    }

    // Saturation (x) / value (y) field, tinted by the current hue.
    Rectangle {
        id: svField
        Layout.fillWidth: true
        implicitHeight: Math.round(110 * UIScale.value)
        radius: UIScale.radiusSm
        clip: true
        color: Qt.hsva(root._hue, 1, 1, 1)

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop {
                    position: 0.0
                    color: "#ffffffff"
                }
                GradientStop {
                    position: 1.0
                    color: "#00ffffff"
                }
            }
        }
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: "#00000000"
                }
                GradientStop {
                    position: 1.0
                    color: "#ff000000"
                }
            }
        }

        Rectangle {
            id: svHandle
            width: Math.round(14 * UIScale.value)
            height: width
            radius: width / 2
            x: root._sat * svField.width - width / 2
            y: (1 - root._val) * svField.height - height / 2
            color: "transparent"
            border.color: "#ffffff"
            border.width: 2

            Rectangle {
                anchors.fill: parent
                anchors.margins: 2
                radius: width / 2
                color: "transparent"
                border.color: "#66000000"
                border.width: 1
            }
        }

        MouseArea {
            id: svArea
            anchors.fill: parent
            preventStealing: true
            cursorShape: Qt.CrossCursor
            onPressed: function (m) {
                root._setSV(m.x, m.y);
            }
            onPositionChanged: function (m) {
                if (pressed)
                    root._setSV(m.x, m.y);
            }
        }
    }

    function _setSV(x, y) {
        root._sat = Math.max(0, Math.min(1, x / svField.width));
        root._val = Math.max(0, Math.min(1, 1 - y / svField.height));
        root._emit();
    }

    // Hue strip
    Rectangle {
        id: hueStrip
        Layout.fillWidth: true
        implicitHeight: Math.round(16 * UIScale.value)
        radius: UIScale.radiusSm
        clip: true
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop {
                position: 0.000
                color: "#ff0000"
            }
            GradientStop {
                position: 0.167
                color: "#ffff00"
            }
            GradientStop {
                position: 0.333
                color: "#00ff00"
            }
            GradientStop {
                position: 0.500
                color: "#00ffff"
            }
            GradientStop {
                position: 0.667
                color: "#0000ff"
            }
            GradientStop {
                position: 0.833
                color: "#ff00ff"
            }
            GradientStop {
                position: 1.000
                color: "#ff0000"
            }
        }

        Rectangle {
            width: Math.round(5 * UIScale.value)
            height: hueStrip.height
            radius: 2
            x: root._hue * (hueStrip.width - width)
            color: "#ffffff"
            border.color: "#66000000"
            border.width: 1
        }

        MouseArea {
            id: hueArea
            anchors.fill: parent
            preventStealing: true
            cursorShape: Qt.SizeHorCursor
            onPressed: function (m) {
                root._setHue(m.x);
            }
            onPositionChanged: function (m) {
                if (pressed)
                    root._setHue(m.x);
            }
        }
    }

    function _setHue(x) {
        root._hue = Math.max(0, Math.min(0.9999, x / hueStrip.width));
        root._emit();
    }

    // Hex entry, mirroring the handles until the user types into it.
    RowLayout {
        Layout.fillWidth: true
        spacing: UIScale.spacingSm

        Rectangle {
            implicitWidth: Math.round(32 * UIScale.value)
            implicitHeight: Math.round(32 * UIScale.value)
            radius: UIScale.radiusSm
            color: Qt.hsva(root._hue, root._sat, root._val, 1)
            border.color: Colors.withAlpha(Colors.text, 0.15)
            border.width: 1
        }

        StyledTextInput {
            id: hexField
            Layout.fillWidth: true
            placeholder: "#rrggbb"
            text: root._hex(root._hue, root._sat, root._val)
            onAccepted: {
                var t = hexField.text.trim();
                if (/^#[0-9a-fA-F]{6}$/.test(t))
                    root.picked(t.toLowerCase());
                // Typing broke the binding above, put it back either way so the
                // field keeps following the handles.
                hexField.text = Qt.binding(function () {
                    return root._hex(root._hue, root._sat, root._val);
                });
            }
        }
    }
}
