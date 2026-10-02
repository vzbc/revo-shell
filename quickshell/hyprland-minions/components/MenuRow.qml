import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.config

// One row of a menu or list: optional check/radio mark, icon, text, and a
// right-hand hint. Highlights on hover (or when `highlighted`).
Item {
    id: root

    property string text
    property string icon: ""
    property string hint: ""
    // 0 = none, 1 = checkbox, 2 = radio
    property int checkType: 0
    property bool checked: false
    // Keep the check column even without a mark, to line up with rows that have one.
    property bool reserveCheck: checkType !== 0
    property bool highlighted: false
    property bool bold: false

    readonly property alias hovered: mouse.containsMouse
    readonly property bool lit: enabled && (hovered || highlighted)

    signal clicked(var mouse)

    Layout.fillWidth: true
    implicitWidth: row.implicitWidth + 16
    implicitHeight: 24
    opacity: enabled ? 1 : 0.5

    Bevel {
        anchors.fill: parent
        anchors.margins: 1
        visible: root.lit
        shadow: false
        faceColor: Theme.selection
    }

    RowLayout {
        id: row

        anchors.fill: parent
        anchors.leftMargin: 6
        anchors.rightMargin: 8
        spacing: 6

        BarText {
            visible: root.reserveCheck
            Layout.preferredWidth: 10
            horizontalAlignment: Text.AlignHCenter
            text: !root.checked ? "" : root.checkType === 2 ? "●" : "✓"
            color: root.lit ? Theme.selectionText : Theme.text
        }

        IconImage {
            visible: root.icon !== ""
            source: root.icon
            implicitSize: 16
        }

        BarText {
            Layout.fillWidth: true
            text: root.text
            font.bold: root.bold
            color: root.lit ? Theme.selectionText : Theme.text
        }

        BarText {
            visible: root.hint !== ""
            text: root.hint
            color: root.lit ? Theme.selectionText : Theme.textDim
        }
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => root.clicked(mouse)
    }
}
