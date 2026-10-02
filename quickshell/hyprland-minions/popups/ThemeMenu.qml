import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config

// Theme picker: light/dark toggle plus every theme in config/themes.
// Changes apply immediately and are remembered.
BarPopup {
    id: popup

    align: Qt.AlignLeft
    padding: 4
    implicitWidth: 220

    PopupHeader {
        text: "Theme"

        BarButton {
            implicitWidth: 44
            implicitHeight: 24
            text: "Light"
            active: !Theme.dark
            onClicked: Theme.setDark(false)
        }

        BarButton {
            implicitWidth: 44
            implicitHeight: 24
            text: "Dark"
            active: Theme.dark
            onClicked: Theme.setDark(true)
        }
    }

    Separator {
        vertical: false
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        Repeater {
            model: Theme.themes

            delegate: MenuRow {
                required property var modelData

                text: modelData.name
                checkType: 2
                checked: modelData.id === Theme.current
                onClicked: Theme.setTheme(modelData.id)
            }
        }
    }
}
