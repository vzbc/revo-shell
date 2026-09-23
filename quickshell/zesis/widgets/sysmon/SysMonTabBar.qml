pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../../"

Item {
    id: root
    property bool compact: false

    readonly property int _h: Math.round((root.compact ? 30 : 32) * UIScale.value)
    readonly property int _pad: Math.round((root.compact ? 20 : 24) * UIScale.value)

    implicitWidth: tabRow.implicitWidth
    implicitHeight: Math.round((root.compact ? 44 : 48) * UIScale.value)

    RowLayout {
        id: tabRow
        spacing: Math.round(4 * UIScale.value)
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: root.compact ? 0 : UIScale.panelPad
        anchors.rightMargin: root.compact ? 0 : UIScale.panelPad

        Repeater {
            model: ["CPU", "Memory", "GPU", "Net", "Disk"]
            delegate: Rectangle {
                id: tab
                required property string modelData
                required property int index

                property bool active: SysMonService.activeTab === tab.index

                implicitHeight: root._h
                implicitWidth: tabLabel.implicitWidth + root._pad
                radius: root.compact ? Math.round(8 * UIScale.value) : UIScale.radiusSm
                color: tab.active ? (root.compact ? Colors.surface : Colors.withAlpha(Colors.accent, 0.15)) : ((root.compact ? tabArea.containsMouse : tabHover.hovered) ? (root.compact ? Colors.withAlpha(Colors.surface, 0.6) : Colors.withAlpha(Colors.text, 0.06)) : "transparent")
                border.color: (!root.compact && tab.active) ? Colors.withAlpha(Colors.accent, 0.4) : "transparent"
                border.width: 1
                Behavior on color {
                    ColorAnimation {
                        duration: Anim.fast
                    }
                }

                Text {
                    id: tabLabel
                    anchors.centerIn: parent
                    text: tab.modelData
                    color: tab.active ? (root.compact ? Colors.text : Colors.accent) : Colors.textDim
                    font.pixelSize: UIScale.fontSmall
                    font.weight: tab.active ? Font.DemiBold : Font.Normal
                    Behavior on color {
                        ColorAnimation {
                            duration: Anim.fast
                        }
                    }
                }

                HoverHandler {
                    id: tabHover
                    enabled: !root.compact
                }
                MouseArea {
                    id: tabArea
                    anchors.fill: parent
                    hoverEnabled: root.compact
                    cursorShape: Qt.PointingHandCursor
                    onClicked: SysMonService.activeTab = tab.index
                }
            }
        }

        Rectangle {
            id: settingsRect
            property bool active: SysMonService.activeTab === 5
            implicitHeight: root._h
            implicitWidth: root._h
            radius: root.compact ? Math.round(8 * UIScale.value) : UIScale.radiusSm
            color: settingsRect.active ? (root.compact ? Colors.surface : Colors.withAlpha(Colors.accent, 0.15)) : ((root.compact ? settingsArea.containsMouse : settingsHover.hovered) ? (root.compact ? Colors.withAlpha(Colors.surface, 0.6) : Colors.withAlpha(Colors.text, 0.06)) : "transparent")
            border.color: (!root.compact && settingsRect.active) ? Colors.withAlpha(Colors.accent, 0.4) : "transparent"
            border.width: 1
            Behavior on color {
                ColorAnimation {
                    duration: Anim.fast
                }
            }

            Text {
                anchors.centerIn: parent
                text: ""
                font.family: "Material Icons"
                font.pixelSize: Math.round(16 * UIScale.value)
                color: settingsRect.active ? Colors.accent : Colors.textDim
                Behavior on color {
                    ColorAnimation {
                        duration: Anim.fast
                    }
                }
            }

            HoverHandler {
                id: settingsHover
                enabled: !root.compact
            }
            MouseArea {
                id: settingsArea
                anchors.fill: parent
                hoverEnabled: root.compact
                cursorShape: Qt.PointingHandCursor
                onClicked: SysMonService.activeTab = 5
            }
        }

        Item {
            Layout.fillWidth: true
            visible: !root.compact
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Colors.withAlpha(Colors.text, 0.05)
        visible: !root.compact
    }
}
