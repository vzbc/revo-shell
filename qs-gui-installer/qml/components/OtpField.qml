// OtpField.qml — password boxes that grow with the typed password (1 box per char)
import QtQuick
import QtQuick.Controls

Item {
    id: root

    property int length: 1
    property int minSlots: 1
    property int maxLength: 64
    property string value: ""
    property string fontFamily: "SF Pro Display"
    property color slotBg: "#0A0A0A"
    property color slotBorder: "#2C2C2E"
    property color slotActiveBorder: "#FFFFFF"
    property color slotText: "#FFFFFF"
    property bool secret: true

    signal submitted(string value)
    signal completed(string value)

    // Mirror of Stage4.passwordReady — true once any character is typed.
    property bool passwordReady: false

    readonly property int slotSize: 44
    readonly property int slotGap: 8
    // Grow exactly with password length: "123" → 3 boxes (min 1 when empty).
    // No extra caret slot — count matches typed characters only.
    readonly property int slotCount: {
        var n = input.text.length
        return Math.max(minSlots, n, 1)
    }
    readonly property int totalW: slotCount * slotSize + (slotCount - 1) * slotGap

    implicitWidth: totalW
    implicitHeight: slotSize
    width: totalW
    height: slotSize

    TextInput {
        id: input
        anchors.fill: parent
        opacity: 0
        focus: true
        activeFocusOnTab: true
        enabled: root.enabled
        echoMode: root.secret ? TextInput.Password : TextInput.Normal
        passwordMaskDelay: 0
        passwordCharacter: "•"
        maximumLength: root.maxLength
        font.family: root.fontFamily
        font.pixelSize: 18
        // Full Linux password charset (no digit-only limit)
        validator: RegularExpressionValidator {
            regularExpression: /[^\n]{0,64}/
        }
        onTextChanged: {
            root.value = text
            root.passwordReady = text.length >= 1
            if (text.length >= root.minSlots && text.length > 0)
                root.completed(text)
        }
        Keys.onReturnPressed: root.submitted(text)
        Keys.onEnterPressed: root.submitted(text)
        Keys.onEscapePressed: {
            // Keep typed password; just drop focus so buttons can be clicked.
            input.focus = false
        }
    }

    Row {
        anchors.centerIn: parent
        spacing: root.slotGap

        Repeater {
            model: root.slotCount

            delegate: Rectangle {
                id: slot
                required property int index

                width: root.slotSize
                height: root.slotSize
                radius: 10
                color: root.slotBg
                border.width: (input.activeFocus && (
                    input.cursorPosition === index ||
                    (input.cursorPosition >= input.text.length && index === Math.min(input.text.length, root.slotCount - 1))
                )) ? 2 : 1
                border.color: {
                    if (input.activeFocus && (
                        input.cursorPosition === index ||
                        (input.cursorPosition >= input.text.length && index === Math.min(input.text.length, root.slotCount - 1))
                    ))
                        return root.slotActiveBorder
                    if (index < input.text.length)
                        return "#A1A1A1"
                    return root.slotBorder
                }

                Behavior on border.color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: {
                        if (index >= input.text.length)
                            return ""
                        if (!root.secret)
                            return input.text.charAt(index)
                        return "•"
                    }
                    font.family: root.fontFamily
                    font.pixelSize: 20
                    font.weight: Font.DemiBold
                    color: root.slotText
                }

                Rectangle {
                    // Caret sits inside the current slot (or last slot when at end)
                    visible: input.activeFocus && root.visible && (
                        input.cursorPosition === index ||
                        (input.cursorPosition >= input.text.length && index === input.text.length)
                    )
                    width: 2
                    height: 20
                    radius: 1
                    color: "#FFFFFF"
                    anchors.centerIn: parent

                    SequentialAnimation on opacity {
                        running: input.activeFocus && root.visible
                        loops: Animation.Infinite
                        NumberAnimation { to: 0; duration: 500 }
                        NumberAnimation { to: 1; duration: 500 }
                    }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.IBeamCursor
        // Steal focus from the Install button so typing always lands in the field.
        onPressed: input.forceActiveFocus()
        onClicked: input.forceActiveFocus()
    }

    function forceFocus() {
        input.forceActiveFocus()
    }

    function clear() {
        input.text = ""
        root.value = ""
        root.passwordReady = false
    }

    // Re-assert focus whenever this control becomes enabled/visible again
    // (e.g. after Install button click tried to move focus away).
    onEnabledChanged: {
        if (enabled)
            Qt.callLater(forceFocus)
    }

    Component.onCompleted: Qt.callLater(forceFocus)

    onVisibleChanged: {
        if (visible)
            Qt.callLater(forceFocus)
    }
}
