import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.config
import qs.services

// Glossy plastic button used for every clickable thing in the bar and its
// popups. It brightens on hover, presses in while held down, and turns the
// theme's candy accent colour while `active` (its popup is open, it's the
// focused window, ...). `flat` buttons only show their plastic on hover/press.
//
// Set `icon` (anything IconImage can load) and/or `text`, or put your own
// children inside; they're parented to an item that fills the button.
Item {
    id: root

    property bool active: false
    property bool flat: false
    property string icon: ""
    property string text: ""
    property int iconSize: 14
    property bool bold: false
    property string tooltip: ""

    readonly property alias hovered: mouse.containsMouse
    readonly property alias pressed: mouse.pressed
    readonly property bool sunken: pressed
    // For text in custom children, so it stays readable on the active colour.
    readonly property color textColor: active ? Theme.activeText : Theme.text

    default property alias content: inner.data

    signal clicked(var mouse)
    signal scrolled(var wheel)

    implicitWidth: row.implicitWidth + 12
    implicitHeight: 26
    opacity: enabled ? 1 : 0.5

    Bevel {
        anchors.fill: parent
        visible: !root.flat || root.hovered || root.sunken || root.active
        sunken: root.sunken
        faceColor: {
            if (root.active)
                return root.hovered ? Theme.activeFaceHover : Theme.activeFace
            if (root.pressed)
                return Theme.facePressed
            return root.hovered ? Theme.faceHover : Theme.face
        }
    }

    Item {
        id: inner

        anchors.fill: parent
        transform: Translate {
            y: root.sunken ? 1 : 0
        }

        RowLayout {
            id: row

            anchors.centerIn: parent
            spacing: 4

            IconImage {
                visible: root.icon !== ""
                source: root.icon
                implicitSize: root.iconSize
            }

            BarText {
                visible: root.text !== ""
                text: root.text
                font.bold: root.bold
                color: root.textColor
            }
        }
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: mouse => root.clicked(mouse)
        onWheel: wheel => root.scrolled(wheel)
    }

    // Tooltip after hovering for a moment; suppressed while a popup is open.
    property bool tipVisible: false

    onHoveredChanged: {
        tipVisible = false
        if (hovered && tooltip !== "")
            tipDelay.restart()
        else
            tipDelay.stop()
    }
    onPressedChanged: {
        tipVisible = false
        tipDelay.stop()
    }

    Timer {
        id: tipDelay
        interval: 700
        onTriggered: root.tipVisible = true
    }

    LazyLoader {
        active: root.tipVisible && root.tooltip !== "" && Popups.current === null

        ToolTip {
            target: root
            text: root.tooltip
        }
    }
}
