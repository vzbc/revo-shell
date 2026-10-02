import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components
import qs.config

// A tray item's DBus menu drawn in the bar's own style. Submenus open in
// place with a "Back" row, since popups can't nest.
BarPopup {
    id: popup

    property var handle // QsMenuHandle
    property var stack: []

    readonly property var currentMenu: stack.length > 0 ? stack[stack.length - 1] : handle
    readonly property bool anyChecks: [...opener.children.values].some(e => e.buttonType !== QsMenuButtonType.None)

    padding: 2
    spacing: 0
    onShownChanged: stack = []

    QsMenuOpener {
        id: opener
        menu: popup.shown ? popup.currentMenu : null
    }

    MenuRow {
        visible: popup.stack.length > 0
        text: "◄ " + (popup.stack.length > 0 ? popup.stack[popup.stack.length - 1].text : "")
        bold: true
        onClicked: popup.stack = popup.stack.slice(0, -1)
    }

    Separator {
        visible: popup.stack.length > 0
        vertical: false
    }

    Repeater {
        model: opener.children

        delegate: Item {
            id: entry

            required property QsMenuEntry modelData

            Layout.fillWidth: true
            Layout.minimumWidth: 160
            implicitWidth: modelData.isSeparator ? 0 : row.implicitWidth
            implicitHeight: modelData.isSeparator ? 6 : row.implicitHeight

            Separator {
                anchors.fill: parent
                visible: entry.modelData.isSeparator
                vertical: false
            }

            MenuRow {
                id: row

                width: parent.width
                visible: !entry.modelData.isSeparator
                enabled: entry.modelData.enabled
                // Strip GTK-style mnemonics ("_File" -> "File", "__" -> "_").
                text: entry.modelData.text.replace(/_(.)/g, "$1")
                icon: entry.modelData.icon
                hint: entry.modelData.hasChildren ? "►" : ""
                checkType: entry.modelData.buttonType === QsMenuButtonType.CheckBox ? 1
                         : entry.modelData.buttonType === QsMenuButtonType.RadioButton ? 2 : 0
                checked: entry.modelData.checkState === Qt.Checked
                reserveCheck: popup.anyChecks

                onClicked: {
                    if (entry.modelData.hasChildren) {
                        popup.stack = [...popup.stack, entry.modelData]
                    } else {
                        entry.modelData.triggered()
                        popup.close()
                    }
                }
            }
        }
    }
}
