pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

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

    function update() {
        const d = new Date();
        const h = d.getHours();
        const m12 = h % 12 === 0 ? 12 : h % 12;
        const min = String(d.getMinutes()).padStart(2, "0");
        const ampm = h < 12 ? "AM" : "PM";
        root.dateShort = root.dayNamesShort[d.getDay()] + " " + root.monthNamesShort[d.getMonth()] + " " + d.getDate();
        root.timeShort = m12 + ":" + min + " " + ampm;
        root.full = root.dateShort + "  " + root.timeShort;
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
