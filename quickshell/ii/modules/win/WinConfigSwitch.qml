import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.win

/**
 * Windows 11 style settings toggle row.
 */
Item {
    id: root

    property string text: ""
    property string buttonIcon: ""
    property bool checked: false
    property bool enabled: true
    property bool hovered: hoverArea.containsMouse
    signal clicked()
    signal toggled(bool value)

    Layout.fillWidth: true
    implicitHeight: 40

    opacity: root.enabled ? 1 : 0.45
    Behavior on opacity {
        NumberAnimation { duration: 120 }
    }

    Rectangle {
        anchors.fill: parent
        radius: 4
        color: root.hovered ? WinTheme.cardHover : "transparent"
        Behavior on color {
            ColorAnimation { duration: 120 }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 10

        OptionalMaterialSymbol {
            icon: root.buttonIcon
            iconSize: Appearance.font.pixelSize.larger
            Layout.alignment: Qt.AlignVCenter
        }
        StyledText {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            text: root.text
            color: WinTheme.text
            font.pixelSize: Appearance.font.pixelSize.small
            wrapMode: Text.WordWrap
        }
        WinSwitch {
            Layout.alignment: Qt.AlignVCenter
            checked: root.checked
            onToggled: value => {
                root.checked = value;
                root.toggled(value);
            }
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.checked = !root.checked;
            root.toggled(root.checked);
            root.clicked();
        }
    }
}
