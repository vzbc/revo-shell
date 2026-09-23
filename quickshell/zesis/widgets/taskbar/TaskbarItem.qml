import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import Quickshell.Wayland._Screencopy
import "../bar"
import "../wm"
import "../../"

Item {
    id: root

    required property string appId
    property int itemSize: Math.round(44 * UIScale.value)

    implicitWidth: itemSize
    implicitHeight: itemSize

    readonly property int _iconSz: Math.round(26 * UIScale.value)

    readonly property var _entry: {
        var _ = DesktopEntries.applications.values.length;
        return DesktopEntries.heuristicLookup(root.appId);
    }
    readonly property string _name: _entry ? _entry.name : root.appId
    readonly property string _iconName: _entry ? _entry.icon : ""

    // WlrForeignToplevel objects for this app (have .activated, .activate(), etc.)
    readonly property var _toplevels: {
        var result = [];
        var arr = ToplevelManager.toplevels.values;
        for (var i = 0; i < arr.length; i++) {
            var t = arr[i];
            if (t.appId && t.appId.toLowerCase() === root.appId.toLowerCase())
                result.push(t);
        }
        return result;
    }

    readonly property bool _isActive: {
        for (var i = 0; i < root._toplevels.length; i++)
            if (root._toplevels[i].activated)
                return true;
        return false;
    }

    readonly property real _thumbW: Math.round(220 * UIScale.value)
    readonly property real _thumbH: {
        var mon = WmService.focusedMonitor;
        return (mon && mon.width > 0) ? Math.round(root._thumbW * mon.height / mon.width) : Math.round(root._thumbW * 9 / 16);
    }

    readonly property bool _show: TaskbarService.activeItem === root

    HoverHandler {
        id: hov
        onHoveredChanged: {
            if (hovered) {
                TaskbarService.hover(root);
            } else if (!popupHov.hovered && root._show) {
                TaskbarService.leave();
            }
        }
    }

    TapHandler {
        onTapped: {
            for (var i = 0; i < root._toplevels.length; i++) {
                if (root._toplevels[i].activated) {
                    root._toplevels[i].activate();
                    return;
                }
            }
            if (root._toplevels.length > 0)
                root._toplevels[0].activate();
        }
    }

    // Active tint
    Rectangle {
        anchors.fill: parent
        anchors.margins: Math.round(3 * UIScale.value)
        radius: UIScale.radiusSm
        color: Colors.withAlpha(Colors.accent, root._isActive ? 0.12 : 0.0)
        Behavior on color {
            ColorAnimation {
                duration: Anim.fast
            }
        }
    }

    // Hover highlight
    Rectangle {
        anchors.fill: parent
        anchors.margins: Math.round(3 * UIScale.value)
        radius: UIScale.radiusSm
        color: Colors.withAlpha(Colors.text, hov.hovered ? 0.08 : 0.0)
        Behavior on color {
            ColorAnimation {
                duration: Anim.fast
            }
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: Math.round(4 * UIScale.value)

        Item {
            width: root._iconSz
            height: root._iconSz
            anchors.horizontalCenter: parent.horizontalCenter

            IconImage {
                id: iconImg
                anchors.fill: parent
                source: root._iconName ? Quickshell.iconPath(root._iconName) : ""
                implicitSize: root._iconSz
                asynchronous: true
            }

            Rectangle {
                anchors.fill: parent
                visible: iconImg.status !== Image.Ready
                radius: width / 2
                color: Colors.withAlpha(Colors.accent, 0.2)
                Text {
                    anchors.centerIn: parent
                    text: root.appId.length > 0 ? root.appId[0].toUpperCase() : "?"
                    color: Colors.accent
                    font.pixelSize: Math.round(root._iconSz * 0.44)
                    font.weight: Font.Bold
                }
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Math.round(3 * UIScale.value)

            Repeater {
                model: root._toplevels.slice(0, 3)
                delegate: Rectangle {
                    required property var modelData
                    width: Math.round(4 * UIScale.value)
                    height: width
                    radius: width / 2
                    color: modelData.activated ? Colors.accent : Colors.withAlpha(Colors.text, 0.3)
                    Behavior on color {
                        ColorAnimation {
                            duration: Anim.fast
                        }
                    }
                }
            }
        }
    }

    PopupWindow {
        id: popup
        visible: root._show && root._toplevels.length > 0
        grabFocus: false
        color: "transparent"

        anchor.item: root
        anchor.edges: BarConfig.isVertical ? (BarConfig.side === "left" ? Edges.Right : Edges.Left) : (BarConfig.side === "top" ? Edges.Bottom : Edges.Top)
        anchor.gravity: BarConfig.isVertical ? (BarConfig.side === "left" ? Edges.Right : Edges.Left) : (BarConfig.side === "top" ? Edges.Bottom : Edges.Top)
        anchor.adjustment: PopupAdjustment.All
        anchor.margins.top: BarConfig.side === "bottom" ? Math.round(-8 * UIScale.value) : 0
        anchor.margins.bottom: BarConfig.side === "top" ? Math.round(-8 * UIScale.value) : 0
        anchor.margins.left: BarConfig.side === "right" ? Math.round(-8 * UIScale.value) : 0
        anchor.margins.right: BarConfig.side === "left" ? Math.round(-8 * UIScale.value) : 0

        readonly property int _cardH: root._thumbH + Math.round(28 * UIScale.value)
        readonly property int _cardSpacing: Math.round(6 * UIScale.value)
        readonly property int _maxVisible: 4
        readonly property int _visibleCount: Math.min(root._toplevels.length, popup._maxVisible)
        implicitWidth: root._thumbW + Math.round(16 * UIScale.value)
        implicitHeight: Math.round(26 * UIScale.value) + popup._visibleCount * popup._cardH + Math.max(0, popup._visibleCount - 1) * popup._cardSpacing + Math.round(18 * UIScale.value)

        onVisibleChanged: if (visible)
            WmService.refreshToplevels()

        HoverHandler {
            id: popupHov
            onHoveredChanged: {
                if (hovered) {
                    TaskbarService.hover(root);
                } else if (!hov.hovered && root._show) {
                    TaskbarService.leave();
                }
            }
        }

        Loader {
            active: root._show
            anchors.fill: parent

            sourceComponent: Rectangle {
                radius: UIScale.radiusMd
                color: Colors.surface
                border.color: Colors.withAlpha(Colors.outline, 0.5)
                border.width: 1

                Column {
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        topMargin: Math.round(10 * UIScale.value)
                        leftMargin: Math.round(8 * UIScale.value)
                        rightMargin: Math.round(8 * UIScale.value)
                    }
                    spacing: Math.round(6 * UIScale.value)

                    Text {
                        width: parent.width
                        text: root._name.toUpperCase()
                        color: Colors.muted
                        font.pixelSize: UIScale.fontTiny
                        font.weight: Font.Bold
                        font.letterSpacing: 1.2
                        elide: Text.ElideRight
                        bottomPadding: Math.round(2 * UIScale.value)
                    }

                    Flickable {
                        width: parent.width
                        height: popup._visibleCount * popup._cardH + Math.max(0, popup._visibleCount - 1) * popup._cardSpacing
                        contentWidth: width
                        contentHeight: root._toplevels.length * popup._cardH + Math.max(0, root._toplevels.length - 1) * popup._cardSpacing
                        clip: true
                        interactive: root._toplevels.length > popup._maxVisible
                        boundsBehavior: Flickable.StopAtBounds

                        ScrollBar.vertical: ScrollBar {
                            policy: root._toplevels.length > popup._maxVisible ? ScrollBar.AlwaysOn : ScrollBar.AlwaysOff
                            width: Math.round(4 * UIScale.value)
                            contentItem: Rectangle {
                                radius: width / 2
                                color: Colors.withAlpha(Colors.text, 0.35)
                                opacity: parent.active ? 1.0 : 0.5
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: Anim.fast
                                    }
                                }
                            }
                            background: null
                        }

                        Column {
                            width: parent.width
                            spacing: popup._cardSpacing

                            Repeater {
                                model: root._toplevels
                                delegate: Rectangle {
                                    id: winCard
                                    required property var modelData
                                    required property int index

                                    width: parent.width
                                    height: popup._cardH
                                    radius: UIScale.radiusSm
                                    color: cardHov.hovered ? Colors.withAlpha(Colors.text, 0.08) : winCard.modelData.activated ? Colors.withAlpha(Colors.accent, 0.1) : "transparent"
                                    Behavior on color {
                                        ColorAnimation {
                                            duration: Anim.fast
                                        }
                                    }

                                    HoverHandler {
                                        id: cardHov
                                    }
                                    TapHandler {
                                        onTapped: {
                                            winCard.modelData.activate();
                                            TaskbarService.activeItem = null;
                                        }
                                    }

                                    Column {
                                        anchors.fill: parent
                                        anchors.margins: Math.round(4 * UIScale.value)
                                        spacing: Math.round(4 * UIScale.value)

                                        Loader {
                                            active: root._show
                                            width: parent.width
                                            height: root._thumbH
                                            clip: true
                                            sourceComponent: ScreencopyView {
                                                anchors.fill: parent
                                                captureSource: winCard.modelData
                                                live: true
                                            }
                                        }

                                        RowLayout {
                                            width: parent.width

                                            Rectangle {
                                                implicitWidth: Math.round(6 * UIScale.value)
                                                implicitHeight: implicitWidth
                                                radius: implicitWidth / 2
                                                color: winCard.modelData.activated ? Colors.accent : Colors.withAlpha(Colors.text, 0.25)
                                                Behavior on color {
                                                    ColorAnimation {
                                                        duration: Anim.fast
                                                    }
                                                }
                                            }

                                            Text {
                                                Layout.fillWidth: true
                                                text: winCard.modelData.title || root._name
                                                color: winCard.modelData.activated ? Colors.text : Colors.textDim
                                                font.pixelSize: UIScale.fontSmall
                                                font.weight: winCard.modelData.activated ? Font.DemiBold : Font.Normal
                                                elide: Text.ElideRight
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        implicitHeight: Math.round(4 * UIScale.value)
                    }
                }
            }
        }
    }
}
