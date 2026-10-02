import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services

// Frame shared by every bar popup. Only one popup is open at a time (see
// Popups). It closes on Escape, when its button is clicked again, or on a
// click anywhere else on the screen: while it's open, a transparent
// "catcher" layer covers everything except the bar and the popup itself.
//
// It's a layer-shell panel placed just above the bar rather than an
// xdg-popup, because popups only get keyboard focus when opened by a click,
// and the start menu can also be opened over IPC.
//
// It's drawn as a thick glossy plastic frame (windowBorder) around a white
// inset well (window) that holds the contents. Children are laid out in a
// column; give them Layout.fillWidth to stretch.
PanelWindow {
    id: popup

    required property Item anchorItem
    // Which edge of anchorItem the popup lines up with.
    property int align: Qt.AlignHCenter
    property int padding: 8
    property alias spacing: body.spacing
    // Thickness of the plastic frame around the well.
    readonly property int frame: 9
    // Room below the frame for its drop shadow.
    readonly property int shadowRoom: 3

    readonly property bool shown: Popups.current === popup
    readonly property var barWindow: anchorItem.QsWindow.window

    default property alias content: body.data

    function toggle() {
        Popups.toggle(popup)
    }

    function close() {
        if (shown)
            Popups.close()
    }

    // Line the popup up with its button, keeping it on screen.
    function reposition() {
        const x = anchorItem.mapToItem(null, 0, 0).x
        const w = implicitWidth
        const left = align === Qt.AlignLeft ? x
                   : align === Qt.AlignRight ? x + anchorItem.width - w
                   : x + (anchorItem.width - w) / 2
        margins.left = Math.round(Math.max(0, Math.min(left, (screen?.width ?? left + w) - w)))
    }

    onShownChanged: if (shown) reposition()
    onImplicitWidthChanged: if (shown) reposition()

    screen: barWindow?.screen ?? null
    visible: shown
    color: "transparent"
    implicitWidth: body.implicitWidth + (padding + frame) * 2
    implicitHeight: body.implicitHeight + (padding + frame) * 2 + shadowRoom

    anchors {
        bottom: true
        left: true
    }
    margins.bottom: 2
    // Zone 0 = don't reserve space, but sit above the bar's zone.
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "plasticbar-popup"
    // Not Exclusive: Hyprland would then send *all* input, clicks included,
    // to the popup only.
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    // Click-catcher. It stops at the bar's reserved zone, so bar buttons
    // still work, and sits on a lower layer than the popup.
    LazyLoader {
        active: popup.shown

        PanelWindow {
            screen: popup.screen
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            exclusionMode: ExclusionMode.Normal
            exclusiveZone: 0
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.namespace: "plasticbar-catcher"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
                onPressed: popup.close()
            }
        }
    }

    Item {
        anchors.fill: parent
        anchors.bottomMargin: popup.shadowRoom
        focus: true
        Keys.onEscapePressed: popup.close()

        Bevel {
            anchors.fill: parent
            radius: Theme.radiusLarge + 4
            faceColor: Theme.windowBorder
        }

        Bevel {
            anchors.fill: parent
            anchors.margins: popup.frame - 1
            radius: Theme.radiusLarge - 2
            sunken: true
            faceColor: Theme.window
        }

        ColumnLayout {
            id: body

            anchors.fill: parent
            anchors.margins: popup.padding + popup.frame
            spacing: 6
        }
    }
}
