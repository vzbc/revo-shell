import QtQuick
import QtQuick.Layouts
import "../../"

Rectangle {
    id: root

    property string placeholder: ""
    property string icon: ""
    property bool showClearButton: false
    property alias text: field.text
    property alias echoMode: field.echoMode
    property alias field: field

    signal accepted
    signal tabPressed
    signal escapePressed

    Layout.fillWidth: true
    implicitHeight: Math.round(32 * UIScale.value)
    radius: UIScale.radiusSm
    color: field.activeFocus ? Colors.withAlpha(Colors.accent, 0.08) : Colors.withAlpha(Colors.text, 0.04)
    border.color: field.activeFocus ? Colors.withAlpha(Colors.accent, 0.4) : Colors.withAlpha(Colors.text, 0.06)
    border.width: 1
    Behavior on color {
        ColorAnimation {
            duration: Anim.fast
        }
    }
    Behavior on border.color {
        ColorAnimation {
            duration: Anim.fast
        }
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: field.forceActiveFocus()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: UIScale.spacingSm
        anchors.rightMargin: UIScale.spacingSm
        spacing: Math.round(7 * UIScale.value)

        Text {
            visible: root.icon.length > 0
            text: root.icon
            font.family: "Material Icons"
            font.pixelSize: UIScale.fontLead
            color: field.activeFocus ? Colors.accent : Colors.muted
            Behavior on color {
                ColorAnimation {
                    duration: Anim.fast
                }
            }
        }

        Item {
            Layout.fillWidth: true
            implicitHeight: Math.round(20 * UIScale.value)

            Text {
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                visible: field.text.length === 0 && root.placeholder.length > 0
                text: root.placeholder
                color: Colors.muted
                font.pixelSize: UIScale.fontBody
            }

            TextInput {
                id: field
                anchors.fill: parent
                verticalAlignment: TextInput.AlignVCenter
                color: Colors.text
                selectionColor: Colors.withAlpha(Colors.accent, 0.35)
                font.pixelSize: UIScale.fontBody
                clip: true
                Keys.onReturnPressed: root.accepted()
                Keys.onTabPressed: root.tabPressed()
                Keys.onEscapePressed: {
                    if (field.text.length > 0) {
                        field.text = "";
                    } else {
                        field.focus = false;
                        root.escapePressed();
                    }
                }
            }
        }

        Text {
            visible: root.showClearButton && field.text.length > 0
            text: "✕"
            font.pixelSize: UIScale.fontCaption
            color: Colors.muted

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: field.text = ""
            }
        }
    }
}
