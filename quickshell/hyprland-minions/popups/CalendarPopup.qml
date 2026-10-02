import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components
import qs.config

// Date/time readout and a month calendar. Scroll or use the arrows to change
// month, click the title to jump back to today.
BarPopup {
    id: popup

    // First day of the month being shown.
    property date month: new Date()

    readonly property var today: clock.date

    function resetMonth() {
        month = new Date(today.getFullYear(), today.getMonth(), 1)
    }

    function shiftMonth(step) {
        month = new Date(month.getFullYear(), month.getMonth() + step, 1)
    }

    // 6 weeks x 7 days starting on the Sunday on/before the 1st.
    readonly property var days: {
        const first = new Date(month.getFullYear(), month.getMonth(), 1)
        const start = new Date(first)
        start.setDate(1 - first.getDay())
        const result = []
        for (let i = 0; i < 42; i++) {
            const d = new Date(start)
            d.setDate(start.getDate() + i)
            result.push(d)
        }
        return result
    }

    onShownChanged: if (shown) resetMonth()

    SystemClock {
        id: clock
        precision: popup.shown ? SystemClock.Seconds : SystemClock.Minutes
    }

    // Big clock in an inset readout panel.
    Item {
        Layout.fillWidth: true
        implicitHeight: readout.implicitHeight + 12

        Bevel {
            anchors.fill: parent
            sunken: true
            faceColor: Theme.field
        }

        ColumnLayout {
            id: readout

            anchors.centerIn: parent
            spacing: 0

            BarText {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatDateTime(clock.date, "hh:mm:ss")
                font.pixelSize: 24
                font.bold: true
            }

            BarText {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatDateTime(clock.date, "dddd, MMMM d, yyyy")
                color: Theme.textDim
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 4

        BarButton {
            implicitWidth: 24
            implicitHeight: 24
            text: "‹"
            onClicked: popup.shiftMonth(-1)
        }

        BarButton {
            Layout.fillWidth: true
            implicitHeight: 24
            flat: true
            text: Qt.formatDate(popup.month, "MMMM yyyy")
            bold: true
            tooltip: "Back to today"
            onClicked: popup.resetMonth()
        }

        BarButton {
            implicitWidth: 24
            implicitHeight: 24
            text: "›"
            onClicked: popup.shiftMonth(1)
        }
    }

    GridLayout {
        columns: 7
        rowSpacing: 0
        columnSpacing: 0

        Repeater {
            model: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

            delegate: BarText {
                required property string modelData

                Layout.preferredWidth: 28
                horizontalAlignment: Text.AlignHCenter
                text: modelData
                color: Theme.textMuted
            }
        }

        Repeater {
            model: popup.days

            delegate: Item {
                id: day

                required property date modelData

                readonly property bool inMonth: modelData.getMonth() === popup.month.getMonth()
                readonly property bool isToday: modelData.toDateString() === popup.today.toDateString()

                Layout.preferredWidth: 28
                Layout.preferredHeight: 22

                Bevel {
                    anchors.fill: parent
                    anchors.margins: 1
                    visible: day.isToday
                    radius: height / 2
                    faceColor: Theme.selection
                }

                BarText {
                    anchors.centerIn: parent
                    text: day.modelData.getDate()
                    color: day.isToday ? Theme.selectionText : day.inMonth ? Theme.text : Theme.textMuted
                    font.bold: day.isToday
                }
            }
        }
    }

    WheelHandler {
        onWheel: event => popup.shiftMonth(event.angleDelta.y > 0 ? -1 : 1)
    }
}
