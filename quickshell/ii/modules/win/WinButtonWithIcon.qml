import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.win

/**
 * Windows 11 style settings button with icon.
 */
Rectangle {
    id: root

    property string nerdIcon
    property string materialIcon
    property bool materialIconFill: true
    property string mainText: "Button text"
    property Component mainContentComponent: Component {
        StyledText {
            visible: text !== ""
            text: root.mainText
            font.pixelSize: Appearance.font.pixelSize.small
            color: WinTheme.text
        }
    }
    property real buttonRadius: 4
    property bool enabled: true
    property bool hovered: mouseArea.containsMouse
    property bool down: false
    property color colBackground: "#333333"
    property color colBackgroundHover: "#3a3a3a"
    property color colBackgroundActive: "#454545"
    property color colRipple: "transparent"
    signal clicked()

    implicitHeight: 35
    implicitWidth: Math.max(84, contentRow.implicitWidth + 20)
    radius: buttonRadius
    color: {
        if (!root.enabled) return "#2a2a2a"
        if (root.down) return root.colBackgroundActive
        if (root.hovered) return root.colBackgroundHover
        return root.colBackground
    }
    Behavior on color {
        ColorAnimation { duration: 120 }
    }

    opacity: root.enabled ? 1 : 0.4
    Behavior on opacity {
        NumberAnimation { duration: 120 }
    }

    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: 6

        Loader {
            Layout.alignment: Qt.AlignVCenter
            active: root.nerdIcon
            visible: active
            sourceComponent: StyledText {
                text: root.nerdIcon
                font.pixelSize: Appearance.font.pixelSize.larger
                font.family: Appearance.font.family.iconNerd
                color: WinTheme.text
            }
        }
        Loader {
            Layout.alignment: Qt.AlignVCenter
            active: !root.nerdIcon && root.materialIcon && root.materialIcon.length > 0
            visible: active
            sourceComponent: MaterialSymbol {
                text: root.materialIcon
                iconSize: Appearance.font.pixelSize.larger
                color: WinTheme.text
                fill: root.materialIconFill ? 1 : 0
            }
        }
        Loader {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            sourceComponent: root.mainContentComponent
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
        onPressed: root.down = true
        onReleased: root.down = false
        onCanceled: root.down = false
        onClicked: root.clicked()
    }
}
