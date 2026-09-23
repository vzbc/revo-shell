import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.win

/**
 * Windows 11 style settings numeric row with spin box.
 */
RowLayout {
    id: root
    property string text: ""
    property string icon
    property alias value: spinBoxWidget.value
    property alias stepSize: spinBoxWidget.stepSize
    property alias from: spinBoxWidget.from
    property alias to: spinBoxWidget.to
    spacing: 10
    Layout.leftMargin: 8
    Layout.rightMargin: 8

    RowLayout {
        spacing: 10
        Layout.alignment: Qt.AlignVCenter

        OptionalMaterialSymbol {
            icon: root.icon
            opacity: root.enabled ? 1 : 0.4
        }
        StyledText {
            id: labelWidget
            Layout.fillWidth: true
            text: root.text
            color: WinTheme.text
            opacity: root.enabled ? 1 : 0.4
            wrapMode: Text.WordWrap
        }
    }

    component WinSpinBox: Rectangle {
        id: spin
        property real value: 0
        property real stepSize: 1
        property real from: 0
        property real to: 100

        implicitHeight: 30
        implicitWidth: 92
        radius: 4
        color: "#333333"
        border.width: 1
        border.color: spinInput.activeFocus ? WinTheme.accent : WinTheme.border

        Behavior on border.color {
            ColorAnimation { duration: 120 }
        }

        function format(v) {
            return String(Math.round(v * 100) / 100);
        }
        function commit() {
            const parsed = parseFloat(spinInput.text);
            const next = isNaN(parsed) ? spin.value : parsed;
            spin.value = Math.max(spin.from, Math.min(spin.to, next));
            spinInput.text = spin.format(spin.value);
        }
        function step(direction) {
            spin.value = Math.max(spin.from, Math.min(spin.to, spin.value + direction * spin.stepSize));
            spinInput.text = spin.format(spin.value);
        }

        Component.onCompleted: spinInput.text = spin.format(spin.value)
        onValueChanged: {
            if (spinInput && !spinInput.activeFocus) spinInput.text = spin.format(spin.value);
        }

        RowLayout {
            anchors.fill: parent
            spacing: 0

            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 26
                color: downBtnArea.containsMouse ? WinTheme.cardHover : "transparent"
                radius: 4
                Behavior on color {
                    ColorAnimation { duration: 120 }
                }

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "remove"
                    iconSize: 16
                    color: WinTheme.text
                }
                MouseArea {
                    id: downBtnArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: spin.step(-1)
                }
            }

            TextInput {
                id: spinInput
                Layout.fillWidth: true
                Layout.fillHeight: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                color: WinTheme.text
                text: spin.format(spin.value)
                font.family: Appearance.font.family.numbers
                font.variableAxes: Appearance.font.variableAxes.numbers
                font.pixelSize: Appearance.font.pixelSize.small
                selectByMouse: true
                onAccepted: spin.commit()
                onEditingFinished: spin.commit()
                onActiveFocusChanged: {
                    if (!activeFocus) spin.commit();
                }
            }

            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 26
                color: upBtnArea.containsMouse ? WinTheme.cardHover : "transparent"
                radius: 4
                Behavior on color {
                    ColorAnimation { duration: 120 }
                }

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "add"
                    iconSize: 16
                    color: WinTheme.text
                }
                MouseArea {
                    id: upBtnArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: spin.step(1)
                }
            }
        }
    }

    WinSpinBox {
        id: spinBoxWidget
        Layout.alignment: Qt.AlignVCenter
        stepSize: root.stepSize
        from: root.from
        to: root.to
        opacity: root.enabled ? 1 : 0.4
    }
}
