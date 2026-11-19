import QtQuick
import ".."

// Screen Time (macOS 27, ScreenTimePreferencesExtension.appex). Screen time
// per day = time this Mac was awake (journal boot sessions ∪ UPower activity,
// same source as Battery › Screen On Usage).
Column {
    id: page

    property string pageId: "screenTime"
    property string accountName: ""
    property string accountEmail: ""
    signal navigate(string pageId)

    readonly property var bumpU: Shell.userCfg
    property int rev: 0
    function ug(k, d) { bumpU; rev; return Shell.uget(k, d) }
    function us(k, v) { Shell.uset(k, v); rev++ }

    width: parent ? parent.width : 640
    spacing: 12

    property var hist: null
    readonly property bool activityOn: ug("screenTime.activity", true) === true
    Component.onCompleted: {
        const script = HOME_DIR + "/.cache/systemsettings/battery_history.py"
        Shell.execOut("mkdir -p " + HOME_DIR + "/.cache/systemsettings", 1000)
        Shell.writeFile(script, Shell.readFile(":/scripts/battery_history.py"))
        try { hist = JSON.parse(Shell.execOut("python3 -I " + script, 8000) || "null") } catch (e) { hist = null }
    }
    readonly property var week: hist ? hist.daily.slice(-7) : []
    readonly property real avg: week.length ? week.reduce((a, b) => a + b, 0) / week.length : 0
    function hm(h) {
        const m = Math.round(h * 60)
        return m >= 60 ? Math.floor(m / 60) + "h " + (m % 60) + "m" : m + "m"
    }

    component Note: Text {
        x: Theme.cardMargin + 4
        width: page.width - 2 * (Theme.cardMargin + 4)
        wrapMode: Text.WordWrap
        font.family: Theme.fontText; font.pixelSize: 12; color: Theme.textSecondary
    }

    // ------------------------------------------------------------ who
    GroupCard {
        Item {
            width: parent ? parent.width : 100
            height: 64
            Avatar {
                id: av
                x: 14; anchors.verticalCenter: parent.verticalCenter
                size: 40
                avatarPath: String(Shell.uget("avatarPath", ""))
            }
            Column {
                anchors.left: av.right; anchors.leftMargin: 12; anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                Text { text: page.accountName || "Me"; font.family: Theme.fontText; font.pixelSize: 13; font.weight: Font.DemiBold; color: Theme.textPrimary }
                Text { text: "Screen Time for this Mac"; font.family: Theme.fontText; font.pixelSize: 12; color: Theme.textSecondary }
            }
        }
    }

    // ---------------------------------------------------- activity summary
    Rectangle {
        x: Theme.cardMargin
        width: parent.width - 2 * Theme.cardMargin
        height: sum.implicitHeight + 32
        radius: Theme.cardRadius
        color: Theme.cardBg
        border.width: 1
        border.color: Theme.cardStroke

        Column {
            id: sum
            x: 16; y: 16
            width: parent.width - 32
            spacing: 10

            // off: macOS offer
            Column {
                visible: !page.activityOn
                width: parent.width
                spacing: 8
                Text { text: "App & Website Activity"; font.family: Theme.fontText; font.pixelSize: 13; font.weight: Font.DemiBold; color: Theme.textPrimary }
                Text {
                    width: parent.width; wrapMode: Text.WordWrap
                    text: "Get reports on how you use your devices, apps, and websites."
                    font.family: Theme.fontText; font.pixelSize: 12; color: Theme.textSecondary
                }
                MacButton { text: "Turn On App & Website Activity…"; onClicked: page.us("screenTime.activity", true) }
            }

            // on: daily average + week chart
            Item {
                visible: page.activityOn
                width: parent.width; height: 40
                Column {
                    Text { text: "Daily Average"; font.family: Theme.fontText; font.pixelSize: 11; color: Theme.textSecondary }
                    Text { text: page.hm(page.avg); font.family: Theme.fontDisplay; font.pixelSize: 22; font.weight: Font.Bold; color: Theme.textPrimary }
                }
                Column {
                    anchors.right: parent.right
                    Text { anchors.right: parent.right; text: "Today"; font.family: Theme.fontText; font.pixelSize: 11; color: Theme.textSecondary }
                    Text { anchors.right: parent.right; text: page.week.length ? page.hm(page.week[page.week.length - 1]) : "—"; font.family: Theme.fontText; font.pixelSize: 13; font.weight: Font.DemiBold; color: Theme.textPrimary }
                }
            }
            Item {
                id: chart
                visible: page.activityOn
                width: parent.width; height: 110
                readonly property real topH: Math.max(2, Math.ceil(Math.max.apply(null, page.week.concat([0])) / 2) * 2)
                readonly property real plotW: width - 30
                readonly property real plotH: height - 18
                Repeater {
                    model: 3
                    delegate: Rectangle {
                        required property int index
                        y: Math.round(index * chart.plotH / 2); width: chart.plotW; height: 1
                        color: Theme.dark ? Qt.rgba(1, 1, 1, index === 2 ? 0.18 : 0.08) : Qt.rgba(0, 0, 0, index === 2 ? 0.16 : 0.07)
                    }
                }
                // average line (dashed green, like macOS)
                Canvas {
                    width: chart.plotW; height: 2
                    y: chart.plotH * (1 - page.avg / chart.topH)
                    onPaint: { const c = getContext("2d"); c.reset(); c.strokeStyle = "#34C759"; c.setLineDash([3, 3]); c.lineWidth = 1.5; c.beginPath(); c.moveTo(0, 1); c.lineTo(width, 1); c.stroke() }
                }
                Repeater {
                    model: [chart.topH + "h", (chart.topH / 2) + "h", "0"]
                    delegate: Text {
                        required property var modelData
                        required property int index
                        x: chart.plotW + 6; y: index * chart.plotH / 2 - height / 2
                        text: modelData; font.family: Theme.fontText; font.pixelSize: 10; color: Theme.textSecondary
                    }
                }
                Row {
                    spacing: 14
                    Repeater {
                        model: page.week
                        delegate: Item {
                            required property var modelData
                            required property int index
                            width: (chart.plotW - 14 * 6) / 7; height: chart.height
                            Rectangle {
                                y: chart.plotH - height
                                width: parent.width
                                height: Math.max(modelData > 0 ? 2 : 0, chart.plotH * modelData / chart.topH)
                                radius: 3
                                color: "#0A84FF"
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: chart.plotH + 4
                                text: page.hist ? new Date((page.hist.day0 - (6 - index) * 86400) * 1000).toLocaleDateString(Qt.locale("en_US"), "ddd").charAt(0) : ""
                                font.family: Theme.fontText; font.pixelSize: 10; color: Theme.textSecondary
                            }
                        }
                    }
                }
            }
        }
    }

    GroupCard {
        DetailRow { iconFile: "st_activity"; title: "App & Website Activity"; chevron: true; onClicked: page.navigate("screenTime.viewReports") }
        DetailRow { separator: true; iconFile: "st_notifications"; title: "Notifications"; chevron: true; onClicked: page.navigate("screenTime.viewReports") }
        DetailRow { separator: true; iconFile: "st_pickups"; title: "Pickups"; chevron: true; onClicked: page.navigate("screenTime.viewReports") }
    }
    GroupCard {
        DetailRow { iconFile: "st_downtime"; title: "Downtime"; value: page.ug("screenTime.downtime", false) === true ? "On" : "Off"; chevron: true; onClicked: page.navigate("screenTime.downtime") }
        DetailRow { separator: true; iconFile: "st_applimits"; title: "App Limits"; value: page.ug("screenTime.appLimits", false) === true ? "On" : "Off"; chevron: true; onClicked: page.navigate("screenTime.appLimits") }
        DetailRow { separator: true; iconFile: "st_allowed"; title: "Always Allowed"; chevron: true; onClicked: page.navigate("screenTime.alwaysAllowed") }
    }
    GroupCard {
        DetailRow { iconFile: "st_commlimits"; title: "Communication Limits"; chevron: true }
        DetailRow { separator: true; iconFile: "st_commsafety"; title: "Communication Safety"; chevron: true }
    }
    GroupCard {
        DetailRow { iconFile: "st_content"; title: "Content & Privacy"; value: page.ug("screenTime.contentPrivacy", false) === true ? "On" : "Off"; chevron: true; onClicked: page.navigate("screenTime.contentPrivacy") }
    }

    SectionHeader { text: "Screen Time Settings" }
    GroupCard {
        DetailRow {
            title: "Share across devices"
            showSwitch: true
            switchOn: page.ug("screenTime.share", true) === true
            onToggled: (c) => page.us("screenTime.share", c)
        }
        DetailRow {
            separator: true
            title: "Lock Screen Time Settings"
            subtitle: "Use a passcode to secure Screen Time settings."
            showSwitch: true
            switchOn: page.ug("screenTime.lock", false) === true
            onToggled: (c) => page.us("screenTime.lock", c)
        }
    }
    Note { text: "You can share your Screen Time across devices signed in to the same account." }

    Row {
        anchors.right: parent.right
        anchors.rightMargin: Theme.cardMargin
        spacing: 10
        MacButton {
            visible: page.activityOn
            text: "Turn Off App & Website Activity…"
            onClicked: page.us("screenTime.activity", false)
        }
        HelpCircle { anchors.verticalCenter: parent.verticalCenter }
    }
    Item { width: 1; height: 6 }
}
