import QtQuick

QtObject {
    id: root

    required property QtObject clockService
    property int visibleYear: clockService.now.getFullYear()
    property int visibleMonth: clockService.now.getMonth()
    readonly property int todayYear: clockService.now.getFullYear()
    readonly property int todayMonth: clockService.now.getMonth()
    readonly property int todayDay: clockService.now.getDate()
    readonly property string monthTitle: Qt.formatDateTime(new Date(visibleYear, visibleMonth, 1), "MMMM yyyy")
    readonly property var cells: buildCells()
    readonly property bool viewingCurrentMonth: visibleYear === todayYear && visibleMonth === todayMonth

    function buildCells() {
        const firstDay = new Date(visibleYear, visibleMonth, 1).getDay();
        const daysInMonth = new Date(visibleYear, visibleMonth + 1, 0).getDate();
        const daysInPreviousMonth = new Date(visibleYear, visibleMonth, 0).getDate();
        const output = [];
        for (let index = firstDay - 1; index >= 0; index--) output.push({
            "day": daysInPreviousMonth - index,
            "currentMonth": false,
            "today": false
        })
        for (let day = 1; day <= daysInMonth; day++) output.push({
            "day": day,
            "currentMonth": true,
            "today": viewingCurrentMonth && day === todayDay
        })
        let nextDay = 1;
        while (output.length < 42) {
            output.push({
                "day": nextDay,
                "currentMonth": false,
                "today": false
            });
            nextDay++;
        }
        return output;
    }

    function previousMonth() {
        if (visibleMonth === 0) {
            visibleMonth = 11;
            visibleYear--;
        } else {
            visibleMonth--;
        }
    }

    function nextMonth() {
        if (visibleMonth === 11) {
            visibleMonth = 0;
            visibleYear++;
        } else {
            visibleMonth++;
        }
    }

    function goToToday() {
        visibleYear = todayYear;
        visibleMonth = todayMonth;
    }

}
