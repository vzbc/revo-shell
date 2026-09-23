import QtQuick
import Quickshell

FocusScope {
    id: root

    required property QtObject theme
    property alias text: searchInput.text
    property string placeholderText: "Search applications"

    signal moveRequested(int offset)
    signal submitRequested()
    signal cancelRequested()

    function focusInput() {
        searchInput.forceActiveFocus();
    }

    implicitHeight: theme.controlHeight + theme.shadowOffset
    activeFocusOnTab: true
    Accessible.role: Accessible.EditableText
    Accessible.name: placeholderText

    Rectangle {
        x: root.theme.space1
        y: root.theme.space1
        width: parent.width - root.theme.space1
        height: root.theme.controlHeight
        radius: root.theme.radiusControl
        color: root.theme.shadow
    }

    Rectangle {
        id: face

        width: parent.width - root.theme.space1
        height: root.theme.controlHeight
        radius: root.theme.radiusControl
        color: root.theme.surfaceRaised
        border.width: root.theme.borderWidth
        border.color: searchInput.activeFocus ? root.theme.focus : root.theme.ink

        Image {
            id: searchIcon

            anchors.left: parent.left
            anchors.leftMargin: root.theme.space3
            anchors.verticalCenter: parent.verticalCenter
            width: root.theme.iconSm
            height: root.theme.iconSm
            source: Quickshell.shellDir + "/assets/icons/search.svg"
            sourceSize.width: root.theme.iconSm
            sourceSize.height: root.theme.iconSm
            fillMode: Image.PreserveAspectFit
            mipmap: true
        }

        Text {
            anchors.left: searchIcon.right
            anchors.leftMargin: root.theme.space2
            anchors.right: parent.right
            anchors.rightMargin: root.theme.space3
            anchors.verticalCenter: parent.verticalCenter
            visible: searchInput.text.length === 0
            text: root.placeholderText
            color: root.theme.inkMuted
            font.family: root.theme.fontFamily
            font.pixelSize: root.theme.textSm
        }

        TextInput {
            id: searchInput

            anchors.left: searchIcon.right
            anchors.leftMargin: root.theme.space2
            anchors.right: parent.right
            anchors.rightMargin: root.theme.space3
            anchors.verticalCenter: parent.verticalCenter
            color: root.theme.ink
            selectionColor: root.theme.focus
            selectedTextColor: root.theme.ink
            font.family: root.theme.fontFamily
            font.pixelSize: root.theme.textSm
            clip: true
            activeFocusOnTab: true
            Keys.onDownPressed: (event) => {
                root.moveRequested(1);
                event.accepted = true;
            }
            Keys.onUpPressed: (event) => {
                root.moveRequested(-1);
                event.accepted = true;
            }
            Keys.onReturnPressed: (event) => {
                root.submitRequested();
                event.accepted = true;
            }
            Keys.onEnterPressed: (event) => {
                root.submitRequested();
                event.accepted = true;
            }
            Keys.onEscapePressed: (event) => {
                root.cancelRequested();
                event.accepted = true;
            }
        }

        TapHandler {
            onTapped: root.focusInput()
        }

    }

}
