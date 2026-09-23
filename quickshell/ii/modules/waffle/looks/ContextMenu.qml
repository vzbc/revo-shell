pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.waffle.looks

// Windows 11 style context menu.
//
// Model items:
//   { type: "separator" }
//   { text, icon?, checkmark?, action? }                 -> regular entry
//   { type: "submenu", text, icon?, submenu: [...] }     -> submenu entry
//
// The root menu (parentMenu === null) owns a single focus grab that covers
// every open menu window in the tree, so clicking anything else dismisses it.
PopupWindow {
    id: root

    property var model: []
    property bool isOpen: false
    property var parentMenu: null
    property var hostItem: null
    property double lastCloseTime: 0

    readonly property real visualMargin: 12
    readonly property real ambientShadowWidth: 1
    readonly property real padding: 2

    readonly property bool hasIcons: (root.model ?? []).some(
        item => item.type !== "separator"
            && (item.icon !== undefined || item.submenu !== undefined || item.checkmark !== undefined)
    )

    // ==== API ====
    function openAt(host, x, y) {
        root.hostItem = host;
        root.anchor.item = host;
        root.anchor.rect = Qt.rect(x, y, 1, 1);
        root.anchor.edges = Edges.Top | Edges.Left;
        root.anchor.gravity = Edges.Top | Edges.Left;
        root.anchor.adjustment = PopupAdjustment.Slide | PopupAdjustment.Flip;
        root.showMenu();
    }

    function openAdjacent(trigger) {
        const g = trigger.mapToGlobal(0, 0);
        const h = root.hostItem.mapToGlobal(0, 0);
        root.anchor.item = root.hostItem;
        root.anchor.rect = Qt.rect(Math.round(g.x - h.x), Math.round(g.y - h.y), trigger.width, trigger.height);
        root.anchor.edges = Edges.Top | Edges.Right;
        root.anchor.gravity = Edges.Top | Edges.Left;
        root.anchor.adjustment = PopupAdjustment.Slide | PopupAdjustment.Flip;
        root.showMenu();
    }

    function showMenu() {
        root.isOpen = true;
        root.visible = true;
        WaffleContext.registerMenu(root);
        if (root.parentMenu !== null) root.parentMenu.adoptWindow(root);
        fadeIn.start();
    }

    function closeMenu() {
        if (!root.isOpen && !submenuLoader.active) return;
        root.closeSubmenus();
        root.isOpen = false;
        root.visible = false;
        root.lastCloseTime = Date.now();
    }

    // ==== Submenus ====
    property var grabWindows: []
    property var activeSubmenuEntry: null
    property var hoveredEntry: null
    property var openTarget: null
    property bool pointerInSubmenu: false

    function adoptWindow(win) {
        if (root.parentMenu !== null) {
            root.parentMenu.adoptWindow(win);
            return;
        }
        if (root.grabWindows.indexOf(win) === -1) {
            root.grabWindows = root.grabWindows.concat([win]);
            focusGrab.windows = [root].concat(root.grabWindows);
        }
    }

    function releaseWindow(win) {
        if (root.parentMenu !== null) {
            root.parentMenu.releaseWindow(win);
            return;
        }
        const index = root.grabWindows.indexOf(win);
        if (index !== -1) {
            const copy = root.grabWindows.slice();
            copy.splice(index, 1);
            root.grabWindows = copy;
            focusGrab.windows = [root].concat(root.grabWindows);
        }
    }

    function openChild(trigger, submenuModel) {
        if (submenuLoader.active && submenuLoader.item.parentMenu === root && submenuLoader.item.model === submenuModel) {
            return;
        }
        root.closeSubmenus();
        submenuLoader.openFor(trigger, submenuModel);
        root.activeSubmenuEntry = trigger;
    }

    function closeSubmenus() {
        if (submenuLoader.active) {
            submenuLoader.item.closeMenu();
            submenuLoader.active = false;
        }
        root.activeSubmenuEntry = null;
    }

    function entryHovered(entry) {
        root.hoveredEntry = entry;
        if (entry.entryChevron) {
            root.openTarget = entry;
            openTimer.start();
        } else if (root.activeSubmenuEntry !== null) {
            closeTimer.start();
        }
    }

    function entryUnhovered(entry) {
        if (root.hoveredEntry === entry) root.hoveredEntry = null;
        if (root.activeSubmenuEntry === entry) {
            closeTimer.start();
        }
    }

    Timer {
        id: openTimer
        interval: 180
        onTriggered: {
            const entry = root.openTarget;
            if (entry && entry.entryChevron && entry.hovered && root.activeSubmenuEntry !== entry) {
                root.openChild(entry, entry.entrySubmenuModel);
            }
        }
    }

    Timer {
        id: closeTimer
        interval: 250
        onTriggered: {
            if (!root.pointerInSubmenu
                && root.activeSubmenuEntry !== null
                && root.hoveredEntry !== root.activeSubmenuEntry) {
                root.closeSubmenus();
            }
        }
    }

    Loader {
        id: submenuLoader
        active: false
        source: "ContextMenu.qml"

        function openFor(trigger, submenuModel) {
            submenuLoader.active = true;
            submenuLoader.item.model = submenuModel;
            submenuLoader.item.parentMenu = root;
            submenuLoader.item.hostItem = root.hostItem;
            submenuLoader.item.openAdjacent(trigger);
        }
    }

    HyprlandFocusGrab {
        id: focusGrab
        active: root.isOpen && root.parentMenu === null
        windows: [root].concat(root.grabWindows)
        onCleared: root.closeMenu()
    }

    Component.onDestruction: {
        WaffleContext.unregisterMenu(root);
        if (root.parentMenu !== null) root.parentMenu.releaseWindow(root);
    }

    // ==== Window ====
    visible: false
    color: "transparent"
    implicitWidth: menuBackground.implicitWidth + root.ambientShadowWidth + root.visualMargin * 2
    implicitHeight: menuBackground.implicitHeight + root.ambientShadowWidth + root.visualMargin * 2

    PropertyAnimation {
        id: fadeIn
        target: menuBackground
        property: "opacity"
        to: 1
        duration: 130
        easing.type: Easing.OutCubic
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true

        onEntered: {
            if (root.parentMenu !== null) root.parentMenu.pointerInSubmenu = true;
        }
        onExited: {
            if (root.parentMenu !== null) root.parentMenu.pointerInSubmenu = false;
        }

        WAmbientShadow {
            target: menuBackground
        }

        Rectangle {
            id: menuBackground
            opacity: 0
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                bottom: parent.bottom
                margins: root.ambientShadowWidth + root.visualMargin
            }
            color: Looks.colors.bg1Base
            radius: Looks.radius.large

            implicitWidth: entries.implicitWidth + root.padding * 2
            implicitHeight: entries.implicitHeight + root.padding * 2

            ColumnLayout {
                id: entries
                anchors {
                    fill: parent
                    margins: root.padding
                }
                spacing: 0

                Repeater {
                    model: root.model
                    delegate: DelegateChooser {
                        role: "type"

                        DelegateChoice {
                            roleValue: "separator"
                            Rectangle {
                                Layout.topMargin: 3
                                Layout.bottomMargin: 3
                                Layout.fillWidth: true
                                implicitHeight: 1
                                color: Looks.colors.bg0Border
                            }
                        }

                        DelegateChoice {
                            roleValue: "submenu"
                            MenuEntry {
                                required property var modelData
                                entryText: modelData.text ?? ""
                                entryIcon: modelData.icon ?? ""
                                entryChevron: true
                                entrySubmenuModel: modelData.submenu
                                forceIcon: root.hasIcons

                                onTriggered: btn => root.openChild(btn, modelData.submenu)
                            }
                        }

                        DelegateChoice {
                            roleValue: undefined
                            MenuEntry {
                                required property var modelData
                                entryText: modelData.text ?? ""
                                entryIcon: modelData.icon ?? ""
                                entryChecked: modelData.checkmark === true
                                forceIcon: root.hasIcons

                                onTriggered: () => {
                                    if (modelData.action) modelData.action();
                                    root.closeMenu();
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ==== Entries ====
    component MenuEntry: Button {
        id: entry
        required property string entryText
        property string entryIcon: ""
        property bool entryChecked: false
        property bool entryChevron: false
        property var entrySubmenuModel: undefined
        property bool forceIcon: false

        signal triggered(Item btn)

        Layout.fillWidth: true
        implicitHeight: 32
        horizontalPadding: 12
        topInset: 0
        bottomInset: 0
        leftInset: 0
        rightInset: 0

        background: Rectangle {
            radius: Looks.radius.medium
            color: entry.hovered || entry.down ? Looks.colors.bg2Hover : "transparent"
            Behavior on color {
                animation: Looks.transition.color.createObject(this)
            }
        }

        contentItem: Item {
            implicitWidth: contentLayout.implicitWidth
            implicitHeight: contentLayout.implicitHeight

            RowLayout {
                id: contentLayout
                anchors {
                    fill: parent
                    leftMargin: entry.horizontalPadding
                    rightMargin: entry.horizontalPadding
                }
                spacing: 12

                FluentIcon {
                    implicitSize: 18
                    Layout.alignment: Qt.AlignVCenter
                    visible: entry.forceIcon
                    icon: entry.entryIcon
                    color: Looks.colors.fg
                    monochrome: true
                }
                WText {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                    text: entry.entryText
                    font.pixelSize: Looks.font.pixelSize.large
                    horizontalAlignment: Text.AlignLeft
                    color: Looks.colors.fg
                }
                FluentIcon {
                    implicitSize: 14
                    Layout.alignment: Qt.AlignVCenter
                    visible: entry.entryChecked
                    icon: "checkmark"
                    color: Looks.colors.fg
                    monochrome: true
                }
                FluentIcon {
                    implicitSize: 14
                    Layout.alignment: Qt.AlignVCenter
                    visible: entry.entryChevron
                    icon: "chevron-right"
                    color: Looks.colors.fg
                    monochrome: true
                }
            }
        }

        onHoveredChanged: {
            if (entry.hovered) root.entryHovered(entry);
            else root.entryUnhovered(entry);
        }

        onClicked: entry.triggered(entry)
    }
}
