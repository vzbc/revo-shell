import QtQuick
import qs.config

// Inset pill-shaped single-line text input with a placeholder.
Item {
    id: root

    property alias text: input.text
    property alias input: input
    property string placeholder: ""
    property alias echoMode: input.echoMode

    signal accepted()
    signal upPressed()
    signal downPressed()

    function focusInput() {
        input.forceActiveFocus()
    }

    implicitWidth: 160
    implicitHeight: 28

    Bevel {
        anchors.fill: parent
        radius: height / 2
        sunken: true
        faceColor: Theme.field
    }

    TextInput {
        id: input

        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        verticalAlignment: TextInput.AlignVCenter
        clip: true
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
        color: Theme.text
        selectionColor: Theme.selection
        selectedTextColor: Theme.selectionText
        onAccepted: root.accepted()
        Keys.onUpPressed: root.upPressed()
        Keys.onDownPressed: root.downPressed()
        Keys.onTabPressed: root.downPressed()
        Keys.onBacktabPressed: root.upPressed()

        cursorDelegate: Rectangle {
            width: 2
            radius: 1
            color: Theme.selection
            visible: input.activeFocus

            SequentialAnimation on opacity {
                running: input.activeFocus
                loops: Animation.Infinite
                PropertyAction { value: 1 }
                PauseAnimation { duration: 530 }
                PropertyAction { value: 0 }
                PauseAnimation { duration: 530 }
            }
        }
    }

    BarText {
        anchors.fill: input
        verticalAlignment: Text.AlignVCenter
        visible: input.text === ""
        text: root.placeholder
        color: Theme.textMuted
    }
}
