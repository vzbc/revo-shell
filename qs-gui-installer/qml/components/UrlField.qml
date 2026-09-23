// UrlField.qml — single-line repo URL input (stage 2)
import QtQuick
import QtQuick.Controls

Rectangle {
    id: root

    property alias text: input.text
    property alias placeholder: placeholderLabel.text
    property string fontFamily: "SF Pro Display"
    property color bg: "#0A0A0A"
    property color borderIdle: "#2C2C2E"
    property color borderActive: "#FFFFFF"
    property color textColor: "#FFFFFF"
    property color placeholderColor: "#6E6E73"

    signal accepted()

    height: 52
    width: 480
    radius: 14
    color: bg
    border.width: input.activeFocus ? 2 : 1
    border.color: input.activeFocus ? borderActive : borderIdle

    Behavior on border.color { ColorAnimation { duration: 160 } }

    TextInput {
        id: input
        anchors.fill: parent
        anchors.leftMargin: 18
        anchors.rightMargin: 18
        verticalAlignment: TextInput.AlignVCenter
        font.family: root.fontFamily
        font.pixelSize: 15
        color: root.textColor
        clip: true
        selectionColor: "#33FFFFFF"
        selectedTextColor: "#FFFFFF"
        focus: true
        onAccepted: root.accepted()
    }

    Text {
        id: placeholderLabel
        anchors.left: parent.left
        anchors.leftMargin: 18
        anchors.verticalCenter: parent.verticalCenter
        text: "https://github.com/you/quickshell-dotfiles"
        font.family: root.fontFamily
        font.pixelSize: 15
        color: root.placeholderColor
        visible: input.text.length === 0
        opacity: visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 140 } }
    }

    // lock icon hint
    Text {
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        text: "⌥"
        font.family: root.fontFamily
        font.pixelSize: 14
        color: root.placeholderColor
        visible: input.text.length === 0
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.IBeamCursor
        onClicked: input.forceActiveFocus()
    }

    function forceFocus() {
        input.forceActiveFocus()
    }

    onVisibleChanged: if (visible) Qt.callLater(forceFocus)
}
