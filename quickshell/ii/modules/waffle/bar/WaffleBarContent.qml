import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.waffle.looks
import qs.modules.waffle.bar.tasks
import qs.modules.waffle.bar.tray

Rectangle {
    id: root

    color: Config.options.waffles.bar.transparent
        ? Qt.rgba(Looks.colors.bg0Base.r, Looks.colors.bg0Base.g, Looks.colors.bg0Base.b, 0.0)
        : Looks.colors.bg0
    implicitHeight: 48

    MouseArea {
        id: barMenuHost
        anchors.fill: parent
        acceptedButtons: Qt.RightButton

        onClicked: (event) => {
            if (barContextMenu.isOpen) {
                barContextMenu.closeMenu();
                return;
            }
            if (Date.now() - barContextMenu.lastCloseTime < 200) return;
            WaffleContext.closeAll();
            barContextMenu.openAt(barMenuHost, event.x, event.y);
        }
    }

    BarContextMenu {
        id: barContextMenu
    }
    
    Rectangle {
        id: border
        anchors {
            left: parent.left
            right: parent.right
            top: Config.options.waffles.bar.bottom ? parent.top : undefined
            bottom: Config.options.waffles.bar.bottom ? undefined : parent.bottom
        }
        visible: !Config.options.waffles.bar.transparent
        color: Looks.colors.bg0Border
        implicitHeight: 1
    }

    BarGroupRow {
        id: appsRow
        anchors.left: undefined
        anchors.horizontalCenter: parent.horizontalCenter

        states: State {
            name: "left"
            when: Config.options.waffles.bar.leftAlignApps
            AnchorChanges {
                target: appsRow
                anchors.left: parent.left
                anchors.horizontalCenter: undefined
            }
        }

        transitions: Transition {
            animations: Looks.transition.anchor.createObject(this)
        }

        StartButton {}
        SearchBox {
            visible: Config.options.waffles.bar.showSearchBox
        }
        Tasks {}
    }

    BarGroupRow {
        id: systemRow
        anchors.right: parent.right
        FadeLoader {
            Layout.fillHeight: true
            shown: Config.options.waffles.bar.leftAlignApps
        }
        Tray {}
        UpdatesButton {}
        SystemButton {}
        TimeButton {}
    }

    component BarGroupRow: RowLayout {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        spacing: 0
    }
}
