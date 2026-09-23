import "../components" as Ui
import QtQuick
import QtQuick.Layouts
import Quickshell

FocusScope {
    id: root

    required property QtObject theme
    required property QtObject sessionService
    property int currentIndex: 0
    property int confirmIndex: 1
    property string pendingAction: ""
    readonly property var actions: [{
        "action": "suspend",
        "label": "Suspend",
        "status": "Sleep",
        "question": "Suspend this session?",
        "icon": Quickshell.shellDir + "/assets/icons/suspend.svg",
        "accent": theme.blue
    }, {
        "action": "logout",
        "label": "Logout",
        "status": "End session",
        "question": "Log out of Hyprland?",
        "icon": Quickshell.shellDir + "/assets/icons/logout.svg",
        "accent": theme.lilac
    }, {
        "action": "restart",
        "label": "Reboot",
        "status": "Restart system",
        "question": "Reboot the computer?",
        "icon": Quickshell.shellDir + "/assets/icons/restart.svg",
        "accent": theme.gold
    }, {
        "action": "poweroff",
        "label": "Shutdown",
        "status": "Power off",
        "question": "Shut down the computer?",
        "icon": Quickshell.shellDir + "/assets/icons/power.svg",
        "accent": theme.coral
    }]
    readonly property var pendingEntry: actions.find((entry) => {
        return entry.action === pendingAction;
    })

    signal closeRequested()

    function open() {
        resetTransientState();
        forceActiveFocus();
    }

    function resetTransientState() {
        currentIndex = 0;
        confirmIndex = 1;
        pendingAction = "";
    }

    function moveSelection(delta) {
        const count = actions.length;
        currentIndex = (currentIndex + delta + count) % count;
    }

    function requestAction(index) {
        currentIndex = index;
        pendingAction = actions[index].action;
        confirmIndex = 1;
        forceActiveFocus();
    }

    function cancelConfirmation() {
        pendingAction = "";
        confirmIndex = 1;
        forceActiveFocus();
    }

    function confirmAction() {
        if (pendingAction.length === 0)
            return ;

        const action = pendingAction;
        closeRequested();
        sessionService.runAction(action);
    }

    implicitWidth: theme.sessionMenuWidth
    implicitHeight: menuColumn.implicitHeight + theme.space4 * 2 + theme.shadowOffset
    focus: true
    Keys.priority: Keys.BeforeItem
    Keys.onPressed: (event) => {
        const activate = event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space;
        const backward = event.key === Qt.Key_Left || event.key === Qt.Key_Up || event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier));
        const forward = event.key === Qt.Key_Right || event.key === Qt.Key_Down || event.key === Qt.Key_Tab;
        if (event.key === Qt.Key_Escape) {
            if (root.pendingAction.length > 0)
                root.cancelConfirmation();
            else
                root.closeRequested();
            event.accepted = true;
            return ;
        }
        if (root.pendingAction.length > 0) {
            if (backward || forward) {
                root.confirmIndex = root.confirmIndex === 0 ? 1 : 0;
                event.accepted = true;
                return ;
            }
            if (activate) {
                if (root.confirmIndex === 1)
                    root.confirmAction();
                else
                    root.cancelConfirmation();
                event.accepted = true;
            }
            return ;
        }
        if (backward) {
            root.moveSelection(-1);
            event.accepted = true;
            return ;
        }
        if (forward) {
            root.moveSelection(1);
            event.accepted = true;
            return ;
        }
        if (activate) {
            root.requestAction(root.currentIndex);
            event.accepted = true;
        }
    }

    Ui.RaisedSurface {
        anchors.fill: parent
        theme: root.theme
        fill: root.theme.surface
        surfaceRadius: root.theme.radiusPanel
        padding: root.theme.space4

        ColumnLayout {
            id: menuColumn

            anchors.fill: parent
            spacing: root.theme.space3

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 38
                spacing: root.theme.space3

                Rectangle {
                    Layout.preferredWidth: 34
                    Layout.preferredHeight: 34
                    radius: root.theme.radiusControl
                    color: root.theme.coral
                    border.width: root.theme.borderWidth
                    border.color: root.theme.ink

                    Image {
                        anchors.centerIn: parent
                        width: root.theme.iconMd
                        height: root.theme.iconMd
                        source: Quickshell.shellDir + "/assets/icons/power.svg"
                        sourceSize.width: root.theme.iconMd
                        sourceSize.height: root.theme.iconMd
                    }

                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        Layout.fillWidth: true
                        text: "Session"
                        color: root.theme.ink
                        font.family: root.theme.fontFamily
                        font.pixelSize: root.theme.textLg
                        font.weight: Font.Bold
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.pendingAction.length > 0 ? "One more check before continuing" : "What should Lotus do?"
                        color: root.theme.inkMuted
                        font.family: root.theme.fontFamily
                        font.pixelSize: root.theme.textXs
                    }

                }

                Ui.IconButton {
                    theme: root.theme
                    controlSize: 32
                    iconSource: Quickshell.shellDir + "/assets/icons/close.svg"
                    accessibleName: "Close session menu"
                    fill: root.theme.surfaceRaised
                    onClicked: root.closeRequested()
                }

            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: root.theme.outlineSoft
            }

            StackLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 84
                currentIndex: root.pendingAction.length > 0 ? 1 : 0

                RowLayout {
                    spacing: root.theme.space2

                    Repeater {
                        model: root.actions

                        Ui.ControlTile {
                            required property int index
                            required property var modelData

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            theme: root.theme
                            iconSource: modelData.icon
                            label: modelData.label
                            status: modelData.status
                            checked: index === root.currentIndex
                            accent: modelData.accent
                            onClicked: root.requestAction(index)
                        }

                    }

                }

                Rectangle {
                    radius: root.theme.radiusCard
                    color: root.theme.surfaceMuted
                    border.width: root.theme.borderWidth
                    border.color: root.theme.ink

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: root.theme.space3
                        spacing: root.theme.space3

                        Text {
                            Layout.fillWidth: true
                            text: root.pendingEntry !== undefined ? root.pendingEntry.question : "Continue?"
                            wrapMode: Text.WordWrap
                            color: root.theme.ink
                            font.family: root.theme.fontFamily
                            font.pixelSize: root.theme.textMd
                            font.weight: Font.Bold
                        }

                        Ui.PixelButton {
                            Layout.preferredWidth: 104
                            theme: root.theme
                            label: "Cancel"
                            fill: root.confirmIndex === 0 ? root.theme.lilac : root.theme.surfaceRaised
                            onClicked: root.cancelConfirmation()
                        }

                        Ui.PixelButton {
                            Layout.preferredWidth: 104
                            theme: root.theme
                            label: "Confirm"
                            fill: root.confirmIndex === 1 && root.pendingEntry !== undefined ? root.pendingEntry.accent : root.theme.surfaceRaised
                            onClicked: root.confirmAction()
                        }

                    }

                }

            }

            Text {
                Layout.fillWidth: true
                text: root.pendingAction.length > 0 ? "Left / Right to choose    Enter to continue    Esc to go back" : "Arrows or Tab to select    Enter to choose    Esc to close"
                horizontalAlignment: Text.AlignHCenter
                color: root.theme.inkMuted
                font.family: root.theme.fontFamily
                font.pixelSize: root.theme.textXs
            }

        }

    }

}
