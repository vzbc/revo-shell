import QtQuick
import Qt5Compat.GraphicalEffects
import QtQuick.Layouts
import QtQuick.Controls
import Qt.labs.qmlmodels
import Quickshell
import Quickshell.Wayland
import Quickshell.Io

Item {
    id: root

    readonly property real cardMargin: Config.cardMargin !== undefined ? Config.cardMargin : 12

    // Baseline panel bounds to prevent Layout.fillHeight/fillWidth collapse
    implicitWidth: 680
    implicitHeight: 460

    // Calendar Navigation State
    property int gridMonth: new Date().getMonth()
    property int gridYear: new Date().getFullYear()

    function prevMonth() {
        if (gridMonth === 0) {
            gridMonth = 11
            gridYear -= 1
        } else {
            gridMonth -= 1
        }
    }

    function nextMonth() {
        if (gridMonth === 11) {
            gridMonth = 0
            gridYear += 1
        } else {
            gridMonth += 1
        }
    }

    // Selected Date & Date Formatting
    property var selectedDate: new Date()
    
    function formatDateKey(d) {
        var year = d.getFullYear()
        var month = (d.getMonth() + 1).toString().padStart(2, '0')
        var day = d.getDate().toString().padStart(2, '0')
        return year + "-" + month + "-" + day
    }

    property string selectedKey: formatDateKey(selectedDate)

    // Reminders Data Store
    property var allReminders: ({})

    // Persistence
    readonly property string storagePath: Quickshell.shellDir.toString().replace(/^file:\/\//, "") + "/reminders.json"

    function saveReminders() {
        var currentList = []
        for (var i = 0; i < reminderModel.count; i++) {
            currentList.push(reminderModel.get(i).title)
        }

        var updated = Object.assign({}, allReminders)
        if (currentList.length > 0) {
            updated[selectedKey] = currentList
        } else {
            delete updated[selectedKey]
        }
        allReminders = updated

        var jsonStr = JSON.stringify(allReminders)
        saveProcess.command = ["fish", "-c", "printf '%s\\n' '" + jsonStr.replace(/'/g, "'\\''") + "' > " + storagePath]
        saveProcess.running = true
    }

    function loadActiveReminders() {
        reminderModel.clear()
        var list = allReminders[selectedKey] || []
        for (var i = 0; i < list.length; i++) {
            reminderModel.append({ title: list[i] })
        }
    }

    onSelectedKeyChanged: loadActiveReminders()

    Process { id: saveProcess }

    FileView {
        id: remindersFileReader
        path: root.storagePath
        onTextChanged: {
            let raw = text()
            if (!raw || raw.trim() === "") return
            try {
                allReminders = JSON.parse(raw.trim())
                root.loadActiveReminders()
            } catch (e) {
                console.error("Failed to parse reminders JSON:", e)
            }
        }
    }

    // 12-Hour Clock Logic (No leading zero)
    function get12Hour() {
        var d = new Date()
        var h = d.getHours() % 12
        return (h === 0 ? 12 : h).toString()
    }

    property string bigHour: get12Hour()
    property string bigMinute: Qt.formatTime(new Date(), "mm")
    property string bigAmPm: Qt.formatTime(new Date(), "ap")
    property string dayOfWeekStr: Qt.formatDate(selectedDate, "dddd")
    property string formattedDateUpper: Qt.formatDate(new Date(), "dddd, MMM d").toUpperCase()

    Timer {
        interval: 1000
        running: root.visible
        repeat: true
        onTriggered: {
            var d = new Date()
            bigHour = root.get12Hour()
            bigMinute = Qt.formatTime(d, "mm")
            bigAmPm = Qt.formatTime(d, "ap")
            formattedDateUpper = Qt.formatDate(d, "dddd, MMM d").toUpperCase()
        }
    }

    ListModel { id: reminderModel }

    RowLayout {
        id: mainRow
        anchors.fill: parent
        anchors.margins: root.cardMargin
        spacing: root.cardMargin / 2

        // --- LEFT COLUMN: CLOCK, GRAPHIC WEATHER & REMINDERS ---
        ColumnLayout {
            Layout.fillHeight: true
            Layout.preferredWidth: 260
            Layout.maximumWidth: 260
            spacing: root.cardMargin / 2

            // CARD 1: HERO CLOCK & ATMOSPHERIC GRAPHIC WEATHER
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: clockWeatherCol.implicitHeight + (root.cardMargin * 2)
                color: Qt.rgba(1, 1, 1, 0.08)
                radius: Config.cornerRadius
                border.width: 1
                border.color: Qt.rgba(255, 255, 255, 0.1)
                clip: true

                Behavior on border.color { ColorAnimation { duration: 150 } }

                // MASSIVE GRAPHIC WEATHER WATERMARK
                Watermark {
                    icon: Config.weather.glyph
                    iconSize: 150
                    seed: 6
                }

                ColumnLayout {
                    id: clockWeatherCol
                    anchors.fill: parent
                    anchors.margins: root.cardMargin
                    spacing: 10

                    // TOP HEADER: DAY & DATE PILL
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Rectangle {
                            implicitWidth: 3
                            implicitHeight: 12
                            radius: 1.5
                            color: Config.accent
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Text {
                            text: root.formattedDateUpper
                            color: Config.accent
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontCaption)
                            font.bold: true
                            font.letterSpacing: 1.1
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }

                    // HERO CLOCK DISPLAY (CENTERED WITH EXACT MATCH ACCENT GLOW)
                    RowLayout {
                        id: heroTimeRow
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 6

                        Item {
                            implicitWidth: heroTimeText.implicitWidth
                            implicitHeight: heroTimeText.implicitHeight

                            Glow {
                                anchors.fill: heroTimeText
                                source: heroTimeText
                                radius: 12
                                samples: 24
                                color: Config.accent
                                spread: 0.2
                                transparentBorder: true
                                visible: Config.clockShowGlow
                            }

                            Text {
                                id: heroTimeText
                                anchors.fill: parent
                                text: bigHour + ":" + bigMinute
                                color: Config.textMain
                                font.family: Config.sysFont
                                font.pixelSize: 68
                                font.bold: true
                                font.italic: true
                                font.letterSpacing: -2.0
                            }
                        }

                        Rectangle {
                            implicitWidth: amPmText.implicitWidth + 10
                            implicitHeight: 22
                            radius: 11
                            color: Qt.rgba(255, 255, 255, 0.10)
                            border.width: 2
                            border.color: Qt.rgba(255, 255, 255, 0.15)
                            Layout.alignment: Qt.AlignTop
                            Layout.topMargin: 8

                            Text {
                                id: amPmText
                                anchors.centerIn: parent
                                text: bigAmPm.toUpperCase()
                                color: Config.textMain
                                font.family: Config.sysFont
                                font.pixelSize: 13
                                font.bold: true
                                font.italic: true
                            }
                        }
                    }

                    // WEATHER TYPOGRAPHY (ELIDED & BOUNDED TO PREVENT OVERFLOW)
                    RowLayout {
                        spacing: 6
                        Layout.fillWidth: true

                        Text {
                            text: Config.weather.temp
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: 18
                            font.bold: true
                        }

                        Rectangle {
                            implicitWidth: 4
                            implicitHeight: 4
                            radius: 2
                            color: Config.accent
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Text {
                            text: Config.weather.desc !== "" ? Config.weather.desc : "Current Weather"
                            color: Config.textMuted
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontCaption)
                            font.bold: true
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                }
            }

            // CARD 2: REMINDERS CARD WITH GRAPHIC WATERMARK
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: Qt.rgba(1, 1, 1, 0.08)
                radius: Config.cornerRadius
                border.width: 1
                border.color: Qt.rgba(255, 255, 255, 0.1)
                clip: true

                Behavior on border.color { ColorAnimation { duration: 150 } }

                // GRAPHIC NOTES WATERMARK
                Watermark {
                    icon: "edit_note"
                    iconSize: 110
                    baseRotation: 10
                    seed: 7
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: root.cardMargin / 2
                    spacing: 8

                    RowLayout {
                        spacing: 6
                        Rectangle {
                            implicitWidth: 3; implicitHeight: 12; radius: 1.5
                            color: Config.accent
                        }
                        Text {
                            text: "NOTES / REMINDERS"
                            color: Config.textMuted
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontCaption)
                            font.bold: true
                        }
                    }

                    ListView {
                        id: reminderList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 6
                        model: reminderModel

                        delegate: Rectangle {
                            width: reminderList.width
                            implicitHeight: rowContent.implicitHeight + 10
                            radius: Config.cornerRadius / 2
                            color: itemHover.hovered ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(0, 0, 0, 0.25)

                            Behavior on color { ColorAnimation { duration: 150 } }

                            HoverHandler { id: itemHover }

                            RowLayout {
                                id: rowContent
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 6
                                anchors.topMargin: 4
                                anchors.bottomMargin: 4
                                spacing: 8

                                Text {
                                    text: model.title
                                    color: Config.textMain
                                    font.family: Config.sysFont
                                    font.pixelSize: Config.size(Config.fontBody)
                                    Layout.fillWidth: true
                                    wrapMode: Text.Wrap
                                }

                                Rectangle {
                                    id: deleteBtn
                                    implicitWidth: 20
                                    implicitHeight: 20
                                    radius: Config.cornerRadius / 4
                                    color: deleteHover.hovered ? Qt.rgba(255, 255, 255, 0.12) : "transparent"
                                    Layout.alignment: Qt.AlignTop

                                    Behavior on color { ColorAnimation { duration: 150 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "×"
                                        color: deleteHover.hovered ? Config.accent : Config.textMuted
                                        font.family: Config.sysFont
                                        font.pixelSize: Config.size(Config.fontSubhead)
                                        font.bold: true
                                    }

                                    TapHandler {
                                        onTapped: {
                                            reminderModel.remove(index)
                                            root.saveReminders()
                                        }
                                    }

                                    HoverHandler {
                                        id: deleteHover
                                        cursorShape: Qt.PointingHandCursor
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: Math.max(32, noteInput.implicitHeight + 8)
                        color: Qt.rgba(0, 0, 0, 0.25)
                        radius: Config.cornerRadius / 2

                        TextEdit {
                            id: noteInput
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            anchors.topMargin: 6
                            anchors.bottomMargin: 6
                            verticalAlignment: Text.AlignVCenter
                            color: Config.textMain
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontCaption)
                            wrapMode: TextEdit.Wrap
                            selectByMouse: true

                            Text {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                text: "Type a note, Enter to save..."
                                color: Config.textMuted
                                font.family: Config.sysFont
                                font.pixelSize: Config.size(Config.fontCaption)
                                visible: !noteInput.text && !noteInput.activeFocus
                            }

                            HoverHandler { cursorShape: Qt.IBeamCursor }

                            Keys.onPressed: event => {
                                if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && !(event.modifiers & Qt.ShiftModifier)) {
                                    if (noteInput.text.trim() !== "") {
                                        reminderModel.append({ title: noteInput.text.trim() })
                                        root.saveReminders()
                                        noteInput.text = ""
                                    }
                                    event.accepted = true
                                }
                            }
                        }
                    }
                }
            }
        }

        // --- CARD 3: CALENDAR MONTHGRID CARD WITH GRAPHIC WATERMARK ---
        Rectangle {
            Layout.fillHeight: true
            Layout.fillWidth: true
            color: Qt.rgba(1, 1, 1, 0.08)
            radius: Config.cornerRadius
            border.width: 1
            border.color: Qt.rgba(255, 255, 255, 0.1)
            clip: true

            Behavior on border.color { ColorAnimation { duration: 150 } }

            // GRAPHIC CALENDAR WATERMARK
            Watermark {
                icon: "calendar_month"
                iconSize: 150
                seed: 8
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: root.cardMargin
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    Text {
                        text: dayOfWeekStr.toUpperCase()
                        color: Config.accent
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontTitle)
                        font.bold: true
                    }
                    Item { Layout.fillWidth: true }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: root.cardMargin

                    Text {
                        text: Qt.formatDate(new Date(root.gridYear, root.gridMonth, 1), "MMMM yyyy").toUpperCase()
                        color: Config.textMain
                        font.family: Config.sysFont
                        font.pixelSize: Config.size(Config.fontSubhead)
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    RowLayout {
                        spacing: 4

                        Rectangle {
                            implicitWidth: 28
                            implicitHeight: 28
                            radius: Config.cornerRadius / 2
                            color: prevHover.hovered ? Qt.rgba(255, 255, 255, 0.1) : "transparent"
                            border.color: prevHover.hovered ? Config.accent : Qt.rgba(255, 255, 255, 0.15)
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            Item {
                                implicitWidth: 18
                                implicitHeight: 18
                                anchors.centerIn: parent

                                Text {
                                    anchors.centerIn: parent
                                    text: "chevron_left"
                                    font.family: "Material Symbols Outlined"
                                    font.pixelSize: 18
                                    color: prevHover.hovered ? Config.accent : Config.textMain
                                }
                            }

                            TapHandler { onTapped: root.prevMonth() }
                            HoverHandler { id: prevHover; cursorShape: Qt.PointingHandCursor }
                        }

                        Rectangle {
                            implicitWidth: 28
                            implicitHeight: 28
                            radius: Config.cornerRadius / 2
                            color: nextHover.hovered ? Qt.rgba(255, 255, 255, 0.1) : "transparent"
                            border.color: nextHover.hovered ? Config.accent : Qt.rgba(255, 255, 255, 0.15)
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            Item {
                                implicitWidth: 18
                                implicitHeight: 18
                                anchors.centerIn: parent

                                Text {
                                    anchors.centerIn: parent
                                    text: "chevron_right"
                                    font.family: "Material Symbols Outlined"
                                    font.pixelSize: 18
                                    color: nextHover.hovered ? Config.accent : Config.textMain
                                }
                            }

                            TapHandler { onTapped: root.nextMonth() }
                            HoverHandler { id: nextHover; cursorShape: Qt.PointingHandCursor }
                        }
                    }
                }

                MonthGrid {
                    id: grid
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    month: root.gridMonth
                    year: root.gridYear

                    delegate: Rectangle {
                        implicitWidth: 38
                        implicitHeight: 38
                        radius: Config.cornerRadius / 1.5

                        property string cellKey: root.formatDateKey(model.date)
                        property bool isSelected: cellKey === root.selectedKey
                        property bool hasReminders: (root.allReminders[cellKey] || []).length > 0

                        color: isSelected ? Config.accent : (model.today ? Qt.rgba(255, 255, 255, 0.05) : "transparent")
                        border.color: isSelected ? Config.accent : (hasReminders ? Config.textMuted : (model.today ? Config.accent : "transparent"))
                        border.width: isSelected || hasReminders || model.today ? 1 : 0

                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: model.day
                            color: isSelected ? Config.bgBase : (model.today ? Config.accent : (model.month === grid.month ? Config.textMain : Qt.rgba(255,255,255,0.15)))
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontSubhead)
                            font.bold: model.today || isSelected || hasReminders
                        }

                        TapHandler {
                            onTapped: root.selectedDate = model.date
                        }

                        HoverHandler {
                            cursorShape: Qt.PointingHandCursor
                        }
                    }
                }
            }
        }
    }
}