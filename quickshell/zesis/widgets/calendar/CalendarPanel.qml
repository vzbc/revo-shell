pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../shared"
import "../../"

// Note: Claude Code helped me transfer the visual language of Outlook to QML
// The majority of this file has been written by Claude Code.

Item {
    id: root

    readonly property var _monthNames: I18n.t("calendar.monthNames").split("|")
    readonly property var _shortDayNames: I18n.t("calendar.shortDayNames").split("|")
    readonly property var _today: new Date()

    // Form state
    property bool _creating: false
    property bool _newAllDay: false
    property string _newCal: ""
    property var _formEvent: null
    property string _newRepeat: "none"
    property var _newAttendees: []
    property var _newReminderMin: null

    readonly property var _reminderOptions: [
        {
            label: I18n.t("calendar.reminderNone"),
            value: null
        },
        {
            label: I18n.t("calendar.reminder15Min"),
            value: 15
        },
        {
            label: I18n.t("calendar.reminder30Min"),
            value: 30
        },
        {
            label: I18n.t("calendar.reminder1Hour"),
            value: 60
        },
        {
            label: I18n.t("calendar.reminder1Day"),
            value: 1440
        }
    ]

    // Week view state
    property var _selectedEvent: null
    property real _popupX: 0
    property real _popupY: 0
    readonly property real _hourPx: Math.round(56 * UIScale.value)
    readonly property real _hourLabelW: Math.round(44 * UIScale.value)

    readonly property var _weekStart: {
        var d = new Date(miniGrid.selectedDate);
        var day = d.getDay();
        var diff = day === 0 ? -6 : 1 - day;
        d.setDate(d.getDate() + diff);
        d.setHours(0, 0, 0, 0);
        return d;
    }

    readonly property var _weekDays: {
        var ws = root._weekStart;
        var days = [];
        for (var i = 0; i < 7; i++) {
            var d = new Date(ws);
            d.setDate(d.getDate() + i);
            days.push(d);
        }
        return days;
    }

    readonly property var _timedWeekEvents: {
        var out = [], ws = root._weekStart;
        if (!ws)
            return out;
        var wsMs = ws.getTime(), weMs = wsMs + 7 * 86400000;
        for (var i = 0; i < CalendarService.events.length; i++) {
            var ev = CalendarService.events[i];
            if (!ev.allDay && new Date(ev.start).getTime() >= wsMs && new Date(ev.start).getTime() < weMs)
                out.push(ev);
        }
        return out;
    }

    readonly property var _allDayWeekEvents: {
        var out = [], ws = root._weekStart;
        if (!ws)
            return out;
        var wsMs = ws.getTime(), weMs = wsMs + 7 * 86400000;
        for (var i = 0; i < CalendarService.events.length; i++) {
            var ev = CalendarService.events[i];
            if (ev.allDay && new Date(ev.start).getTime() >= wsMs && new Date(ev.start).getTime() < weMs)
                out.push(ev);
        }
        return out;
    }

    property var _now: new Date()
    Timer {
        interval: 60000
        repeat: true
        running: true
        onTriggered: root._now = new Date()
    }

    readonly property int _nowTodayCol: {
        var ws = root._weekStart;
        if (!ws)
            return -1;
        var t = new Date(root._now);
        t.setHours(0, 0, 0, 0);
        var diff = Math.round((t.getTime() - ws.getTime()) / 86400000);
        return (diff >= 0 && diff < 7) ? diff : -1;
    }
    readonly property real _nowY: (root._now.getHours() * 60 + root._now.getMinutes()) * root._hourPx / 60

    // Functions

    function goToThisWeek() {
        miniGrid.selectedDate = root._today;
        miniGrid.viewYear = root._today.getFullYear();
        miniGrid.viewMonth = root._today.getMonth();
    }
    function prevWeek() {
        var d = new Date(miniGrid.selectedDate);
        d.setDate(d.getDate() - 7);
        miniGrid.selectedDate = d;
        miniGrid.viewYear = root._weekStart.getFullYear();
        miniGrid.viewMonth = root._weekStart.getMonth();
    }
    function nextWeek() {
        var d = new Date(miniGrid.selectedDate);
        d.setDate(d.getDate() + 7);
        miniGrid.selectedDate = d;
        miniGrid.viewYear = root._weekStart.getFullYear();
        miniGrid.viewMonth = root._weekStart.getMonth();
    }

    function fmtTime(ev) {
        if (!ev || ev.allDay)
            return I18n.t("calendar.allDay");
        return ev.start.substring(11, 16);
    }
    function fmtTimeRange(ev) {
        if (!ev)
            return "";
        if (ev.allDay)
            return I18n.t("calendar.allDay");
        var s = ev.start.substring(11, 16);
        var e = ev.end ? ev.end.substring(11, 16) : "";
        return e ? s + " - " + e : s;
    }
    function fmtWeekRange() {
        var ws = root._weekStart;
        if (!ws)
            return "";
        var we = new Date(ws);
        we.setDate(we.getDate() + 6);
        var m = root._monthNames;
        if (ws.getMonth() === we.getMonth())
            return m[ws.getMonth()].substring(0, 3) + " " + ws.getDate() + " - " + we.getDate() + ", " + ws.getFullYear();
        return m[ws.getMonth()].substring(0, 3) + " " + ws.getDate() + " - " + m[we.getMonth()].substring(0, 3) + " " + we.getDate();
    }
    function fmtReminderLabel(min) {
        if (min === null || min === undefined)
            return "";
        if (min === 0)
            return I18n.t("calendar.atTimeOfEvent");
        if (min < 60)
            return I18n.t("calendar.minutesBefore", [min]);
        if (min === 60)
            return I18n.t("calendar.oneHourBefore");
        if (min < 1440)
            return I18n.t("calendar.hoursBefore", [min / 60]);
        return min === 1440 ? I18n.t("calendar.oneDayBefore") : I18n.t("calendar.daysBefore", [min / 1440]);
    }
    function errText(e) {
        if (e === "missing:icalendar")
            return I18n.t("calendar.icalendarNotInstalled");
        if (e.startsWith("no_dir:"))
            return I18n.t("calendar.calendarDirNotFound", [e.substring(7)]);
        if (e === "vdirsyncer_missing")
            return I18n.t("calendar.vdirsyncerNotFound");
        if (e === "parse_error")
            return I18n.t("calendar.parseError");
        return e;
    }
    function eventDayCol(ev) {
        var ws = root._weekStart;
        var d = new Date(ev.start);
        d.setHours(0, 0, 0, 0);
        return Math.round((d.getTime() - ws.getTime()) / 86400000);
    }
    function eventY(ev) {
        var d = new Date(ev.start);
        return (d.getHours() * 60 + d.getMinutes()) * root._hourPx / 60;
    }
    function eventH(ev) {
        if (!ev.end)
            return root._hourPx;
        var dmin = (new Date(ev.end).getTime() - new Date(ev.start).getTime()) / 60000;
        return Math.max(dmin * root._hourPx / 60, Math.round(20 * UIScale.value));
    }

    function openEditForm(ev) {
        root._selectedEvent = null;
        root._formEvent = ev;
        root._creating = true;
        root._newAllDay = ev.allDay;
        root._newRepeat = ev.repeat || "none";
        root._newCal = ev.calendar;
        root._newAttendees = ev.attendees ? JSON.parse(JSON.stringify(ev.attendees)) : [];
        root._newReminderMin = ev.reminderMin !== undefined ? ev.reminderMin : null;
        sumField.text = ev.summary;
        startField.text = ev.allDay ? "09:00" : ev.start.substring(11, 16);
        endField.text = (ev.end && !ev.allDay) ? ev.end.substring(11, 16) : "10:00";
        locField.text = ev.location || "";
        urlField.text = ev.url || "";
        descField.text = ev.description || "";
    }

    // Layout

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        PanelHeader {
            Layout.fillWidth: true
            breadcrumb: I18n.t("calendar.breadcrumb")
            title: I18n.t("calendar.title")
        }

        // Error banner
        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: UIScale.panelPad
            Layout.rightMargin: UIScale.panelPad
            Layout.topMargin: UIScale.spacingXs
            implicitHeight: errLabel.implicitHeight + UIScale.spacingMd * 2
            radius: UIScale.radiusMd
            color: Colors.withAlpha(Colors.accent, 0.1)
            border.color: Colors.withAlpha(Colors.accent, 0.3)
            border.width: 1
            visible: CalendarService.lastError !== ""
            Text {
                id: errLabel
                anchors.centerIn: parent
                width: parent.width - UIScale.spacingMd * 2
                text: root.errText(CalendarService.lastError)
                color: Colors.accent
                font.pixelSize: UIScale.fontSmall
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
            }
        }

        CalendarMiniGrid {
            id: miniGrid
            Layout.fillWidth: true
            onSelectedDateChanged: {
                var ws = root._weekStart;
                if (!ws)
                    return;
                if (miniGrid.viewYear !== ws.getFullYear() || miniGrid.viewMonth !== ws.getMonth()) {
                    miniGrid.viewYear = ws.getFullYear();
                    miniGrid.viewMonth = ws.getMonth();
                }
            }
        }

        Divider {
            Layout.topMargin: UIScale.spacingXs
        }

        // Week nav bar
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: UIScale.panelPad
            Layout.rightMargin: UIScale.panelPad
            Layout.topMargin: UIScale.spacingXs
            Layout.bottomMargin: UIScale.spacingXs
            spacing: UIScale.spacingXs

            Rectangle {
                implicitWidth: Math.round(28 * UIScale.value)
                implicitHeight: Math.round(28 * UIScale.value)
                radius: UIScale.radiusSm
                color: wkPrevHov.hovered ? Colors.withAlpha(Colors.text, 0.1) : "transparent"
                Behavior on color {
                    ColorAnimation {
                        duration: Anim.fast
                    }
                }
                Text {
                    anchors.centerIn: parent
                    text: ""
                    font.family: "Material Icons"
                    font.pixelSize: Math.round(16 * UIScale.value)
                    color: Colors.textDim
                }
                HoverHandler {
                    id: wkPrevHov
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.prevWeek()
                }
            }
            Text {
                text: root.fmtWeekRange()
                color: Colors.text
                font.pixelSize: UIScale.fontSmall
                font.weight: Font.DemiBold
            }
            Rectangle {
                implicitWidth: Math.round(28 * UIScale.value)
                implicitHeight: Math.round(28 * UIScale.value)
                radius: UIScale.radiusSm
                color: wkNextHov.hovered ? Colors.withAlpha(Colors.text, 0.1) : "transparent"
                Behavior on color {
                    ColorAnimation {
                        duration: Anim.fast
                    }
                }
                Text {
                    anchors.centerIn: parent
                    text: ""
                    font.family: "Material Icons"
                    font.pixelSize: Math.round(16 * UIScale.value)
                    color: Colors.textDim
                }
                HoverHandler {
                    id: wkNextHov
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.nextWeek()
                }
            }

            Item {
                Layout.fillWidth: true
            }

            Rectangle {
                implicitHeight: Math.round(22 * UIScale.value)
                implicitWidth: thisWeekLabel.implicitWidth + Math.round(12 * UIScale.value)
                radius: height / 2
                color: thisWeekHov.hovered ? Colors.withAlpha(Colors.text, 0.1) : Colors.surfaceHigh
                Behavior on color {
                    ColorAnimation {
                        duration: Anim.fast
                    }
                }
                Text {
                    id: thisWeekLabel
                    anchors.centerIn: parent
                    text: I18n.t("calendar.thisWeek")
                    color: Colors.textDim
                    font.pixelSize: UIScale.fontTiny
                }
                HoverHandler {
                    id: thisWeekHov
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.goToThisWeek()
                }
            }

            Rectangle {
                implicitWidth: Math.round(28 * UIScale.value)
                implicitHeight: Math.round(28 * UIScale.value)
                radius: UIScale.radiusSm
                color: syncHov.hovered ? Colors.withAlpha(Colors.text, 0.1) : "transparent"
                Behavior on color {
                    ColorAnimation {
                        duration: Anim.fast
                    }
                }
                Text {
                    anchors.centerIn: parent
                    text: ""
                    font.family: "Material Icons"
                    font.pixelSize: Math.round(16 * UIScale.value)
                    color: (CalendarService.syncing || CalendarService.loading) ? Colors.accent : Colors.textDim
                    Behavior on color {
                        ColorAnimation {
                            duration: Anim.fast
                        }
                    }
                }
                HoverHandler {
                    id: syncHov
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (!CalendarService.syncing && !CalendarService.loading)
                            CalendarService.syncAndFetch();
                    }
                }
            }
            Rectangle {
                implicitWidth: Math.round(28 * UIScale.value)
                implicitHeight: Math.round(28 * UIScale.value)
                radius: UIScale.radiusSm
                color: root._creating ? Colors.withAlpha(Colors.accent, 0.2) : addHov.hovered ? Colors.withAlpha(Colors.text, 0.1) : "transparent"
                Behavior on color {
                    ColorAnimation {
                        duration: Anim.fast
                    }
                }
                Text {
                    anchors.centerIn: parent
                    text: root._creating ? "" : ""
                    font.family: "Material Icons"
                    font.pixelSize: Math.round(16 * UIScale.value)
                    color: root._creating ? Colors.accent : Colors.textDim
                    Behavior on color {
                        ColorAnimation {
                            duration: Anim.fast
                        }
                    }
                }
                HoverHandler {
                    id: addHov
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root._creating = !root._creating;
                        if (root._creating) {
                            root._formEvent = null;
                            root._newAllDay = false;
                            root._newRepeat = "none";
                            root._newCal = CalendarService.availableCalendars.length > 0 ? CalendarService.availableCalendars[0] : "personal";
                            root._newAttendees = [];
                            root._newReminderMin = null;
                            sumField.text = "";
                            startField.text = "09:00";
                            endField.text = "10:00";
                            locField.text = "";
                            urlField.text = "";
                            descField.text = "";
                        }
                    }
                }
            }
        }

        // Create / edit form
        ColumnLayout {
            visible: root._creating
            Layout.fillWidth: true
            Layout.leftMargin: UIScale.panelPad
            Layout.rightMargin: UIScale.panelPad
            spacing: UIScale.spacingXs

            StyledTextInput {
                id: sumField
                placeholder: I18n.t("calendar.eventTitlePlaceholder")
            }

            RowLayout {
                spacing: UIScale.spacingMd
                Text {
                    text: I18n.t("calendar.allDay")
                    color: Colors.textDim
                    font.pixelSize: UIScale.fontSmall
                }
                Item {
                    Layout.fillWidth: true
                }
                ToggleSwitch {
                    checked: root._newAllDay
                    onToggled: root._newAllDay = !root._newAllDay
                }
            }

            RowLayout {
                visible: !root._newAllDay
                spacing: UIScale.spacingXs
                Text {
                    text: I18n.t("calendar.from")
                    color: Colors.textDim
                    font.pixelSize: UIScale.fontSmall
                }
                StyledTextInput {
                    id: startField
                    text: "09:00"
                }
                Text {
                    text: I18n.t("calendar.to")
                    color: Colors.textDim
                    font.pixelSize: UIScale.fontSmall
                }
                StyledTextInput {
                    id: endField
                    text: "10:00"
                }
            }

            RowLayout {
                spacing: UIScale.spacingXs
                Text {
                    text: I18n.t("calendar.repeats")
                    color: Colors.textDim
                    font.pixelSize: UIScale.fontSmall
                }
                Item {
                    Layout.fillWidth: true
                }
                Repeater {
                    model: ["none", "daily", "weekly", "monthly", "yearly"]
                    delegate: Rectangle {
                        id: repPill
                        required property string modelData
                        implicitHeight: Math.round(22 * UIScale.value)
                        implicitWidth: repPillLabel.implicitWidth + Math.round(12 * UIScale.value)
                        radius: height / 2
                        color: root._newRepeat === repPill.modelData ? Colors.withAlpha(Colors.accent, 0.25) : repPillHov.hovered ? Colors.withAlpha(Colors.text, 0.08) : Colors.surfaceHigh
                        border.color: root._newRepeat === repPill.modelData ? Colors.withAlpha(Colors.accent, 0.6) : "transparent"
                        border.width: 1
                        Behavior on color {
                            ColorAnimation {
                                duration: Anim.fast
                            }
                        }
                        Text {
                            id: repPillLabel
                            anchors.centerIn: parent
                            text: I18n.t("calendar.repeat_" + repPill.modelData)
                            color: root._newRepeat === repPill.modelData ? Colors.accent : Colors.textDim
                            font.pixelSize: UIScale.fontTiny
                            Behavior on color {
                                ColorAnimation {
                                    duration: Anim.fast
                                }
                            }
                        }
                        HoverHandler {
                            id: repPillHov
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root._newRepeat = repPill.modelData
                        }
                    }
                }
            }

            Text {
                visible: root._formEvent !== null && root._formEvent.recurring
                text: I18n.t("calendar.appliesToAllOccurrences")
                color: Colors.muted
                font.pixelSize: UIScale.fontTiny
                Layout.alignment: Qt.AlignHCenter
            }

            StyledTextInput {
                id: locField
                placeholder: I18n.t("calendar.locationPlaceholder")
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: Math.max(Math.round(64 * UIScale.value), descField.implicitHeight + Math.round(16 * UIScale.value))
                radius: UIScale.radiusSm
                color: Colors.surfaceHigh
                border.color: descField.activeFocus ? Colors.withAlpha(Colors.accent, 0.5) : "transparent"
                border.width: 1
                Behavior on border.color {
                    ColorAnimation {
                        duration: Anim.fast
                    }
                }
                TextEdit {
                    id: descField
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        bottom: parent.bottom
                        margins: Math.round(8 * UIScale.value)
                    }
                    color: Colors.text
                    font.pixelSize: UIScale.fontSmall
                    wrapMode: TextEdit.Wrap
                    selectByMouse: true
                    Text {
                        anchors.fill: parent
                        text: I18n.t("calendar.notes")
                        color: Colors.muted
                        font.pixelSize: UIScale.fontSmall
                        visible: descField.text.length === 0 && !descField.activeFocus
                    }
                }
            }

            StyledTextInput {
                id: urlField
                placeholder: I18n.t("calendar.meetingUrlPlaceholder")
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: UIScale.spacingXs
                RowLayout {
                    Layout.fillWidth: true
                    spacing: UIScale.spacingXs
                    StyledTextInput {
                        id: attField
                        placeholder: I18n.t("calendar.addAttendeeEmailPlaceholder")
                        onAccepted: {
                            var email = attField.text.trim();
                            if (email.length > 0) {
                                var l = root._newAttendees.slice();
                                l.push({
                                    email: email,
                                    name: ""
                                });
                                root._newAttendees = l;
                                attField.text = "";
                            }
                        }
                    }
                    Rectangle {
                        implicitWidth: Math.round(32 * UIScale.value)
                        implicitHeight: Math.round(32 * UIScale.value)
                        radius: UIScale.radiusSm
                        color: addAttHov.hovered ? Colors.withAlpha(Colors.accent, 0.25) : Colors.withAlpha(Colors.accent, 0.12)
                        Behavior on color {
                            ColorAnimation {
                                duration: Anim.fast
                            }
                        }
                        Text {
                            anchors.centerIn: parent
                            text: "+"
                            color: Colors.accent
                            font.pixelSize: UIScale.fontBody
                            font.weight: Font.DemiBold
                        }
                        HoverHandler {
                            id: addAttHov
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                var email = attField.text.trim();
                                if (email.length > 0) {
                                    var l = root._newAttendees.slice();
                                    l.push({
                                        email: email,
                                        name: ""
                                    });
                                    root._newAttendees = l;
                                    attField.text = "";
                                }
                            }
                        }
                    }
                }
                Flow {
                    Layout.fillWidth: true
                    spacing: Math.round(4 * UIScale.value)
                    visible: root._newAttendees.length > 0
                    Repeater {
                        model: root._newAttendees
                        delegate: Rectangle {
                            id: attChip
                            required property var modelData
                            required property int index
                            implicitHeight: Math.round(22 * UIScale.value)
                            implicitWidth: attChipRow.implicitWidth + Math.round(12 * UIScale.value)
                            radius: height / 2
                            color: Colors.surfaceHigh
                            RowLayout {
                                id: attChipRow
                                anchors.centerIn: parent
                                spacing: Math.round(4 * UIScale.value)
                                Text {
                                    text: attChip.modelData.email
                                    color: Colors.textDim
                                    font.pixelSize: UIScale.fontTiny
                                }
                                Text {
                                    text: "×"
                                    color: Colors.muted
                                    font.pixelSize: UIScale.fontTiny
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            var l = root._newAttendees.slice();
                                            l.splice(attChip.index, 1);
                                            root._newAttendees = l;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            RowLayout {
                spacing: UIScale.spacingXs
                Text {
                    text: I18n.t("calendar.reminder")
                    color: Colors.textDim
                    font.pixelSize: UIScale.fontSmall
                }
                Item {
                    Layout.fillWidth: true
                }
                Repeater {
                    model: root._reminderOptions
                    delegate: Rectangle {
                        id: remPill
                        required property var modelData
                        implicitHeight: Math.round(22 * UIScale.value)
                        implicitWidth: remPillLabel.implicitWidth + Math.round(12 * UIScale.value)
                        radius: height / 2
                        color: root._newReminderMin === remPill.modelData.value ? Colors.withAlpha(Colors.accent, 0.25) : remPillHov.hovered ? Colors.withAlpha(Colors.text, 0.08) : Colors.surfaceHigh
                        border.color: root._newReminderMin === remPill.modelData.value ? Colors.withAlpha(Colors.accent, 0.6) : "transparent"
                        border.width: 1
                        Behavior on color {
                            ColorAnimation {
                                duration: Anim.fast
                            }
                        }
                        Text {
                            id: remPillLabel
                            anchors.centerIn: parent
                            text: remPill.modelData.label
                            color: root._newReminderMin === remPill.modelData.value ? Colors.accent : Colors.textDim
                            font.pixelSize: UIScale.fontTiny
                            Behavior on color {
                                ColorAnimation {
                                    duration: Anim.fast
                                }
                            }
                        }
                        HoverHandler {
                            id: remPillHov
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root._newReminderMin = remPill.modelData.value
                        }
                    }
                }
            }

            RowLayout {
                visible: CalendarService.availableCalendars.length > 1 && root._formEvent === null
                spacing: UIScale.spacingXs
                Text {
                    text: I18n.t("calendar.in")
                    color: Colors.textDim
                    font.pixelSize: UIScale.fontSmall
                }
                Repeater {
                    model: CalendarService.availableCalendars
                    delegate: Rectangle {
                        id: calPill
                        required property string modelData
                        implicitHeight: Math.round(24 * UIScale.value)
                        implicitWidth: calPillLabel.implicitWidth + Math.round(16 * UIScale.value)
                        radius: height / 2
                        color: root._newCal === calPill.modelData ? Colors.withAlpha(Colors.accent, 0.25) : calPillHov.hovered ? Colors.withAlpha(Colors.text, 0.1) : Colors.surfaceHigh
                        border.color: root._newCal === calPill.modelData ? Colors.withAlpha(Colors.accent, 0.6) : "transparent"
                        border.width: 1
                        Behavior on color {
                            ColorAnimation {
                                duration: Anim.fast
                            }
                        }
                        Text {
                            id: calPillLabel
                            anchors.centerIn: parent
                            text: calPill.modelData
                            color: root._newCal === calPill.modelData ? Colors.accent : Colors.textDim
                            font.pixelSize: UIScale.fontTiny
                            Behavior on color {
                                ColorAnimation {
                                    duration: Anim.fast
                                }
                            }
                        }
                        HoverHandler {
                            id: calPillHov
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root._newCal = calPill.modelData
                        }
                    }
                }
            }

            RowLayout {
                Layout.topMargin: UIScale.spacingXs
                spacing: UIScale.spacingMd
                Item {
                    Layout.fillWidth: true
                }
                Rectangle {
                    implicitWidth: Math.round(72 * UIScale.value)
                    implicitHeight: Math.round(30 * UIScale.value)
                    radius: UIScale.radiusSm
                    color: cancelHov.hovered ? Colors.withAlpha(Colors.text, 0.1) : "transparent"
                    Behavior on color {
                        ColorAnimation {
                            duration: Anim.fast
                        }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: I18n.t("common.cancel")
                        color: Colors.textDim
                        font.pixelSize: UIScale.fontSmall
                    }
                    HoverHandler {
                        id: cancelHov
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root._creating = false;
                            root._formEvent = null;
                        }
                    }
                }
                Rectangle {
                    implicitWidth: Math.round(72 * UIScale.value)
                    implicitHeight: Math.round(30 * UIScale.value)
                    radius: UIScale.radiusSm
                    color: (CalendarService.writing || sumField.text.trim().length === 0) ? Colors.withAlpha(Colors.accent, 0.3) : createBtnHov.hovered ? Colors.accent : Colors.withAlpha(Colors.accent, 0.8)
                    Behavior on color {
                        ColorAnimation {
                            duration: Anim.fast
                        }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: CalendarService.writing ? "Saving..." : root._formEvent !== null ? "Save" : "Create"
                        color: Colors.onAccent
                        font.pixelSize: UIScale.fontSmall
                        font.weight: Font.DemiBold
                    }
                    HoverHandler {
                        id: createBtnHov
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: sumField.text.trim().length > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                        enabled: !CalendarService.writing && sumField.text.trim().length > 0
                        onClicked: {
                            var y = miniGrid.selectedDate.getFullYear();
                            var mo = String(miniGrid.selectedDate.getMonth() + 1).padStart(2, "0");
                            var d = String(miniGrid.selectedDate.getDate()).padStart(2, "0");
                            var ev = {
                                summary: sumField.text.trim(),
                                date: y + "-" + mo + "-" + d,
                                startTime: startField.text,
                                endTime: endField.text,
                                allDay: root._newAllDay,
                                repeat: root._newRepeat,
                                location: locField.text.trim(),
                                description: descField.text.trim(),
                                url: urlField.text.trim(),
                                attendees: root._newAttendees,
                                reminderMin: root._newReminderMin
                            };
                            if (root._formEvent !== null) {
                                ev.uid = root._formEvent.uid;
                                CalendarService.editEvent(root._formEvent.file, ev);
                            } else {
                                CalendarService.createEvent(ev, root._newCal);
                            }
                            root._creating = false;
                            root._formEvent = null;
                        }
                    }
                }
            }
        }

        // Day column headers
        Item {
            Layout.fillWidth: true
            implicitHeight: Math.round(44 * UIScale.value)

            // Left spacer matching hour label width
            Item {
                x: 0
                y: 0
                width: root._hourLabelW
                height: parent.height
            }

            Repeater {
                model: root._weekDays
                delegate: Item {
                    id: dayHdrCell
                    required property var modelData
                    required property int index
                    x: root._hourLabelW + dayHdrCell.index * ((parent.width - root._hourLabelW) / 7)
                    width: (parent.width - root._hourLabelW) / 7
                    height: parent.height

                    readonly property bool isToday: {
                        var t = root._today;
                        return dayHdrCell.modelData.getFullYear() === t.getFullYear() && dayHdrCell.modelData.getMonth() === t.getMonth() && dayHdrCell.modelData.getDate() === t.getDate();
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: Math.round(1 * UIScale.value)
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root._shortDayNames[dayHdrCell.modelData.getDay()]
                            color: dayHdrCell.isToday ? Colors.accent : Colors.muted
                            font.pixelSize: UIScale.fontTiny
                            font.weight: Font.Bold
                            font.letterSpacing: 0.5
                        }
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: Math.round(26 * UIScale.value)
                            height: Math.round(26 * UIScale.value)
                            radius: height / 2
                            color: dayHdrCell.isToday ? Colors.accent : "transparent"
                            Text {
                                anchors.centerIn: parent
                                text: dayHdrCell.modelData.getDate()
                                color: dayHdrCell.isToday ? Colors.onAccent : Colors.text
                                font.pixelSize: UIScale.fontSmall
                                font.weight: Font.DemiBold
                            }
                        }
                    }
                }
            }
        }

        // Thin divider above time grid
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Colors.withAlpha(Colors.text, 0.08)
        }

        // Time grid
        Flickable {
            id: timeGridFlick
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: 24 * root._hourPx
            clip: true
            flickableDirection: Flickable.VerticalFlick

            Component.onCompleted: {
                var h = Math.max(0, root._now.getHours() - 1);
                contentY = Math.min(h * root._hourPx, contentHeight - height);
            }

            Item {
                id: tgContent
                width: timeGridFlick.width
                height: 24 * root._hourPx

                // Hour rows
                Repeater {
                    model: 24
                    delegate: Item {
                        id: hrRow
                        required property int index
                        x: 0
                        y: hrRow.index * root._hourPx
                        width: tgContent.width
                        height: root._hourPx

                        Text {
                            x: 0
                            y: -implicitHeight / 2
                            width: root._hourLabelW - Math.round(6 * UIScale.value)
                            horizontalAlignment: Text.AlignRight
                            text: {
                                if (hrRow.index === 0)
                                    return "";
                                if (hrRow.index < 12)
                                    return hrRow.index + " AM";
                                if (hrRow.index === 12)
                                    return "12 PM";
                                return (hrRow.index - 12) + " PM";
                            }
                            color: Colors.muted
                            font.pixelSize: UIScale.fontTiny
                        }
                        Rectangle {
                            x: root._hourLabelW
                            y: 0
                            width: parent.width - root._hourLabelW
                            height: 1
                            color: Colors.withAlpha(Colors.text, 0.07)
                        }
                        Rectangle {
                            x: root._hourLabelW
                            y: root._hourPx / 2
                            width: parent.width - root._hourLabelW
                            height: 1
                            color: Colors.withAlpha(Colors.text, 0.03)
                        }
                    }
                }

                // Vertical day separators
                Repeater {
                    model: 6
                    delegate: Rectangle {
                        id: daySep
                        required property int index
                        readonly property real dayColW: (tgContent.width - root._hourLabelW) / 7
                        x: root._hourLabelW + (daySep.index + 1) * dayColW
                        y: 0
                        width: 1
                        height: tgContent.height
                        color: Colors.withAlpha(Colors.text, 0.07)
                    }
                }

                // Now indicator
                Item {
                    visible: root._nowTodayCol >= 0
                    readonly property real dayColW: (tgContent.width - root._hourLabelW) / 7
                    x: root._hourLabelW + root._nowTodayCol * dayColW
                    y: root._nowY
                    width: dayColW
                    height: 2
                    Rectangle {
                        width: parent.width
                        height: 2
                        color: Colors.accent
                        radius: 1
                    }
                    Rectangle {
                        x: -Math.round(4 * UIScale.value)
                        y: -Math.round(3 * UIScale.value)
                        width: Math.round(8 * UIScale.value)
                        height: Math.round(8 * UIScale.value)
                        radius: height / 2
                        color: Colors.accent
                    }
                }

                // Timed events
                Repeater {
                    model: root._timedWeekEvents
                    delegate: Rectangle {
                        id: evBlock
                        required property var modelData
                        readonly property int dayCol: root.eventDayCol(modelData)
                        readonly property real dayColW: (tgContent.width - root._hourLabelW) / 7
                        visible: dayCol >= 0 && dayCol < 7
                        x: root._hourLabelW + dayCol * dayColW + Math.round(2 * UIScale.value)
                        y: root.eventY(modelData)
                        width: dayColW - Math.round(4 * UIScale.value)
                        height: root.eventH(modelData)
                        radius: UIScale.radiusSm
                        color: Colors.withAlpha(Colors.accent, 0.18)
                        border.color: Colors.withAlpha(Colors.accent, 0.55)
                        border.width: 1
                        clip: true

                        ColumnLayout {
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                                margins: Math.round(3 * UIScale.value)
                            }
                            spacing: 0
                            Text {
                                Layout.fillWidth: true
                                text: evBlock.modelData.summary
                                color: Colors.text
                                font.pixelSize: UIScale.fontTiny
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }
                            Text {
                                visible: evBlock.height > Math.round(32 * UIScale.value)
                                Layout.fillWidth: true
                                text: root.fmtTime(evBlock.modelData)
                                color: Colors.textDim
                                font.pixelSize: UIScale.fontTiny
                                elide: Text.ElideRight
                            }
                        }

                        HoverHandler {
                            id: evHov
                        }
                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            color: evHov.hovered ? Colors.withAlpha(Colors.text, 0.07) : "transparent"
                            Behavior on color {
                                ColorAnimation {
                                    duration: Anim.fast
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root._selectedEvent && root._selectedEvent.uid === evBlock.modelData.uid) {
                                    root._selectedEvent = null;
                                } else {
                                    root._selectedEvent = evBlock.modelData;
                                    var mapped = evBlock.mapToItem(root, evBlock.width, 0);
                                    root._popupX = mapped.x;
                                    root._popupY = mapped.y;
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Absorber
    MouseArea {
        z: 9
        anchors.fill: parent
        visible: root._selectedEvent !== null
        onClicked: root._selectedEvent = null
    }

    // Event popup
    Rectangle {
        id: eventPopup
        z: 10
        visible: root._selectedEvent !== null
        readonly property real pad: UIScale.panelPad
        width: Math.round(300 * UIScale.value)
        implicitHeight: popupCol.implicitHeight + pad * 2
        x: {
            var ideal = root._popupX + Math.round(8 * UIScale.value);
            return Math.max(pad, Math.min(ideal, root.width - width - pad));
        }
        y: Math.max(pad, Math.min(root._popupY, root.height - implicitHeight - pad))
        radius: UIScale.radiusMd
        color: Colors.surface
        border.color: Colors.withAlpha(Colors.text, 0.12)
        border.width: 1

        ColumnLayout {
            id: popupCol
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: eventPopup.pad
            }
            spacing: UIScale.spacingMd

            // Header row
            RowLayout {
                Layout.fillWidth: true
                spacing: UIScale.spacingXs
                Rectangle {
                    implicitWidth: Math.round(4 * UIScale.value)
                    implicitHeight: Math.round(18 * UIScale.value)
                    radius: 2
                    color: Colors.accent
                    Layout.alignment: Qt.AlignTop
                    Layout.topMargin: Math.round(4 * UIScale.value)
                }
                Text {
                    Layout.fillWidth: true
                    text: root._selectedEvent ? root._selectedEvent.summary : ""
                    color: Colors.text
                    font.pixelSize: UIScale.fontSubhead
                    font.weight: Font.DemiBold
                    wrapMode: Text.WordWrap
                }
                Rectangle {
                    implicitWidth: Math.round(26 * UIScale.value)
                    implicitHeight: Math.round(26 * UIScale.value)
                    radius: UIScale.radiusSm
                    Layout.alignment: Qt.AlignTop
                    color: popupEditHov.hovered ? Colors.withAlpha(Colors.text, 0.1) : "transparent"
                    Behavior on color {
                        ColorAnimation {
                            duration: Anim.fast
                        }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: ""
                        font.family: "Material Icons"
                        font.pixelSize: Math.round(14 * UIScale.value)
                        color: Colors.textDim
                    }
                    HoverHandler {
                        id: popupEditHov
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.openEditForm(root._selectedEvent)
                    }
                }
                Rectangle {
                    implicitWidth: Math.round(26 * UIScale.value)
                    implicitHeight: Math.round(26 * UIScale.value)
                    radius: UIScale.radiusSm
                    Layout.alignment: Qt.AlignTop
                    color: popupCloseHov.hovered ? Colors.withAlpha(Colors.text, 0.1) : "transparent"
                    Behavior on color {
                        ColorAnimation {
                            duration: Anim.fast
                        }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: ""
                        font.family: "Material Icons"
                        font.pixelSize: Math.round(14 * UIScale.value)
                        color: Colors.textDim
                    }
                    HoverHandler {
                        id: popupCloseHov
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root._selectedEvent = null
                    }
                }
            }

            Divider {}

            // Time
            RowLayout {
                Layout.fillWidth: true
                spacing: UIScale.spacingMd
                Text {
                    text: ""
                    font.family: "Material Icons"
                    font.pixelSize: UIScale.fontBody
                    color: Colors.muted
                    Layout.alignment: Qt.AlignTop
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Text {
                        text: root._selectedEvent ? root.fmtTimeRange(root._selectedEvent) : ""
                        color: Colors.text
                        font.pixelSize: UIScale.fontSmall
                    }
                    Text {
                        visible: root._selectedEvent ? root._selectedEvent.recurring : false
                        text: root._selectedEvent ? (root._selectedEvent.repeat.charAt(0).toUpperCase() + root._selectedEvent.repeat.slice(1) + " repeat") : ""
                        color: Colors.muted
                        font.pixelSize: UIScale.fontTiny
                    }
                }
            }

            // Location
            RowLayout {
                Layout.fillWidth: true
                spacing: UIScale.spacingMd
                visible: root._selectedEvent ? (root._selectedEvent.location || "") !== "" : false
                Text {
                    text: ""
                    font.family: "Material Icons"
                    font.pixelSize: UIScale.fontBody
                    color: Colors.muted
                    Layout.alignment: Qt.AlignTop
                }
                Text {
                    Layout.fillWidth: true
                    text: root._selectedEvent ? (root._selectedEvent.location || "") : ""
                    color: Colors.text
                    font.pixelSize: UIScale.fontSmall
                    wrapMode: Text.Wrap
                }
            }

            // URL
            RowLayout {
                Layout.fillWidth: true
                spacing: UIScale.spacingMd
                visible: root._selectedEvent ? (root._selectedEvent.url || "") !== "" : false
                Text {
                    text: ""
                    font.family: "Material Icons"
                    font.pixelSize: UIScale.fontBody
                    color: Colors.muted
                }
                Text {
                    Layout.fillWidth: true
                    text: root._selectedEvent ? (root._selectedEvent.url || "") : ""
                    color: Colors.accent
                    font.pixelSize: UIScale.fontSmall
                    elide: Text.ElideRight
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (root._selectedEvent)
                            Qt.openUrlExternally(root._selectedEvent.url)
                    }
                }
            }

            // Organizer
            RowLayout {
                Layout.fillWidth: true
                spacing: UIScale.spacingMd
                visible: root._selectedEvent ? !!root._selectedEvent.organizer : false
                Text {
                    text: ""
                    font.family: "Material Icons"
                    font.pixelSize: UIScale.fontBody
                    color: Colors.muted
                    Layout.alignment: Qt.AlignTop
                }
                Column {
                    Layout.fillWidth: true
                    spacing: 0
                    Text {
                        text: root._selectedEvent && root._selectedEvent.organizer ? (root._selectedEvent.organizer.name || root._selectedEvent.organizer.email) : ""
                        color: Colors.text
                        font.pixelSize: UIScale.fontSmall
                    }
                    Text {
                        visible: root._selectedEvent && root._selectedEvent.organizer && root._selectedEvent.organizer.name !== ""
                        text: root._selectedEvent && root._selectedEvent.organizer ? root._selectedEvent.organizer.email : ""
                        color: Colors.muted
                        font.pixelSize: UIScale.fontTiny
                    }
                }
            }

            // Attendees
            ColumnLayout {
                Layout.fillWidth: true
                spacing: UIScale.spacingXs
                visible: root._selectedEvent ? (root._selectedEvent.attendees && root._selectedEvent.attendees.length > 0) : false

                RowLayout {
                    spacing: UIScale.spacingMd
                    Text {
                        text: ""
                        font.family: "Material Icons"
                        font.pixelSize: UIScale.fontBody
                        color: Colors.muted
                    }
                    Text {
                        text: root._selectedEvent && root._selectedEvent.attendees ? root._selectedEvent.attendees.length + " attendee" + (root._selectedEvent.attendees.length > 1 ? "s" : "") : ""
                        color: Colors.text
                        font.pixelSize: UIScale.fontSmall
                    }
                }

                Repeater {
                    model: root._selectedEvent ? root._selectedEvent.attendees : []
                    delegate: RowLayout {
                        id: attRow
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.leftMargin: Math.round(32 * UIScale.value)
                        spacing: UIScale.spacingXs
                        Rectangle {
                            implicitWidth: Math.round(7 * UIScale.value)
                            implicitHeight: Math.round(7 * UIScale.value)
                            radius: height / 2
                            color: attRow.modelData.status === "ACCEPTED" ? Colors.accent : attRow.modelData.status === "DECLINED" ? Colors.withAlpha(Colors.text, 0.25) : Colors.withAlpha(Colors.accent, 0.4)
                        }
                        Text {
                            Layout.fillWidth: true
                            text: attRow.modelData.name || attRow.modelData.email
                            color: Colors.textDim
                            font.pixelSize: UIScale.fontTiny
                            elide: Text.ElideRight
                        }
                        Text {
                            visible: attRow.modelData.status !== "NEEDS-ACTION"
                            text: attRow.modelData.status === "ACCEPTED" ? "✓" : attRow.modelData.status === "DECLINED" ? "✗" : "?"
                            color: Colors.muted
                            font.pixelSize: UIScale.fontTiny
                        }
                    }
                }
            }

            // Reminder
            RowLayout {
                Layout.fillWidth: true
                spacing: UIScale.spacingMd
                visible: root._selectedEvent ? (root._selectedEvent.reminderMin !== null && root._selectedEvent.reminderMin !== undefined) : false
                Text {
                    text: ""
                    font.family: "Material Icons"
                    font.pixelSize: UIScale.fontBody
                    color: Colors.muted
                }
                Text {
                    text: root._selectedEvent ? root.fmtReminderLabel(root._selectedEvent.reminderMin) : ""
                    color: Colors.text
                    font.pixelSize: UIScale.fontSmall
                }
            }

            // Description
            Text {
                Layout.fillWidth: true
                visible: root._selectedEvent ? (root._selectedEvent.description || "") !== "" : false
                text: root._selectedEvent ? (root._selectedEvent.description || "") : ""
                color: Colors.textDim
                font.pixelSize: UIScale.fontSmall
                wrapMode: Text.Wrap
            }

            // Delete
            RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: 0
                Item {
                    Layout.fillWidth: true
                }
                Rectangle {
                    implicitWidth: Math.round(72 * UIScale.value)
                    implicitHeight: Math.round(28 * UIScale.value)
                    radius: UIScale.radiusSm
                    color: popupDelHov.hovered ? Colors.withAlpha(Colors.accent, 0.2) : Colors.withAlpha(Colors.accent, 0.08)
                    Behavior on color {
                        ColorAnimation {
                            duration: Anim.fast
                        }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: I18n.t("calendar.delete")
                        color: Colors.accent
                        font.pixelSize: UIScale.fontSmall
                    }
                    HoverHandler {
                        id: popupDelHov
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var f = root._selectedEvent.file;
                            root._selectedEvent = null;
                            CalendarService.deleteEvent(f);
                        }
                    }
                }
            }
        }
    }
}
