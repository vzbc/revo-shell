pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Services.Notifications
import "../../"

Rectangle {
    id: root

    required property Notification notification

    property bool replyExpanded: false
    onReplyExpandedChanged: NotifServer.replyActive = replyExpanded

    readonly property string image: root.notification?.image ?? ""
    readonly property bool hasImage: root.image !== ""

    radius: UIScale.radiusLg
    color: Colors.surface
    border.color: Colors.withAlpha(Colors.accent, 0.18)
    border.width: 1
    implicitWidth: 340
    implicitHeight: mainRow.implicitHeight + UIScale.spacingLg + 4
    clip: true

    opacity: 0
    transform: [
        Translate {
            id: slideIn
            y: -8
        },
        Translate {
            id: swipeTrans
            x: 0
        }
    ]

    Component.onCompleted: showAnim.start()

    SequentialAnimation {
        id: showAnim
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "opacity"
                to: 1
                duration: Anim.medium
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: slideIn
                property: "y"
                to: 0
                duration: Anim.medium
                easing.type: Easing.OutCubic
            }
        }
    }

    function dismiss() {
        swipeDismissAnim.stop();
        swipeSnapBack.stop();
        hideAnim.start();
    }

    function viewNotification() {
        NotifServer.markRead();
        NotifServer.focusWindow(root.notification);
        const actions = root.notification?.actions ?? [];
        for (let i = 0; i < actions.length; i++) {
            if (actions[i].identifier === "default") {
                actions[i].invoke();
                return;
            }
        }
        root.dismiss();
    }

    function sendReply(text) {
        if (text.trim() === "")
            return;
        root.notification.sendInlineReply(text);
        root.dismiss();
    }

    SequentialAnimation {
        id: hideAnim
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "opacity"
                to: 0
                duration: Anim.fast
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: root
                property: "implicitHeight"
                to: 0
                duration: Anim.medium
                easing.type: Easing.InCubic
            }
        }
        ScriptAction {
            script: root.notification.dismiss()
        }
    }

    // Swipe to dismiss
    DragHandler {
        id: swipeDrag
        target: null
        xAxis.enabled: true
        yAxis.enabled: false
        acceptedButtons: Qt.LeftButton
        onTranslationChanged: {
            if (active)
                swipeTrans.x = translation.x >= 0 ? translation.x : -Math.log(1 + Math.abs(translation.x)) * 10;
        }
        onActiveChanged: {
            if (!active) {
                if (swipeTrans.x > 100) {
                    swipeDismissAnim.targetX = 420;
                    swipeDismissAnim.start();
                } else {
                    swipeSnapBack.start();
                }
            }
        }
    }

    NumberAnimation {
        id: swipeSnapBack
        target: swipeTrans
        property: "x"
        to: 0
        duration: Anim.medium
        easing.type: Easing.OutBack
        easing.overshoot: 1.2
    }

    SequentialAnimation {
        id: swipeDismissAnim
        property real targetX: 420
        ParallelAnimation {
            NumberAnimation {
                target: swipeTrans
                property: "x"
                to: swipeDismissAnim.targetX
                duration: Anim.medium
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: root
                property: "opacity"
                to: 0
                duration: Anim.medium
                easing.type: Easing.InCubic
            }
        }
        NumberAnimation {
            target: root
            property: "implicitHeight"
            to: 0
            duration: Anim.medium
            easing.type: Easing.InCubic
        }
        ScriptAction {
            script: {
                NotifServer.markRead();
                root.notification.dismiss();
            }
        }
    }

    Timer {
        interval: 8000
        running: !root.replyExpanded
        onTriggered: root.dismiss()
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.MiddleButton
        onClicked: {
            NotifServer.markRead();
            root.dismiss();
        }
    }

    RowLayout {
        id: mainRow
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: UIScale.spacingMd
        }
        spacing: UIScale.spacingSm

        Item {
            id: avatar
            Layout.alignment: Qt.AlignTop
            visible: root.hasImage
            implicitWidth: 36
            implicitHeight: 36

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: Colors.surfaceHigh
            }

            Rectangle {
                id: avatarMask
                anchors.fill: parent
                radius: width / 2
                visible: false
                layer.enabled: true
            }

            Image {
                anchors.fill: parent
                source: root.image
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(avatar.width * 2, avatar.height * 2)
                cache: false
                asynchronous: true
                layer.enabled: true
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: avatarMask
                    maskThresholdMin: 0.5
                    maskSpreadAtMin: 1.0
                }
            }

            Image {
                visible: (root.notification?.appIcon ?? "") !== ""
                width: 16
                height: 16
                anchors {
                    right: parent.right
                    bottom: parent.bottom
                }
                source: (root.notification?.appIcon ?? "") !== "" ? Quickshell.iconPath(root.notification.appIcon) : ""
                fillMode: Image.PreserveAspectFit
                asynchronous: true
            }
        }

        ColumnLayout {
            id: contentCol
            Layout.fillWidth: true
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                spacing: UIScale.spacingSm

                Text {
                    Layout.fillWidth: true
                    text: root.notification?.summary ?? ""
                    color: Colors.text
                    font.bold: true
                    font.pixelSize: UIScale.fontBody
                    elide: Text.ElideRight
                }

                Text {
                    text: root.notification?.appName ?? ""
                    color: Colors.muted
                    font.pixelSize: UIScale.fontCaption
                    opacity: 0.8
                }

                Text {
                    text: "✕"
                    color: closeHover.containsMouse ? Colors.accent : Colors.muted
                    font.pixelSize: UIScale.fontSmall
                    Behavior on color {
                        ColorAnimation {
                            duration: Anim.fast
                        }
                    }

                    MouseArea {
                        id: closeHover
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton
                        onClicked: {
                            NotifServer.markRead();
                            root.dismiss();
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                visible: (root.notification?.body ?? "") !== ""
                text: root.notification?.body ?? ""
                color: Colors.textDim
                font.pixelSize: UIScale.fontSmall
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                textFormat: Text.MarkdownText
            }

            // Action row: View + Reply + any extra actions
            RowLayout {
                Layout.fillWidth: true
                visible: !root.replyExpanded
                spacing: 6

                Rectangle {
                    radius: 6
                    color: viewHover.containsMouse ? Colors.withAlpha(Colors.accent, 0.2) : Colors.surfaceHigh
                    implicitWidth: viewLabel.implicitWidth + 16
                    implicitHeight: viewLabel.implicitHeight + 8

                    Text {
                        id: viewLabel
                        anchors.centerIn: parent
                        text: I18n.t("notifications.view")
                        color: Colors.accent
                        font.pixelSize: UIScale.fontCaption
                    }

                    MouseArea {
                        id: viewHover
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.viewNotification()
                    }
                }

                Rectangle {
                    visible: root.notification?.hasInlineReply ?? false
                    radius: 6
                    color: replyHover.containsMouse ? Colors.withAlpha(Colors.accent, 0.2) : Colors.surfaceHigh
                    implicitWidth: replyLabel.implicitWidth + 16
                    implicitHeight: replyLabel.implicitHeight + 8

                    Text {
                        id: replyLabel
                        anchors.centerIn: parent
                        text: I18n.t("notifications.reply")
                        color: Colors.accent
                        font.pixelSize: UIScale.fontCaption
                    }

                    MouseArea {
                        id: replyHover
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            root.replyExpanded = true;
                            Qt.callLater(function () {
                                replyInput.forceActiveFocus();
                            });
                        }
                    }
                }

                Repeater {
                    model: root.notification?.actions?.filter(a => a.identifier !== "default" && a.identifier !== "inline-reply") ?? []
                    delegate: Rectangle {
                        required property NotificationAction modelData
                        radius: 6
                        color: extraActionHover.containsMouse ? Colors.withAlpha(Colors.accent, 0.2) : Colors.surfaceHigh
                        implicitWidth: extraActionLabel.implicitWidth + 16
                        implicitHeight: extraActionLabel.implicitHeight + 8

                        Text {
                            id: extraActionLabel
                            anchors.centerIn: parent
                            text: parent.modelData.text
                            color: Colors.accent
                            font.pixelSize: UIScale.fontCaption
                        }

                        MouseArea {
                            id: extraActionHover
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                parent.modelData.invoke();
                                root.dismiss();
                            }
                        }
                    }
                }
            }

            // Inline reply row
            RowLayout {
                id: replyRow
                Layout.fillWidth: true
                visible: root.replyExpanded
                spacing: 6

                Rectangle {
                    Layout.fillWidth: true
                    radius: 6
                    color: Colors.surfaceHigh
                    implicitHeight: replyInput.implicitHeight + 10
                    border.color: replyInput.activeFocus ? Colors.withAlpha(Colors.accent, 0.5) : Colors.withAlpha(Colors.accent, 0.15)
                    border.width: 1

                    Text {
                        anchors {
                            left: parent.left
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                            leftMargin: 10
                            rightMargin: 10
                        }
                        visible: replyInput.text === "" && !replyInput.activeFocus
                        text: root.notification?.inlineReplyPlaceholder || I18n.t("notifications.replyPlaceholder")
                        color: Colors.muted
                        font.pixelSize: UIScale.fontSmall
                    }

                    TextInput {
                        id: replyInput
                        anchors {
                            left: parent.left
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                            leftMargin: 10
                            rightMargin: 10
                        }
                        color: Colors.text
                        font.pixelSize: UIScale.fontSmall
                        clip: true
                        Keys.onReturnPressed: root.sendReply(replyInput.text)
                        Keys.onEscapePressed: {
                            root.replyExpanded = false;
                            replyInput.text = "";
                        }
                    }
                }

                Rectangle {
                    radius: 6
                    color: sendHover.containsMouse ? Colors.withAlpha(Colors.accent, 0.2) : Colors.surfaceHigh
                    implicitWidth: sendLabel.implicitWidth + 14
                    implicitHeight: sendLabel.implicitHeight + 8

                    Text {
                        id: sendLabel
                        anchors.centerIn: parent
                        text: I18n.t("notifications.send")
                        color: Colors.accent
                        font.pixelSize: UIScale.fontCaption
                    }

                    MouseArea {
                        id: sendHover
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.sendReply(replyInput.text)
                    }
                }

                Text {
                    text: "✕"
                    color: cancelHover.containsMouse ? Colors.accent : Colors.muted
                    font.pixelSize: UIScale.fontSmall
                    Behavior on color {
                        ColorAnimation {
                            duration: Anim.fast
                        }
                    }

                    MouseArea {
                        id: cancelHover
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            root.replyExpanded = false;
                            replyInput.text = "";
                        }
                    }
                }
            }
        }
    }
}
