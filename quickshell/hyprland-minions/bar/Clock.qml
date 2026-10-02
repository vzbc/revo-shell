import QtQuick
import Quickshell
import qs.components
import qs.popups

BarButton {
    id: root

    implicitWidth: 72
    active: popup.shown
    text: Qt.formatDateTime(clock.date, "h:mm AP")
    tooltip: Qt.formatDateTime(clock.date, "dddd, MMMM d, yyyy")
    onClicked: popup.toggle()

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    CalendarPopup {
        id: popup
        anchorItem: root
        align: Qt.AlignRight
    }
}
