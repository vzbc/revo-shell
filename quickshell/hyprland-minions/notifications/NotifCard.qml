import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets
import qs.components
import qs.config
import qs.services

// A notification drawn as a rounded plastic card: glossy title pill with the
// app name and a close button, then summary, body and action buttons. Used both for
// toasts and in the notification centre. Clicking the body runs the default
// action.
Item {
    id: root

    required property Notification modelData
    // Toasts get the "focused window" title colour, list entries a quiet one.
    property bool highlight: false

    // The Notification is destroyed as soon as it's dismissed, a moment
    // before this card goes away, so only read it through these.
    readonly property string appName: modelData?.appName ?? ""
    readonly property string summary: modelData?.summary ?? ""
    readonly property string body: modelData?.body ?? ""
    readonly property string image: modelData?.image ?? ""
    readonly property string appIcon: modelData?.appIcon ?? ""
    readonly property var actions: modelData ? [...modelData.actions] : []
    readonly property bool critical: modelData?.urgency === NotificationUrgency.Critical

    readonly property string iconSource: image !== ""
        ? image
        : appIcon !== "" ? Quickshell.iconPath(appIcon, true) : ""

    readonly property alias hovered: hover.hovered

    implicitHeight: column.implicitHeight + 12
    implicitWidth: 300

    HoverHandler {
        id: hover
    }

    Bevel {
        anchors.fill: parent
        anchors.bottomMargin: 1
        radius: Theme.radiusLarge
        faceColor: Theme.window
    }

    ColumnLayout {
        id: column

        anchors.fill: parent
        anchors.margins: 5
        anchors.bottomMargin: 7
        spacing: 0

        // Title strip
        Bevel {
            id: titleBar

            readonly property color textColor: root.critical || root.highlight ? Theme.selectionText : Theme.titleInactiveText

            Layout.fillWidth: true
            implicitHeight: 24
            radius: Theme.radiusLarge - 4
            shadow: false
            faceColor: root.critical ? Theme.warning : root.highlight ? Theme.selection : Theme.titleInactive

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 3
                spacing: 4

                BarText {
                    Layout.fillWidth: true
                    text: root.appName !== "" ? root.appName : "Notification"
                    font.bold: true
                    color: titleBar.textColor
                }

                BarButton {
                    implicitWidth: 18
                    implicitHeight: 18
                    text: "×"
                    onClicked: root.modelData?.dismiss()
                }
            }
        }

        // Body
        Item {
            Layout.fillWidth: true
            implicitHeight: bodyRow.implicitHeight + 12

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (!root.modelData) return
                    Notifs.activate(root.modelData)
                    Notifs.hideToast(root.modelData)
                }
            }

            RowLayout {
                id: bodyRow

                anchors.fill: parent
                anchors.margins: 6
                spacing: 8

                IconImage {
                    Layout.alignment: Qt.AlignTop
                    visible: root.iconSource !== ""
                    source: root.iconSource
                    implicitSize: 32
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    spacing: 2

                    BarText {
                        Layout.fillWidth: true
                        text: root.summary
                        font.bold: true
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                    }

                    BarText {
                        Layout.fillWidth: true
                        visible: root.body !== ""
                        text: root.body
                        textFormat: Text.StyledText
                        wrapMode: Text.Wrap
                        maximumLineCount: 6
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.textDim
                        linkColor: Theme.text
                        onLinkActivated: link => Qt.openUrlExternally(link)
                    }
                }
            }
        }

        // Actions (the "default" one is triggered by clicking the body)
        RowLayout {
            readonly property var actions: root.actions.filter(a => a.identifier !== "default")

            Layout.fillWidth: true
            Layout.leftMargin: 6
            Layout.rightMargin: 6
            Layout.bottomMargin: 6
            visible: actions.length > 0
            spacing: 4

            Repeater {
                model: parent.actions

                delegate: BarButton {
                    required property var modelData

                    Layout.fillWidth: true
                    implicitHeight: 24
                    text: modelData?.text ?? ""
                    onClicked: modelData?.invoke()
                }
            }
        }
    }
}
