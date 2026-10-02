import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components
import qs.config
import qs.popups
import qs.services

BarButton {
    id: root

    required property ShellScreen screen

    implicitWidth: 78
    active: menu.shown || themes.shown
    tooltip: "Right click: themes"
    onClicked: mouse => {
        if (mouse.button === Qt.RightButton)
            themes.toggle()
        else
            menu.toggle()
    }

    RowLayout {
        anchors.centerIn: parent
        spacing: 6

        Image {
            source: Theme.startIcon
            sourceSize.width: 16
            sourceSize.height: 16
        }

        BarText {
            text: "Start"
            font.bold: true
            color: root.textColor
        }
    }

    Connections {
        target: Popups

        function onStartMenuRequested(screenName) {
            if (screenName === root.screen.name)
                menu.toggle()
        }
    }

    StartMenu {
        id: menu
        anchorItem: root
        onThemesRequested: Popups.open(themes)
    }

    ThemeMenu {
        id: themes
        anchorItem: root
    }
}
