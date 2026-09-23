import QtQuick
import Quickshell

QtObject {
    id: root

    readonly property date now: clock.date
    readonly property int hour24: now.getHours()
    readonly property int hour12: hour24 % 12 === 0 ? 12 : hour24 % 12
    readonly property string timeText: String(hour12) + ":" + twoDigits(now.getMinutes())
    readonly property string meridiemText: hour24 < 12 ? "AM" : "PM"
    readonly property string accessibleText: Qt.formatDateTime(now, "dddd, MMMM d, yyyy") + ", " + timeText + " " + meridiemText
    property SystemClock clock

    function twoDigits(value) {
        return value < 10 ? "0" + value : String(value);
    }

    clock: SystemClock {
        precision: SystemClock.Minutes
    }

}
