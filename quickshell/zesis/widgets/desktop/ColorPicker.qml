pragma ComponentBehavior: Bound

import QtQuick
import "../../"

Item {
    id: root

    property color selectedColor: Qt.hsva(root._hue, root._sat, root._val, root._alpha)

    function setFromColor(c) {
        root._val = c.hsvValue;
        root._sat = c.hsvSaturation;
        root._alpha = c.a;
        var h = c.hsvHue;
        if (h >= 0)
            root._hue = h;
    }

    property real _hue: 0.0
    property real _sat: 1.0
    property real _val: 1.0
    property real _alpha: 1.0

    readonly property color _pureHue: Qt.hsva(root._hue, 1.0, 1.0, 1.0)

    readonly property real _svH: Math.round(130 * UIScale.value)
    readonly property real _stripH: Math.round(12 * UIScale.value)
    readonly property real _bottomH: Math.round(24 * UIScale.value)
    readonly property real _cursorD: Math.round(14 * UIScale.value)
    readonly property real _gap: Math.round(UIScale.spacingXs)

    implicitWidth: Math.round(200 * UIScale.value)
    implicitHeight: _svH + _gap + _stripH + _gap + _stripH + _gap + _bottomH

    // SV gradient square
    Rectangle {
        id: svRect
        width: root.implicitWidth
        height: root._svH
        color: "black"
        radius: UIScale.radiusSm
        layer.enabled: true

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop {
                    position: 0.0
                    color: "white"
                }
                GradientStop {
                    position: 1.0
                    color: root._pureHue
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop {
                    position: 0.0
                    color: "transparent"
                }
                GradientStop {
                    position: 1.0
                    color: "black"
                }
            }
        }

        Rectangle {
            width: root._cursorD
            height: root._cursorD
            radius: root._cursorD / 2
            x: root._sat * (svRect.width - root._cursorD)
            y: (1.0 - root._val) * (svRect.height - root._cursorD)
            color: root.selectedColor
            border.color: "white"
            border.width: Math.max(1, Math.round(2 * UIScale.value))
        }

        MouseArea {
            anchors.fill: parent
            function _set(mx, my) {
                root._sat = Math.max(0.0, Math.min(1.0, mx / svRect.width));
                root._val = Math.max(0.0, Math.min(1.0, 1.0 - my / svRect.height));
            }
            onPressed: _set(mouseX, mouseY)
            onPositionChanged: if (pressed)
                _set(mouseX, mouseY)
        }
    }

    // Hue strip
    Rectangle {
        id: hueRect
        y: root._svH + root._gap
        width: root.implicitWidth
        height: root._stripH
        radius: root._stripH / 2
        layer.enabled: true

        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop {
                position: 0.000
                color: "#FF0000"
            }
            GradientStop {
                position: 0.167
                color: "#FFFF00"
            }
            GradientStop {
                position: 0.333
                color: "#00FF00"
            }
            GradientStop {
                position: 0.500
                color: "#00FFFF"
            }
            GradientStop {
                position: 0.667
                color: "#0000FF"
            }
            GradientStop {
                position: 0.833
                color: "#FF00FF"
            }
            GradientStop {
                position: 1.000
                color: "#FF0000"
            }
        }

        Rectangle {
            width: Math.max(2, Math.round(4 * UIScale.value))
            height: parent.height
            radius: width / 2
            x: root._hue * (hueRect.width - width)
            color: "transparent"
            border.color: "white"
            border.width: Math.max(1, Math.round(2 * UIScale.value))
        }

        MouseArea {
            anchors.fill: parent
            function _set(mx) {
                root._hue = Math.max(0.0, Math.min(1.0, mx / hueRect.width));
            }
            onPressed: _set(mouseX)
            onPositionChanged: if (pressed)
                _set(mouseX)
        }
    }

    // Alpha strip, grey pill behind so transparency reads correctly
    Rectangle {
        y: root._svH + root._gap + root._stripH + root._gap
        width: root.implicitWidth
        height: root._stripH
        radius: root._stripH / 2
        color: "#555555"
    }

    Rectangle {
        id: alphaRect
        y: root._svH + root._gap + root._stripH + root._gap
        width: root.implicitWidth
        height: root._stripH
        radius: root._stripH / 2
        layer.enabled: true

        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop {
                position: 0.0
                color: Qt.hsva(root._hue, root._sat, root._val, 0.0)
            }
            GradientStop {
                position: 1.0
                color: Qt.hsva(root._hue, root._sat, root._val, 1.0)
            }
        }

        Rectangle {
            width: Math.max(2, Math.round(4 * UIScale.value))
            height: parent.height
            radius: width / 2
            x: root._alpha * (alphaRect.width - width)
            color: "transparent"
            border.color: "white"
            border.width: Math.max(1, Math.round(2 * UIScale.value))
        }

        MouseArea {
            anchors.fill: parent
            function _set(mx) {
                root._alpha = Math.max(0.0, Math.min(1.0, mx / alphaRect.width));
            }
            onPressed: _set(mouseX)
            onPositionChanged: if (pressed)
                _set(mouseX)
        }
    }

    // Swatch + hex input
    Row {
        y: root._svH + root._gap + root._stripH + root._gap + root._stripH + root._gap
        spacing: root._gap

        // Grey backing shows through for semi-transparent colors
        Rectangle {
            width: root._bottomH
            height: root._bottomH
            radius: UIScale.radiusSm
            color: "#555555"
            layer.enabled: true

            Rectangle {
                anchors.fill: parent
                color: root.selectedColor
            }

            Rectangle {
                anchors.fill: parent
                color: "transparent"
                border.color: Colors.withAlpha(Colors.outline, 0.5)
                border.width: 1
            }
        }

        Rectangle {
            width: root.implicitWidth - root._bottomH - root._gap
            height: root._bottomH
            radius: UIScale.radiusSm
            color: Colors.withAlpha(Colors.outline, 0.2)
            clip: true

            TextInput {
                id: hexInput
                anchors {
                    fill: parent
                    margins: Math.round(UIScale.spacingXs)
                }
                text: root.selectedColor.toString().toUpperCase()
                color: Colors.text
                font.pixelSize: UIScale.fontSmall
                selectByMouse: true
                verticalAlignment: TextInput.AlignVCenter

                property bool _userEditing: false

                onTextEdited: _userEditing = true
                onEditingFinished: {
                    if (_userEditing) {
                        var c = Qt.color(text);
                        if (c.valid)
                            root.setFromColor(c);
                        _userEditing = false;
                    }
                }

                Connections {
                    target: root
                    function onSelectedColorChanged() {
                        if (!hexInput._userEditing)
                            hexInput.text = root.selectedColor.toString().toUpperCase();
                    }
                }
            }
        }
    }
}
