pragma ComponentBehavior: Bound

import QtQuick
import "./"
import "../../"
import "../bar"

Item {
    id: root

    readonly property real cellH: Math.round(30 * UIScale.value)
    readonly property real cellW: Math.round(14 * UIScale.value)
    readonly property real colonW: Math.round(14 * UIScale.value)
    readonly property real hPad: Math.round(14 * UIScale.value)
    readonly property real vPad: Math.round(5 * UIScale.value)
    readonly property real charGap: Math.round(1 * UIScale.value)

    // "breathe" | "on" | "off" | "hidden"
    property string colonMode: ClockSettings.colonMode
    // "fixed" | "fluid"
    property string widthMode: ClockSettings.widthMode
    property bool _colonOn: true

    property var _date: new Date()
    property bool _altLatch: false

    readonly property real _minContentW: {
        if (colonMode === "hidden")
            return 4 * cellW + 3 * charGap;
        return 4 * cellW + colonW + 4 * charGap;
    }

    readonly property real _dateMinContentW: {
        var n = colonMode === "hidden" ? 13 : 14;
        return n * cellW + (n - 1) * charGap;
    }

    implicitWidth: BarConfig.isVertical ? (2 * cellW + charGap + hPad * 2) : ((widthMode === "fixed" ? Math.max(charsRow.implicitWidth, ClockSettings.showDate ? _dateMinContentW : _minContentW) : charsRow.implicitWidth) + hPad * 2)
    implicitHeight: BarConfig.isVertical ? (2 * cellH + vPad * 3) : (cellH + vPad * 2)

    TypewriterEngine {
        id: engine
    }

    // Clock-specific logic

    // Second tick: colon blink + minute-change detection
    Timer {
        running: true
        repeat: true
        interval: 1000
        onTriggered: {
            root._colonOn = !root._colonOn;
            var now = new Date();
            if (now.getMinutes() === root._date.getMinutes() && now.getHours() === root._date.getHours()) {
                root._date = now;
                return;
            }
            root._date = now;
            var h = now.getHours();
            if (h < 2 || h >= 5)
                root._altLatch = false;
            engine.animateTo(root._resolveTarget(now));
        }
    }

    function _timeChars(h, m) {
        var displayH = ClockSettings.use12Hour ? (h % 12 || 12) : h;
        return [Math.floor(displayH / 10).toString(), (displayH % 10).toString(), ":", Math.floor(m / 10).toString(), (m % 10).toString()];
    }

    function _dateTimeChars(date) {
        var days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
        var day = days[date.getDay()];
        var d = date.getDate();
        var h = ClockSettings.use12Hour ? (date.getHours() % 12 || 12) : date.getHours();
        var m = date.getMinutes();
        var arr = day.split("");
        arr.push(" ");
        arr.push(d >= 10 ? Math.floor(d / 10).toString() : " ");
        arr.push((d % 10).toString());
        arr.push(" ");
        arr.push("/");
        arr.push(" ");
        arr.push(Math.floor(h / 10).toString());
        arr.push((h % 10).toString());
        arr.push(":");
        arr.push(Math.floor(m / 10).toString());
        arr.push((m % 10).toString());
        return arr;
    }

    function _resolveTarget(date) {
        var h = date.getHours();
        if (h >= 2 && h < 5 && !root._altLatch) {
            root._altLatch = true;
            return ["U", " ", "U", "P", " ", "L", "8", "?"];
        }
        if (ClockSettings.showDate && !BarConfig.isVertical)
            return _dateTimeChars(date);
        return _timeChars(h, date.getMinutes());
    }

    Component.onCompleted: {
        ClockSettings.altModeRequested.connect(root.triggerAltMode);
        ClockSettings.showDateChanged.connect(function () {
            engine.animateTo(root._resolveTarget(root._date));
        });
        ClockSettings.use12HourChanged.connect(function () {
            engine.animateTo(root._resolveTarget(root._date));
        });
        engine.snapTo(_resolveTarget(new Date()));
    }

    // Used by ClockPanel test UI
    function snapTo(h, m) {
        var d = new Date();
        d.setHours(h);
        d.setMinutes(m);
        engine.snapTo(ClockSettings.showDate && !BarConfig.isVertical ? _dateTimeChars(d) : _timeChars(h, m));
    }

    function simulateTo(h, m) {
        var d = new Date();
        d.setHours(h);
        d.setMinutes(m);
        engine.animateTo(ClockSettings.showDate && !BarConfig.isVertical ? _dateTimeChars(d) : _timeChars(h, m));
    }

    function triggerAltMode() {
        engine.animateTo(["U", " ", "U", "P", " ", "L", "8", "?"]);
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Colors.bg
        border.color: Colors.withAlpha(Colors.accent, 0.22)
        border.width: 1.5
    }

    // Horizontal layout
    Row {
        id: charsRow
        visible: !BarConfig.isVertical
        anchors.left: parent.left
        anchors.leftMargin: root.hPad
        anchors.verticalCenter: parent.verticalCenter
        spacing: root.charGap

        Repeater {
            model: engine.model
            delegate: SlotItem {}
        }

        Item {
            visible: engine.cursorVisible
            width: root.cellW
            height: root.cellH
            Text {
                anchors.centerIn: parent
                text: "_"
                font.pixelSize: Math.round(21 * UIScale.value)
                font.bold: true
                font.family: "monospace"
                color: engine.cursorOn ? Colors.accent : Colors.withAlpha(Colors.accent, 0.12)
            }
        }
    }

    // Vertical stacked layout (bar on left/right)
    Column {
        visible: BarConfig.isVertical
        anchors.centerIn: parent
        spacing: root.vPad

        // Hours row, model slots 0-1
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: root.charGap

            Repeater {
                model: engine.model
                delegate: Item {
                    required property string ch
                    required property int index
                    visible: index < 2
                    width: root.cellW
                    height: root.cellH
                    Text {
                        anchors.centerIn: parent
                        text: parent.ch
                        font.pixelSize: Math.round(21 * UIScale.value)
                        font.bold: true
                        font.family: "monospace"
                        color: Colors.accent
                    }
                }
            }
            Item {
                visible: engine.animState === 2 && engine.cursor < 2
                width: root.cellW
                height: root.cellH
                Text {
                    anchors.centerIn: parent
                    text: "_"
                    font.pixelSize: Math.round(21 * UIScale.value)
                    font.bold: true
                    font.family: "monospace"
                    color: engine.cursorOn ? Colors.accent : Colors.withAlpha(Colors.accent, 0.12)
                }
            }
        }

        // Minutes row, model slots > 2 (colon at index 2 is skipped)
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: root.charGap

            Repeater {
                model: engine.model
                delegate: Item {
                    required property string ch
                    required property int index
                    visible: index > 2
                    width: root.cellW
                    height: root.cellH
                    Text {
                        anchors.centerIn: parent
                        text: parent.ch
                        font.pixelSize: Math.round(21 * UIScale.value)
                        font.bold: true
                        font.family: "monospace"
                        color: Colors.accent
                    }
                }
            }
            Item {
                visible: engine.animState === 2 && engine.cursor > 2
                width: root.cellW
                height: root.cellH
                Text {
                    anchors.centerIn: parent
                    text: "_"
                    font.pixelSize: Math.round(21 * UIScale.value)
                    font.bold: true
                    font.family: "monospace"
                    color: engine.cursorOn ? Colors.accent : Colors.withAlpha(Colors.accent, 0.12)
                }
            }
        }
    }

    component SlotItem: Item {
        required property string ch

        readonly property bool _isColon: ch === ":"

        visible: !(_isColon && root.colonMode === "hidden")
        width: _isColon ? root.colonW : root.cellW
        height: root.cellH

        Text {
            anchors.centerIn: parent
            text: parent.ch === "/" ? ":" : parent.ch
            font.pixelSize: Math.round(21 * UIScale.value)
            font.bold: true
            font.family: "monospace"
            color: Colors.accent
            opacity: {
                if (!parent._isColon)
                    return 1;
                if (root.colonMode === "on")
                    return 0.85;
                if (root.colonMode === "off")
                    return 0.18;
                return root._colonOn ? 0.85 : 0.18;
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: Anim.fast
                }
            }
        }
    }
}
