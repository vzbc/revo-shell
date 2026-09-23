pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../../"

Item {
    id: root

    readonly property var _monthNames: I18n.t("calendar.monthNames").split("|")
    readonly property var _dayLabels: I18n.t("calendar.miniDayLabels").split("|")
    readonly property var _today: new Date()

    property int viewYear: root._today.getFullYear()
    property int viewMonth: root._today.getMonth()
    property var selectedDate: root._today

    readonly property int _daysInMonth: new Date(root.viewYear, root.viewMonth + 1, 0).getDate()
    readonly property int _firstWeekday: new Date(root.viewYear, root.viewMonth, 1).getDay()

    readonly property var _eventDateSet: {
        var s = {};
        for (var i = 0; i < CalendarService.events.length; i++)
            s[CalendarService.events[i].start.substring(0, 10)] = true;
        return s;
    }

    readonly property var _weekStart: {
        var d = new Date(root.selectedDate);
        var day = d.getDay();
        var diff = day === 0 ? -6 : 1 - day;
        d.setDate(d.getDate() + diff);
        d.setHours(0, 0, 0, 0);
        return d;
    }

    function prevMonth() {
        if (root.viewMonth === 0) {
            root.viewMonth = 11;
            root.viewYear -= 1;
        } else
            root.viewMonth -= 1;
        root.selectedDate = new Date(root.viewYear, root.viewMonth, 1);
    }
    function nextMonth() {
        if (root.viewMonth === 11) {
            root.viewMonth = 0;
            root.viewYear += 1;
        } else
            root.viewMonth += 1;
        root.selectedDate = new Date(root.viewYear, root.viewMonth, 1);
    }

    implicitHeight: _col.implicitHeight

    ColumnLayout {
        id: _col
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }
        spacing: 0

        // Month navigation
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: UIScale.panelPad
            Layout.rightMargin: UIScale.panelPad
            Layout.topMargin: UIScale.spacingXs
            spacing: UIScale.spacingXs

            Rectangle {
                implicitWidth: Math.round(28 * UIScale.value)
                implicitHeight: Math.round(28 * UIScale.value)
                radius: UIScale.radiusSm
                color: prevHov.hovered ? Colors.withAlpha(Colors.text, 0.1) : "transparent"
                Behavior on color {
                    ColorAnimation {
                        duration: Anim.fast
                    }
                }
                Text {
                    anchors.centerIn: parent
                    text: ""
                    font.family: "Material Icons"
                    font.pixelSize: Math.round(18 * UIScale.value)
                    color: Colors.textDim
                }
                HoverHandler {
                    id: prevHov
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.prevMonth()
                }
            }
            Text {
                Layout.fillWidth: true
                text: root._monthNames[root.viewMonth] + " " + root.viewYear
                color: Colors.text
                font.pixelSize: UIScale.fontSubhead
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
            }
            Rectangle {
                implicitWidth: Math.round(28 * UIScale.value)
                implicitHeight: Math.round(28 * UIScale.value)
                radius: UIScale.radiusSm
                color: nextHov.hovered ? Colors.withAlpha(Colors.text, 0.1) : "transparent"
                Behavior on color {
                    ColorAnimation {
                        duration: Anim.fast
                    }
                }
                Text {
                    anchors.centerIn: parent
                    text: ""
                    font.family: "Material Icons"
                    font.pixelSize: Math.round(18 * UIScale.value)
                    color: Colors.textDim
                }
                HoverHandler {
                    id: nextHov
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.nextMonth()
                }
            }
        }

        // Day-of-week labels
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: UIScale.panelPad
            Layout.rightMargin: UIScale.panelPad
            spacing: Math.round(4 * UIScale.value)
            Repeater {
                model: root._dayLabels
                delegate: Text {
                    required property string modelData
                    Layout.fillWidth: true
                    text: modelData
                    color: Colors.muted
                    font.pixelSize: UIScale.fontTiny
                    font.weight: Font.Bold
                    font.letterSpacing: 1.0
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        // Calendar grid
        Item {
            id: calGrid
            Layout.fillWidth: true
            Layout.leftMargin: UIScale.panelPad
            Layout.rightMargin: UIScale.panelPad

            readonly property real cellGap: Math.round(4 * UIScale.value)
            readonly property real cellW: (width - 6 * cellGap) / 7
            readonly property real cellH: Math.round(36 * UIScale.value)
            implicitHeight: 6 * cellH + 5 * cellGap

            Repeater {
                model: 42
                delegate: Item {
                    id: dayCell
                    required property int index
                    readonly property int _offset: dayCell.index - root._firstWeekday
                    readonly property bool inMonth: _offset >= 0 && _offset < root._daysInMonth
                    readonly property int dayNum: _offset + 1
                    readonly property var cellDate: new Date(root.viewYear, root.viewMonth, dayNum)
                    readonly property bool isToday: {
                        var t = root._today;
                        return inMonth && cellDate.getFullYear() === t.getFullYear() && cellDate.getMonth() === t.getMonth() && cellDate.getDate() === t.getDate();
                    }
                    readonly property bool inCurrentWeek: {
                        if (!inMonth)
                            return false;
                        var ws = root._weekStart;
                        var d = new Date(cellDate);
                        d.setHours(0, 0, 0, 0);
                        var diff = Math.round((d.getTime() - ws.getTime()) / 86400000);
                        return diff >= 0 && diff < 7;
                    }
                    readonly property bool hasEvents: {
                        if (!inMonth)
                            return false;
                        var y = String(cellDate.getFullYear());
                        var m = String(cellDate.getMonth() + 1).padStart(2, "0");
                        var d = String(cellDate.getDate()).padStart(2, "0");
                        return root._eventDateSet[y + "-" + m + "-" + d] === true;
                    }

                    x: (dayCell.index % 7) * (calGrid.cellW + calGrid.cellGap)
                    y: Math.floor(dayCell.index / 7) * (calGrid.cellH + calGrid.cellGap)
                    width: calGrid.cellW
                    height: calGrid.cellH

                    Rectangle {
                        anchors.fill: parent
                        radius: UIScale.radiusSm
                        color: dayCell.isToday ? Colors.withAlpha(Colors.accent, 0.18) : dayCell.inCurrentWeek ? Colors.withAlpha(Colors.text, 0.06) : cellHov.hovered && dayCell.inMonth ? Colors.withAlpha(Colors.text, 0.04) : "transparent"
                        border.color: dayCell.isToday ? Colors.withAlpha(Colors.accent, 0.6) : dayCell.inCurrentWeek ? Colors.withAlpha(Colors.text, 0.18) : "transparent"
                        border.width: 1
                        Behavior on color {
                            ColorAnimation {
                                duration: Anim.fast
                            }
                        }
                    }
                    Text {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.topMargin: Math.round(8 * UIScale.value)
                        horizontalAlignment: Text.AlignHCenter
                        text: dayCell.inMonth ? dayCell.dayNum : ""
                        color: dayCell.isToday ? Colors.accent : dayCell.inMonth ? Colors.textDim : Colors.withAlpha(Colors.text, 0.15)
                        font.pixelSize: UIScale.fontSmall
                        font.weight: (dayCell.isToday || dayCell.inCurrentWeek) ? Font.DemiBold : Font.Normal
                        Behavior on color {
                            ColorAnimation {
                                duration: Anim.fast
                            }
                        }
                    }
                    Rectangle {
                        visible: dayCell.hasEvents
                        anchors.horizontalCenter: dayCell.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: Math.round(4 * UIScale.value)
                        width: Math.round(4 * UIScale.value)
                        height: Math.round(4 * UIScale.value)
                        radius: width / 2
                        color: dayCell.isToday ? Colors.accent : Colors.withAlpha(Colors.accent, 0.6)
                    }
                    HoverHandler {
                        id: cellHov
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: dayCell.inMonth ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            if (dayCell.inMonth)
                                root.selectedDate = dayCell.cellDate;
                        }
                    }
                }
            }
        }
    }
}
