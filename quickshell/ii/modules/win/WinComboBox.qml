pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.win

/**
 * Windows 11 style combo box.
 */
ComboBox {
    id: root

    property string buttonIcon: ""

    implicitHeight: 36
    Layout.fillWidth: true

    background: Rectangle {
        radius: 4
        color: root.hovered ? WinTheme.cardHover : WinTheme.card
        border.width: 1
        border.color: root.popup.visible ? WinTheme.accent : WinTheme.border

        Behavior on color {
            ColorAnimation { duration: 120 }
        }
        Behavior on border.color {
            ColorAnimation { duration: 120 }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            cursorShape: Qt.PointingHandCursor
        }
    }

    indicator: MaterialSymbol {
        x: root.width - width - 12
        y: root.height / 2 - height / 2
        text: "keyboard_arrow_down"
        iconSize: Appearance.font.pixelSize.larger
        color: WinTheme.text

        rotation: root.popup.visible ? 180 : 0
        Behavior on rotation {
            NumberAnimation { duration: 120 }
        }
    }

    contentItem: Item {
        implicitWidth: buttonLayout.implicitWidth
        implicitHeight: buttonLayout.implicitHeight

        RowLayout {
            id: buttonLayout
            anchors.fill: parent
            spacing: 8
            anchors.leftMargin: 14
            anchors.rightMargin: 32

            Loader {
                Layout.alignment: Qt.AlignVCenter
                active: root.buttonIcon.length > 0 || (root.currentIndex >= 0 && typeof root.model[root.currentIndex] === 'object' && root.model[root.currentIndex]?.icon)
                visible: active
                sourceComponent: MaterialSymbol {
                    text: {
                        if (root.currentIndex >= 0 && typeof root.model[root.currentIndex] === 'object' && root.model[root.currentIndex]?.icon) {
                            return root.model[root.currentIndex].icon;
                        }
                        return root.buttonIcon;
                    }
                    iconSize: Appearance.font.pixelSize.larger
                    color: WinTheme.text
                }
            }

            StyledText {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                color: WinTheme.text
                text: root.displayText
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    delegate: ItemDelegate {
        id: itemDelegate
        width: ListView.view ? ListView.view.width : root.width
        implicitHeight: 32

        required property var model
        required property int index
        property bool isCurrent: root.currentIndex === itemDelegate.index

        background: Rectangle {
            radius: 4
            color: {
                if (itemDelegate.isCurrent && itemDelegate.hovered) return "#3f77a3"
                if (itemDelegate.hovered || itemDelegate.down) return WinTheme.cardHover
                if (itemDelegate.isCurrent) return "#2a4a63"
                return "transparent"
            }
            Behavior on color {
                ColorAnimation { duration: 100 }
            }
        }

        contentItem: RowLayout {
            spacing: 8
            anchors.leftMargin: 12
            anchors.rightMargin: 12

            Loader {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredHeight: Appearance.font.pixelSize.larger
                active: typeof itemDelegate.model === 'object' && itemDelegate.model?.icon?.length > 0
                visible: active
                sourceComponent: MaterialSymbol {
                    text: itemDelegate.model?.icon ?? ""
                    iconSize: Appearance.font.pixelSize.larger
                    color: itemDelegate.isCurrent ? WinTheme.text : WinTheme.textSecondary
                }
            }

            StyledText {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                color: itemDelegate.isCurrent ? WinTheme.text : WinTheme.textSecondary
                text: itemDelegate.model[root.textRole]
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    popup: Popup {
        y: root.height + 4
        width: root.width
        height: Math.min(listView.contentHeight + topPadding + bottomPadding, 300)
        padding: 6

        enter: Transition {
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: 120
            }
        }

        exit: Transition {
            NumberAnimation {
                property: "opacity"
                from: 1
                to: 0
                duration: 120
            }
        }

        background: Rectangle {
            radius: 8
            color: "#2b2b2b"
            border.width: 1
            border.color: WinTheme.border
        }

        contentItem: ListView {
            id: listView
            clip: true
            implicitHeight: contentHeight
            spacing: 2
            model: root.popup.visible ? root.delegateModel : null
            currentIndex: root.highlightedIndex
        }
    }
}
