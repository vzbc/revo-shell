pragma ComponentBehavior: Bound

import QtQuick
import "./"
import "../../"

// Large desktop clock skin.
// timeEngine drives HH:MM; dateEngine drives [d1, d2, " ", m1...mN]
// with day at fixed indices 0-1 and month at 3+, so each sub-row
// renders only its slice - date gets typed when it changes at midnight.
Item {
    id: root

    readonly property real _digitPx: Math.round(80 * UIScale.value)
    readonly property real _dotR: Math.round(6 * UIScale.value)
    readonly property real _gap: Math.round(UIScale.spacingXs)
    readonly property real _divGap: Math.round(UIScale.spacingMd)

    readonly property var _monthNames: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]

    readonly property real _naturalTimeW: {
        if (ClockSettings.colonMode === "hidden")
            return 4 * Math.round(root._digitPx * 0.62) + 3 * root._gap;
        return 4 * Math.round(root._digitPx * 0.62) + Math.round(root._dotR * 5) + 4 * root._gap;
    }

    implicitWidth: {
        var dateW = (ClockSettings.widthMode === "fixed" && root._naturalDateColW > 0) ? root._naturalDateColW : dateCol.implicitWidth;
        return digitsRow.width + _divGap + divider.width + _divGap + dateW;
    }
    implicitHeight: root._digitPx

    TypewriterEngine {
        id: timeEngine
    }
    TypewriterEngine {
        id: dateEngine
    }

    property var _date: new Date()
    property bool _dayChangeInProgress: false
    property bool _simulating: false
    property bool _colonOn: true
    property real _naturalDateColW: 0

    Timer {
        running: true
        repeat: true
        interval: 1000
        onTriggered: {
            root._colonOn = !root._colonOn;
            if (root._simulating)
                return;
            if (!root._dayChangeInProgress)
                root._naturalDateColW = dateCol.implicitWidth;
            var now = new Date();
            var minuteChanged = now.getMinutes() !== root._date.getMinutes() || now.getHours() !== root._date.getHours();
            var dayChanged = now.getDate() !== root._date.getDate() || now.getMonth() !== root._date.getMonth();
            if (!minuteChanged && !dayChanged) {
                root._date = now;
                return;
            }
            root._date = now;
            if (dayChanged) {
                root._dayChangeInProgress = true;
                dateEngine.animateTo(root._toDateChars(now), true, true);
            } else {
                timeEngine.animateTo(root._toTimeChars(now));
            }
        }
    }

    // Step 1 -> 2: date deleted, now delete time
    // Step 4: date typed last, sequence done
    Connections {
        target: dateEngine
        function onDeletePhaseComplete() {
            if (root._dayChangeInProgress)
                timeEngine.animateTo(root._toTimeChars(root._date), true, true);
        }
        function onTypePhaseComplete() {
            root._dayChangeInProgress = false;
            if (root._simulating) {
                root._simulating = false;
                root._date = new Date();
            }
            root._naturalDateColW = dateCol.implicitWidth;
        }
    }

    // Step 2 -> 3: time deleted, now type time first
    // Step 3 -> 4: time typed, now type date
    Connections {
        target: timeEngine
        function onDeletePhaseComplete() {
            if (root._dayChangeInProgress)
                timeEngine.resumeTyping();
        }
        function onTypePhaseComplete() {
            if (root._dayChangeInProgress)
                dateEngine.resumeTyping();
        }
    }

    function _toTimeChars(date) {
        var h = ClockSettings.use12Hour ? (date.getHours() % 12 || 12) : date.getHours();
        var m = date.getMinutes();
        return [Math.floor(h / 10).toString(), (h % 10).toString(), ":", Math.floor(m / 10).toString(), (m % 10).toString()];
    }

    function _toDateChars(date) {
        var d = date.getDate();
        var month = _monthNames[date.getMonth()];
        var arr = [d >= 10 ? Math.floor(d / 10).toString() : " ", (d % 10).toString(), " "];
        for (var i = 0; i < month.length; i++)
            arr.push(month[i]);
        return arr;
    }

    Component.onCompleted: {
        timeEngine.snapTo(_toTimeChars(new Date()));
        dateEngine.snapTo(_toDateChars(new Date()));
        ClockSettings.use12HourChanged.connect(function () {
            timeEngine.snapTo(root._toTimeChars(root._date));
        });
    }

    function simulateTo(h, m) {
        var d = new Date();
        d.setHours(h);
        d.setMinutes(m);
        _simulating = true;
        timeEngine.animateTo(_toTimeChars(d));
    }

    function simulateDayChange(month, day, h, m) {
        var d = new Date();
        d.setMonth(month);
        d.setDate(day);
        d.setHours(h);
        d.setMinutes(m);
        _date = d;
        _simulating = true;
        _dayChangeInProgress = true;
        dateEngine.animateTo(_toDateChars(d), true, true);
    }

    // Snap to 23:59 the night before, then chain date -> time animation into the new day
    function simulateMidnight(month, day) {
        var target = new Date();
        target.setMonth(month);
        target.setDate(day);
        target.setHours(0);
        target.setMinutes(0);
        var before = new Date(target.getTime() - 60000);  // 23:59 previous day
        timeEngine.snapTo(_toTimeChars(before));
        dateEngine.snapTo(_toDateChars(before));
        _date = target;
        _simulating = true;
        _dayChangeInProgress = true;
        dateEngine.animateTo(_toDateChars(target), true, true);
    }

    // Time digits (left of divider)

    Row {
        id: digitsRow
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: root._gap
        width: ClockSettings.widthMode === "fixed" ? Math.max(implicitWidth, root._naturalTimeW) : implicitWidth

        Repeater {
            model: timeEngine.model
            delegate: DigitSlot {}
        }

        Item {
            visible: timeEngine.cursorVisible
            width: Math.round(root._digitPx * 0.5)
            height: root._digitPx
            Text {
                anchors.centerIn: parent
                text: "_"
                font.pixelSize: root._digitPx
                font.bold: true
                color: timeEngine.cursorOn ? "white" : Qt.rgba(1, 1, 1, 0.12)
            }
        }
    }

    Rectangle {
        id: divider
        anchors.left: digitsRow.right
        anchors.leftMargin: root._divGap
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(1, Math.round(1.5 * UIScale.value))
        height: Math.round(root._digitPx * 0.72)
        color: Qt.rgba(1, 1, 1, 0.35)
    }

    // Date column (right of divider): month on top, day below

    Column {
        id: dateCol
        anchors.left: divider.right
        anchors.leftMargin: root._divGap
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0

        // Month name, dateEngine indices 3+
        Row {
            spacing: 0
            // Height sentinel keeps the row from collapsing during animation
            Text {
                width: 0
                font.pixelSize: UIScale.fontSmall
                text: ""
            }

            Repeater {
                model: dateEngine.model
                delegate: MonthChar {}
            }

            Item {
                visible: dateEngine.cursorVisible && dateEngine.cursor >= 3
                width: _mCur.implicitWidth
                height: _mCur.implicitHeight
                Text {
                    id: _mCur
                    text: "_"
                    font.pixelSize: UIScale.fontSmall
                    font.weight: Font.Bold
                    color: dateEngine.cursorOn ? Qt.rgba(1, 1, 1, 0.8) : Qt.rgba(1, 1, 1, 0.12)
                }
            }
        }

        // Day number, dateEngine indices 0-1
        Row {
            spacing: 0
            Text {
                width: 0
                font.pixelSize: Math.round(36 * UIScale.value)
                text: ""
            }

            Repeater {
                model: dateEngine.model
                delegate: DayChar {}
            }

            Item {
                visible: dateEngine.cursorVisible && dateEngine.cursor < 3
                width: _dCur.implicitWidth
                height: _dCur.implicitHeight
                Text {
                    id: _dCur
                    text: "_"
                    font.pixelSize: Math.round(36 * UIScale.value)
                    font.weight: Font.Bold
                    color: dateEngine.cursorOn ? "white" : Qt.rgba(1, 1, 1, 0.12)
                }
            }
        }
    }

    component DigitSlot: Item {
        required property string ch
        readonly property bool _isColon: ch === ":"
        visible: !_isColon || ClockSettings.colonMode !== "hidden"
        width: _isColon ? Math.round(root._dotR * 5) : Math.round(root._digitPx * 0.62)
        height: root._digitPx

        Text {
            visible: !parent._isColon
            anchors.centerIn: parent
            text: parent.ch
            font.pixelSize: root._digitPx
            font.bold: true
            color: "white"
        }

        Column {
            visible: parent._isColon
            anchors.centerIn: parent
            spacing: Math.round(root._dotR * 2)
            opacity: {
                if (ClockSettings.colonMode === "on")
                    return 0.85;
                if (ClockSettings.colonMode === "off")
                    return 0.18;
                return root._colonOn ? 0.85 : 0.18;
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: Anim.fast
                }
            }
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: root._dotR * 2
                height: root._dotR * 2
                radius: root._dotR
                color: "white"
            }
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: root._dotR * 2
                height: root._dotR * 2
                radius: root._dotR
                color: "white"
            }
        }
    }

    component MonthChar: Item {
        required property string ch
        required property int index
        visible: index >= 3
        implicitWidth: _mT.implicitWidth
        implicitHeight: _mT.implicitHeight

        Text {
            id: _mT
            text: parent.ch
            font.pixelSize: UIScale.fontSmall
            font.weight: Font.Bold
            font.letterSpacing: 2
            color: Qt.rgba(1, 1, 1, 0.8)
        }
    }

    component DayChar: Item {
        required property string ch
        required property int index
        visible: index < 2
        implicitWidth: _dT.implicitWidth
        implicitHeight: _dT.implicitHeight

        Text {
            id: _dT
            text: parent.ch
            font.pixelSize: Math.round(36 * UIScale.value)
            font.weight: Font.Bold
            color: "white"
        }
    }
}
