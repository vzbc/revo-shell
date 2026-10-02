import QtQuick
import QtQuick.Layouts
import qs.components

// Right-click menu for a taskbar button.
BarPopup {
    id: popup

    property var toplevel // Wayland Toplevel

    align: Qt.AlignLeft
    padding: 2
    spacing: 0

    MenuRow {
        text: "Focus"
        bold: true
        reserveCheck: true
        onClicked: {
            popup.toplevel?.activate()
            popup.close()
        }
    }

    MenuRow {
        text: "Maximize"
        checkType: 1
        checked: popup.toplevel?.maximized ?? false
        onClicked: {
            popup.toplevel.maximized = !popup.toplevel.maximized
            popup.close()
        }
    }

    MenuRow {
        text: "Fullscreen"
        checkType: 1
        checked: popup.toplevel?.fullscreen ?? false
        onClicked: {
            popup.toplevel.fullscreen = !popup.toplevel.fullscreen
            popup.close()
        }
    }

    Separator {
        vertical: false
    }

    MenuRow {
        Layout.preferredWidth: 150
        text: "Close"
        hint: "Mid-click"
        reserveCheck: true
        onClicked: {
            popup.toplevel?.close()
            popup.close()
        }
    }
}
