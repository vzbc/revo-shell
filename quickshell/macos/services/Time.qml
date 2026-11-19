pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../modules/common"

Singleton {
    id: root

    property string dateShort: ""
    property string timeShort: ""
    property string full: ""
    property string dateLong: ""
    property string timeHourMin: ""
    property string monthDay: ""

    readonly property var dayNamesShort: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    readonly property var monthNamesShort: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    readonly property var dayNames: ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    readonly property var monthNames: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]

    // Menu Bar > Clock Options (System Settings)
    readonly property bool use24h: Appearance.cfgGet("clock24h", false) === true
    readonly property bool showSeconds: Appearance.cfgGet("clockSeconds", false) === true
    readonly property bool showAmPm: Appearance.cfgGet("clockAmPm", true) !== false
    readonly property bool flashSeparators: Appearance.cfgGet("clockFlash", false) === true
    readonly property bool showDay: Appearance.cfgGet("clockDay", true) !== false
    readonly property string dateMode: String(Appearance.cfgGet("clockDateMode", "When Space Allows"))
    onUse24hChanged: update()
    onShowSecondsChanged: update()
    onShowAmPmChanged: update()
    onShowDayChanged: update()
    onDateModeChanged: update()

    property bool _tick: false

    function update() {
        const d = new Date();
        const h = d.getHours();
        const m12 = h % 12 === 0 ? 12 : h % 12;
        const min = String(d.getMinutes()).padStart(2, "0");
        const sec = String(d.getSeconds()).padStart(2, "0");
        const ampm = h < 12 ? "AM" : "PM";
        root._tick = !root._tick;
        const sep = (root.flashSeparators && root._tick) ? " " : ":";
        const hh = root.use24h ? String(h).padStart(2, "0") : String(m12);
        let t = hh + sep + min + (root.showSeconds ? sep + sec : "");
        if (!root.use24h && root.showAmPm) t += " " + ampm;
        const datePart = (root.showDay ? root.dayNamesShort[d.getDay()] + " " : "") + root.monthNamesShort[d.getMonth()] + " " + d.getDate();
        root.dateShort = root.dayNamesShort[d.getDay()] + " " + root.monthNamesShort[d.getMonth()] + " " + d.getDate();
        root.timeShort = t;
        if (root.dateMode === "Never")
            root.full = (root.showDay ? root.dayNamesShort[d.getDay()] + "  " : "") + t;
        else
            root.full = datePart + "  " + t;
        root.dateLong = root.dayNames[d.getDay()] + ", " + root.monthNames[d.getMonth()] + " " + d.getDate();
        root.timeHourMin = m12 + ":" + min;
        root.monthDay = root.monthNames[d.getMonth()] + " " + d.getDate();
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.update()
    }

    Component.onCompleted: root.update()
}
