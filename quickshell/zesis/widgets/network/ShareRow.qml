import QtQuick
import QtQuick.Layouts
import "../../"

Item {
    required property var modelData
    required property string hostname
    required property string authUser
    required property string authPass

    readonly property string shareName: modelData.name
    readonly property string shareComment: modelData.comment ?? ""
    readonly property string shareState: modelData.state

    height: Math.round(40 * UIScale.value)

    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: Math.round(2 * UIScale.value)
        anchors.rightMargin: Math.round(2 * UIScale.value)
        radius: UIScale.radiusSm
        color: shareState === "mounted" ? Colors.withAlpha(Colors.accent, 0.12) : (shareHover.hovered ? Colors.surfaceHigh : "transparent")
        Behavior on color {
            ColorAnimation {
                duration: Anim.fast
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: UIScale.spacingMd
        anchors.rightMargin: UIScale.spacingSm
        spacing: UIScale.spacingSm

        Rectangle {
            implicitWidth: Math.round(6 * UIScale.value)
            implicitHeight: Math.round(6 * UIScale.value)
            radius: implicitWidth / 2
            color: shareState === "mounted" ? Colors.accent : Colors.withAlpha(Colors.text, 0.2)
            Behavior on color {
                ColorAnimation {
                    duration: Anim.fast
                }
            }
        }

        Column {
            Layout.fillWidth: true
            spacing: 0

            Text {
                text: shareName
                color: Colors.text
                font.pixelSize: UIScale.fontSmall
                font.weight: shareState === "mounted" ? Font.DemiBold : Font.Normal
                elide: Text.ElideRight
                width: parent.width
            }

            Text {
                visible: shareComment.length > 0
                text: shareComment
                color: Colors.textDim
                font.pixelSize: UIScale.fontCaption
                elide: Text.ElideRight
                width: parent.width
            }
        }

        Rectangle {
            visible: shareState === "idle" && NetworkService.mountBackend !== "smbnetfs"
            implicitWidth: mountBtnText.implicitWidth + UIScale.spacingSm * 2
            implicitHeight: Math.round(24 * UIScale.value)
            radius: Math.round(12 * UIScale.value)
            color: mountBtnMa.containsMouse ? Colors.withAlpha(Colors.accent, 0.25) : Colors.withAlpha(Colors.accent, 0.12)
            Behavior on color {
                ColorAnimation {
                    duration: Anim.fast
                }
            }

            Text {
                id: mountBtnText
                anchors.centerIn: parent
                text: I18n.t("network.mountAction")
                color: Colors.accent
                font.pixelSize: UIScale.fontCaption
            }

            MouseArea {
                id: mountBtnMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: NetworkService.mount(hostname, shareName, authUser, authPass)
            }
        }

        Text {
            visible: shareState === "mounting"
            text: "..."
            color: Colors.muted
            font.pixelSize: UIScale.fontSmall
        }

        Rectangle {
            visible: shareState === "mounted"
            implicitWidth: openBtnText.implicitWidth + UIScale.spacingSm * 2
            implicitHeight: Math.round(24 * UIScale.value)
            radius: Math.round(12 * UIScale.value)
            color: openBtnMa.containsMouse ? Colors.withAlpha(Colors.accent, 0.25) : Colors.withAlpha(Colors.accent, 0.12)
            Behavior on color {
                ColorAnimation {
                    duration: Anim.fast
                }
            }

            Text {
                id: openBtnText
                anchors.centerIn: parent
                text: I18n.t("network.openAction")
                color: Colors.accent
                font.pixelSize: UIScale.fontCaption
            }

            MouseArea {
                id: openBtnMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: NetworkService.openPath(NetworkService.mountUri(hostname, shareName))
            }
        }

        Rectangle {
            visible: shareState === "mounted" && NetworkService.mountBackend !== "smbnetfs"
            implicitWidth: unmountBtnText.implicitWidth + UIScale.spacingSm * 2
            implicitHeight: Math.round(24 * UIScale.value)
            radius: Math.round(12 * UIScale.value)
            color: unmountBtnMa.containsMouse ? Colors.withAlpha(Colors.accent, 0.2) : "transparent"
            border.color: Colors.withAlpha(Colors.accent, 0.4)
            border.width: 1
            Behavior on color {
                ColorAnimation {
                    duration: Anim.fast
                }
            }

            Text {
                id: unmountBtnText
                anchors.centerIn: parent
                text: I18n.t("network.unmountAction")
                color: Colors.accent
                font.pixelSize: UIScale.fontCaption
            }

            MouseArea {
                id: unmountBtnMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    var uri = NetworkService.mountUri(hostname, shareName);
                    if (uri)
                        NetworkService.unmount(uri);
                }
            }
        }

        Rectangle {
            visible: shareState === "error"
            implicitWidth: retryBtnText.implicitWidth + UIScale.spacingSm * 2
            implicitHeight: Math.round(24 * UIScale.value)
            radius: Math.round(12 * UIScale.value)
            color: retryBtnMa.containsMouse ? Colors.withAlpha(Colors.accent, 0.2) : Colors.withAlpha(Colors.accent, 0.08)
            Behavior on color {
                ColorAnimation {
                    duration: Anim.fast
                }
            }

            Text {
                id: retryBtnText
                anchors.centerIn: parent
                text: I18n.t("network.retryAction")
                color: Colors.accent
                font.pixelSize: UIScale.fontCaption
            }

            MouseArea {
                id: retryBtnMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: NetworkService.mount(hostname, shareName, authUser, authPass)
            }
        }
    }

    HoverHandler {
        id: shareHover
    }
}
