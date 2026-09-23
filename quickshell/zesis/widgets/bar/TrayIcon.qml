pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import "../../"

Item {
    id: root

    required property SystemTrayItem item

    implicitWidth: 28
    implicitHeight: 28
    Layout.alignment: Qt.AlignCenter

    Rectangle {
        anchors.fill: parent
        radius: 6
        color: trayMouseArea.containsMouse ? Colors.withAlpha(Colors.accent, 0.12) : "transparent"
        Behavior on color {
            ColorAnimation {
                duration: Anim.fast
            }
        }
    }

    IconImage {
        anchors.centerIn: parent
        implicitSize: 18
        source: root.resolveIcon(root.item.icon)
        smooth: true
        mipmap: true
    }

    MouseArea {
        id: trayMouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: event => {
            if (event.button === Qt.LeftButton) {
                root.item.activate();
            } else if (event.button === Qt.RightButton && root.item.hasMenu) {
                // Reset to root menu before showing
                rootOpener.menu = root.item.menu;
                menuPopup.visible = true;
            }
        }
    }

    PopupWindow {
        id: menuPopup
        anchor.item: root
        anchor.rect.x: {
            if (BarConfig.side === "left")
                return root.width;
            if (BarConfig.side === "right")
                return -menuPopup.implicitWidth;
            return root.width / 2 - menuPopup.implicitWidth / 2;
        }
        anchor.rect.y: {
            if (BarConfig.side === "bottom")
                return -menuPopup.implicitHeight;
            if (BarConfig.isVertical)
                return root.height / 2 - menuPopup.implicitHeight / 2;
            return root.height;
        }
        grabFocus: true
        visible: false
        color: "transparent"

        property string _barSide: BarConfig.side
        on_BarSideChanged: menuPopup.visible = false
        implicitWidth: 220
        implicitHeight: Math.min(menuList.contentHeight + 10, 480)

        onVisibleChanged: {
            if (!visible)
                rootOpener.menu = root.item.menu;
        }

        QsMenuOpener {
            id: rootOpener
            menu: root.item.menu
        }

        Rectangle {
            anchors.fill: parent
            color: Colors.surface
            radius: 10
            border.color: Colors.withAlpha(Colors.accent, 0.25)
            border.width: 1
            clip: true

            ListView {
                id: menuList
                anchors {
                    fill: parent
                    margins: 4
                }
                spacing: 1
                model: ScriptModel {
                    values: [...rootOpener.children.values]
                }

                delegate: Rectangle {
                    id: entry
                    required property QsMenuEntry modelData

                    property QsMenuOpener childMenu: QsMenuOpener {
                        menu: entry.modelData
                    }

                    width: menuList.width
                    height: entry.modelData.isSeparator ? 5 : 32
                    color: "transparent"
                    radius: 6

                    // Separator line
                    Rectangle {
                        visible: entry.modelData.isSeparator
                        anchors.centerIn: parent
                        width: parent.width - 16
                        height: 1
                        color: Colors.outline
                    }

                    // Hover background for normal items
                    Rectangle {
                        visible: !entry.modelData.isSeparator
                        anchors.fill: parent
                        radius: 6
                        color: itemHover.containsMouse && entry.modelData.enabled ? Colors.withAlpha(Colors.accent, 0.14) : "transparent"
                        Behavior on color {
                            ColorAnimation {
                                duration: Anim.micro
                            }
                        }
                    }

                    RowLayout {
                        visible: !entry.modelData.isSeparator
                        anchors {
                            fill: parent
                            leftMargin: 12
                            rightMargin: 10
                        }
                        spacing: 6

                        // Checkbox / radio indicator
                        Text {
                            visible: entry.modelData.buttonType === QsMenuButtonType.CheckBox || entry.modelData.buttonType === QsMenuButtonType.RadioButton
                            text: entry.modelData.checkState === Qt.Checked ? "●" : "○"
                            color: Colors.accent
                            font.pixelSize: 10
                        }

                        Text {
                            Layout.fillWidth: true
                            text: entry.modelData.text ?? ""
                            color: entry.modelData.enabled ? Colors.text : Colors.muted
                            font.pixelSize: 13
                            elide: Text.ElideRight
                            verticalAlignment: Text.AlignVCenter
                        }

                        // Submenu arrow
                        Text {
                            visible: entry.modelData.hasChildren
                            text: ">"
                            color: Colors.muted
                            font.pixelSize: 14
                        }
                    }

                    MouseArea {
                        id: itemHover
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: !entry.modelData.isSeparator && entry.modelData.enabled
                        onClicked: {
                            if (entry.modelData.hasChildren) {
                                rootOpener.menu = entry.childMenu.menu;
                            } else {
                                entry.modelData.triggered();
                                menuPopup.visible = false;
                            }
                        }
                    }
                }
            }
        }
    }

    function resolveIcon(icon) {
        if (icon && icon.includes("?path=")) {
            const parts = icon.split("?path=");
            const name = parts[0];
            const path = parts[1];
            return `file://${path}/${name.slice(name.lastIndexOf("/") + 1)}`;
        }
        return icon ?? "";
    }
}
