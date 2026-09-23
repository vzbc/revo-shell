pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.Mpris
import "../../"
import "../shared"
import "../bar"

Item {
    id: root

    readonly property var _player: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null

    readonly property bool available: Mpris.players.values.length > 0
    visible: available
    onVisibleChanged: if (!visible)
        musicPopup.close()

    readonly property bool _vertical: BarConfig.isVertical
    readonly property int _textW: Math.round(110 * UIScale.value)
    readonly property int _crossAxis: Math.round(30 * UIScale.value)

    implicitWidth: root._vertical ? root._crossAxis : (iconText.implicitWidth + Math.round(UIScale.spacingSm) + root._textW)
    implicitHeight: root._vertical ? (iconTextV.implicitHeight + Math.round(UIScale.spacingSm) + root._textW) : root._crossAxis

    Row {
        visible: !root._vertical
        anchors.centerIn: parent
        spacing: Math.round(UIScale.spacingSm)

        Text {
            id: iconText
            anchors.verticalCenter: parent.verticalCenter
            text: "󰝚"
            color: Colors.muted
            font.pixelSize: UIScale.fontLead
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root._player ? root._player.trackTitle : ""
            width: root._textW
            elide: Text.ElideRight
            color: Colors.text
            font.pixelSize: UIScale.fontSmall
            font.bold: true
        }
    }

    // Vertical bar
    Column {
        visible: root._vertical
        anchors.centerIn: parent
        spacing: Math.round(UIScale.spacingSm)

        Text {
            id: iconTextV
            anchors.horizontalCenter: parent.horizontalCenter
            text: "󰝚"
            color: Colors.muted
            font.pixelSize: UIScale.fontLead
        }

        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: titleTextV.implicitHeight
            height: root._textW

            Text {
                id: titleTextV
                anchors.centerIn: parent
                width: root._textW
                text: root._player ? root._player.trackTitle : ""
                elide: Text.ElideRight
                color: Colors.text
                font.pixelSize: UIScale.fontSmall
                font.bold: true
                rotation: 90
            }
        }
    }

    HoverHandler {
        id: chipHover
        onHoveredChanged: {
            if (chipHover.hovered) {
                hideTimer.stop();
                musicPopup.open();
            } else if (!popupHover.hovered) {
                hideTimer.restart();
            }
        }
    }

    Timer {
        id: hideTimer
        interval: 300
        onTriggered: musicPopup.close()
    }

    AnimatedPopup {
        id: musicPopup
        anchorItem: root
        grabFocus: false
        implicitWidth: 400
        implicitHeight: 260

        HoverHandler {
            id: popupHover
            onHoveredChanged: {
                if (popupHover.hovered)
                    hideTimer.stop();
                else if (!chipHover.hovered)
                    hideTimer.restart();
            }
        }

        content: Component {
            MusicController {
                popupVisible: musicPopup.visible
            }
        }
    }
}
