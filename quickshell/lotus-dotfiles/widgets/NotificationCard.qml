import "../components" as Ui
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications

Item {
    id: root

    required property QtObject theme
    required property QtObject notificationService
    required property var entry
    property bool compact: false
    property bool replyOpen: false
    readonly property bool critical: entry.urgency === NotificationUrgency.Critical

    function iconSource(iconName) {
        const value = String(iconName || "");
        if (value.startsWith("file:") || value.startsWith("image:"))
            return value;

        if (value.startsWith("/"))
            return "file://" + value;

        if (value.length > 0 && Quickshell.hasThemeIcon(value))
            return Quickshell.iconPath(value);

        return Quickshell.shellDir + "/assets/icons/application.svg";
    }

    implicitWidth: compact ? theme.notificationToastWidth : Math.max(0, parent ? parent.width : theme.notificationCenterWidth)
    implicitHeight: cardColumn.implicitHeight + theme.space3 * 2 + theme.shadowOffset

    Ui.RaisedSurface {
        anchors.fill: parent
        theme: root.theme
        fill: root.theme.surfaceRaised
        surfaceRadius: root.theme.radiusCard
        padding: root.theme.space3

        ColumnLayout {
            id: cardColumn

            anchors.fill: parent
            spacing: root.theme.space2

            RowLayout {
                Layout.fillWidth: true
                spacing: root.theme.space2

                Rectangle {
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    radius: root.theme.radiusControl
                    color: root.critical ? root.theme.coral : root.theme.alpha(root.theme.green, 0.7)
                    border.width: root.theme.borderWidth
                    border.color: root.theme.ink

                    Image {
                        anchors.centerIn: parent
                        width: root.theme.iconMd
                        height: root.theme.iconMd
                        source: root.iconSource(root.entry.appIcon)
                        sourceSize.width: root.theme.iconMd
                        sourceSize.height: root.theme.iconMd
                        fillMode: Image.PreserveAspectFit
                        mipmap: true
                    }

                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        Layout.fillWidth: true
                        text: root.entry.appName
                        elide: Text.ElideRight
                        color: root.theme.inkMuted
                        font.family: root.theme.fontFamily
                        font.pixelSize: root.theme.textXs
                        font.weight: Font.Bold
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.entry.summary
                        elide: Text.ElideRight
                        color: root.theme.ink
                        font.family: root.theme.fontFamily
                        font.pixelSize: root.theme.textSm
                        font.weight: Font.Bold
                    }

                }

                Rectangle {
                    visible: root.entry.unread
                    Layout.preferredWidth: 8
                    Layout.preferredHeight: 8
                    radius: 4
                    color: root.critical ? root.theme.coral : root.theme.pink
                    border.width: 1
                    border.color: root.theme.ink
                }

                Text {
                    visible: !root.compact
                    text: Qt.formatTime(root.entry.receivedAt, "h:mm AP")
                    color: root.theme.inkMuted
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.textXs
                }

                Ui.IconButton {
                    theme: root.theme
                    controlSize: 30
                    iconSource: Quickshell.shellDir + "/assets/icons/close.svg"
                    accessibleName: "Dismiss " + root.entry.summary
                    fill: "transparent"
                    onClicked: root.notificationService.dismiss(root.entry.key)
                }

            }

            Text {
                visible: root.entry.body.length > 0
                Layout.fillWidth: true
                text: root.entry.body
                textFormat: Text.PlainText
                maximumLineCount: root.compact ? 2 : 5
                elide: Text.ElideRight
                wrapMode: Text.Wrap
                color: root.theme.ink
                font.family: root.theme.fontFamily
                font.pixelSize: root.theme.textXs
                lineHeight: 1.2
            }

            Rectangle {
                visible: root.entry.progress >= 0
                Layout.fillWidth: true
                Layout.preferredHeight: 12
                radius: root.theme.radiusPill
                color: root.theme.surfaceMuted
                border.width: 1
                border.color: root.theme.ink
                clip: true

                Rectangle {
                    width: Math.max(0, Math.min(parent.width, parent.width * root.entry.progress / 100))
                    height: parent.height
                    color: root.critical ? root.theme.coral : root.theme.green
                }

            }

            Image {
                visible: !root.compact && root.entry.image.length > 0
                Layout.fillWidth: true
                Layout.preferredHeight: visible ? 120 : 0
                source: root.entry.image
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
            }

            Flow {
                visible: root.entry.live && root.entry.actions.length > 0
                Layout.fillWidth: true
                Layout.preferredHeight: visible ? implicitHeight : 0
                spacing: root.theme.space2

                Repeater {

                    model: ScriptModel {
                        values: root.entry.actions
                    }

                    delegate: Ui.PixelButton {
                        required property var modelData

                        theme: root.theme
                        label: String(modelData.text || "Open")
                        fill: root.theme.green
                        onClicked: root.notificationService.invokeAction(root.entry.key, modelData.identifier)
                    }

                }

            }

            RowLayout {
                visible: !root.compact && root.entry.live && root.entry.hasInlineReply
                Layout.fillWidth: true
                Layout.preferredHeight: visible ? 38 : 0
                spacing: root.theme.space2

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 34
                    radius: root.theme.radiusControl
                    color: root.theme.surface
                    border.width: root.theme.borderWidth
                    border.color: replyInput.activeFocus ? root.theme.focus : root.theme.ink

                    TextInput {
                        id: replyInput

                        anchors.fill: parent
                        anchors.leftMargin: root.theme.space2
                        anchors.rightMargin: root.theme.space2
                        verticalAlignment: TextInput.AlignVCenter
                        clip: true
                        color: root.theme.ink
                        font.family: root.theme.fontFamily
                        font.pixelSize: root.theme.textXs
                        Accessible.name: root.entry.inlineReplyPlaceholder
                        Keys.onReturnPressed: {
                            if (root.notificationService.sendReply(root.entry.key, text))
                                text = "";

                        }
                    }

                    Text {
                        visible: replyInput.text.length === 0 && !replyInput.activeFocus
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: root.theme.space2
                        text: root.entry.inlineReplyPlaceholder
                        color: root.theme.inkMuted
                        font.family: root.theme.fontFamily
                        font.pixelSize: root.theme.textXs
                    }

                }

                Ui.PixelButton {
                    Layout.preferredWidth: 82
                    theme: root.theme
                    label: "Reply"
                    fill: root.theme.blue
                    enabled: replyInput.text.trim().length > 0
                    onClicked: {
                        if (root.notificationService.sendReply(root.entry.key, replyInput.text))
                            replyInput.text = "";

                    }
                }

            }

        }

    }

}
