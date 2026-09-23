pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../calendar"
import "../user"
import "../../"
import "../weather"
import "../diaspora"

Item {
    id: root

    property var _now: new Date()
    Timer {
        interval: 60000
        repeat: true
        running: true
        onTriggered: root._now = new Date()
    }

    property string _greeting: ""
    Component.onCompleted: {
        var h = new Date().getHours();
        var opts;
        if (h >= 5 && h < 12)
            opts = I18n.t("home.greetingsMorning").split("|");
        else if (h >= 12 && h < 17)
            opts = I18n.t("home.greetingsAfternoon").split("|");
        else if (h >= 17 && h < 22)
            opts = I18n.t("home.greetingsEvening").split("|");
        else
            opts = I18n.t("home.greetingsNight").split("|");
        root._greeting = opts[Math.floor(Math.random() * opts.length)];
    }

    readonly property var _dayNames: I18n.t("home.dayNames").split("|")
    readonly property var _monthNames: I18n.t("home.monthNames").split("|")

    readonly property string _dateStr: {
        var d = root._now;
        return root._dayNames[d.getDay()] + ", " + d.getDate() + " " + root._monthNames[d.getMonth()] + " " + d.getFullYear();
    }

    readonly property string _todayKey: {
        var d = root._now;
        return d.getFullYear() + "-" + String(d.getMonth() + 1).padStart(2, "0") + "-" + String(d.getDate()).padStart(2, "0");
    }

    readonly property var _todayEvents: {
        var out = [];
        for (var i = 0; i < CalendarService.events.length; i++) {
            var ev = CalendarService.events[i];
            if (ev.start.substring(0, 10) === root._todayKey)
                out.push(ev);
        }
        out.sort(function (a, b) {
            if (a.allDay && !b.allDay)
                return -1;
            if (!a.allDay && b.allDay)
                return 1;
            return a.start < b.start ? -1 : a.start > b.start ? 1 : 0;
        });
        return out;
    }

    function _fmtTime(ev) {
        if (ev.allDay)
            return I18n.t("home.allDay");
        return ev.start.substring(11, 16);
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Hero: greeting card
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: Math.round(130 * UIScale.value)
            topRightRadius: Math.round(16 * UIScale.value)
            color: Colors.withAlpha(Colors.surface, 0.4)

            Image {
                anchors.fill: parent
                source: {
                    if (UserService.heroFollowWallpaper)
                        return ThemeState.lastWallpaper !== "" ? ("file://" + ThemeState.lastWallpaper) : "";
                    return UserService.heroImage !== "" ? ("file://" + UserService.heroImage) : "";
                }
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                opacity: 0.15
                visible: status === Image.Ready
            }

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: Colors.withAlpha(Colors.text, 0.07)
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: UIScale.panelPad
                anchors.rightMargin: UIScale.panelPad
                anchors.topMargin: UIScale.spacingMd
                anchors.bottomMargin: UIScale.spacingMd
                spacing: UIScale.spacingMd

                Column {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: Math.round(3 * UIScale.value)

                    Text {
                        text: root._greeting
                        color: Colors.textDim
                        font.pixelSize: UIScale.fontSubhead
                    }
                    Text {
                        width: parent.width
                        text: UserService.name !== "" ? UserService.name : I18n.t("home.welcome")
                        color: Colors.text
                        font.pixelSize: Math.round(30 * UIScale.value * UIScale.fontScale)
                        font.weight: Font.ExtraBold
                        elide: Text.ElideRight
                    }
                    Text {
                        text: root._dateStr
                        color: Colors.muted
                        font.pixelSize: UIScale.fontSmall
                    }
                }

                UserAvatar {
                    size: Math.round(72 * UIScale.value)
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }

        // Body: agenda + mini calendar
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // Left: today's agenda
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                BackgroundGlobe {
                    anchors.fill: parent
                    opacity: 0.16
                }

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: UIScale.panelPad
                        Layout.rightMargin: UIScale.spacingMd
                        Layout.topMargin: UIScale.spacingMd
                        Layout.bottomMargin: UIScale.spacingSm
                        spacing: UIScale.spacingSm

                        Text {
                            text: I18n.t("home.today")
                            color: Colors.muted
                            font.pixelSize: UIScale.fontTiny
                            font.weight: Font.Bold
                            font.letterSpacing: 1.5
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 1
                            color: Colors.withAlpha(Colors.text, 0.07)
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Text {
                            visible: root._todayEvents.length > 0
                            text: root._todayEvents.length + (root._todayEvents.length === 1 ? " event" : " events")
                            color: Colors.muted
                            font.pixelSize: UIScale.fontTiny
                        }
                    }

                    Flickable {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentWidth: width
                        contentHeight: agendaCol.implicitHeight + UIScale.spacingLg
                        clip: true
                        flickableDirection: Flickable.VerticalFlick
                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded
                        }

                        Column {
                            id: agendaCol
                            x: UIScale.panelPad
                            width: parent.width - UIScale.panelPad - UIScale.spacingMd
                            spacing: Math.round(5 * UIScale.value)

                            Item {
                                width: parent.width
                                height: Math.round(100 * UIScale.value)
                                visible: root._todayEvents.length === 0

                                Column {
                                    anchors.centerIn: parent
                                    spacing: UIScale.spacingSm

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: ""
                                        font.family: "Material Icons"
                                        font.pixelSize: Math.round(28 * UIScale.value)
                                        color: Colors.withAlpha(Colors.text, 0.15)
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: I18n.t("home.nothingScheduledToday")
                                        color: Colors.muted
                                        font.pixelSize: UIScale.fontSmall
                                    }
                                }
                            }

                            Repeater {
                                model: root._todayEvents

                                Rectangle {
                                    id: evCard
                                    required property var modelData
                                    width: parent.width
                                    implicitHeight: Math.round(54 * UIScale.value)
                                    radius: UIScale.radiusMd
                                    color: evHov.hovered ? Colors.withAlpha(Colors.text, 0.04) : "transparent"
                                    Behavior on color {
                                        ColorAnimation {
                                            duration: Anim.fast
                                        }
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: UIScale.spacingSm
                                        anchors.rightMargin: UIScale.spacingSm
                                        anchors.topMargin: UIScale.spacingXs
                                        anchors.bottomMargin: UIScale.spacingXs
                                        spacing: UIScale.spacingMd

                                        Rectangle {
                                            implicitWidth: Math.round(3 * UIScale.value)
                                            Layout.fillHeight: true
                                            Layout.topMargin: Math.round(6 * UIScale.value)
                                            Layout.bottomMargin: Math.round(6 * UIScale.value)
                                            radius: 2
                                            color: Colors.accent
                                        }

                                        Text {
                                            text: root._fmtTime(evCard.modelData)
                                            color: Colors.accent
                                            font.pixelSize: UIScale.fontTiny
                                            font.weight: Font.DemiBold
                                            font.family: evCard.modelData.allDay ? "" : "monospace"
                                            Layout.preferredWidth: Math.round(48 * UIScale.value)
                                            Layout.alignment: Qt.AlignVCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }

                                        Column {
                                            Layout.fillWidth: true
                                            Layout.alignment: Qt.AlignVCenter
                                            spacing: Math.round(2 * UIScale.value)

                                            Text {
                                                width: parent.width
                                                text: evCard.modelData.summary
                                                color: Colors.text
                                                font.pixelSize: UIScale.fontBody
                                                font.weight: Font.DemiBold
                                                elide: Text.ElideRight
                                            }
                                            Text {
                                                visible: (evCard.modelData.location || "") !== ""
                                                width: parent.width
                                                text: evCard.modelData.location || ""
                                                color: Colors.textDim
                                                font.pixelSize: UIScale.fontTiny
                                                elide: Text.ElideRight
                                            }
                                        }
                                    }

                                    HoverHandler {
                                        id: evHov
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                implicitWidth: 1
                Layout.fillHeight: true
                color: Colors.withAlpha(Colors.outline, 0.5)
            }

            // Right: weather + calendar stacked
            Item {
                Layout.preferredWidth: Math.round(320 * UIScale.value)
                Layout.maximumWidth: Math.round(320 * UIScale.value)
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    WeatherReport {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 1
                        color: Colors.withAlpha(Colors.outline, 0.5)
                    }

                    Item {
                        implicitHeight: UIScale.spacingMd
                    }

                    CalendarMiniGrid {
                        Layout.fillWidth: true
                    }

                    Item {
                        implicitHeight: UIScale.spacingMd
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.leftMargin: UIScale.spacingMd
                        Layout.rightMargin: UIScale.spacingMd
                        Layout.bottomMargin: UIScale.spacingMd
                        implicitHeight: Math.round(34 * UIScale.value)
                        radius: UIScale.radiusMd
                        color: jumpHov.hovered ? Colors.withAlpha(Colors.accent, 0.2) : Colors.withAlpha(Colors.accent, 0.1)
                        Behavior on color {
                            ColorAnimation {
                                duration: Anim.fast
                            }
                        }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: UIScale.spacingXs

                            Text {
                                text: "󰺻"
                                font.family: "Material Icons"
                                font.pixelSize: UIScale.fontBody
                                color: Colors.accent
                            }
                            Text {
                                text: I18n.t("home.openCalendar")
                                color: Colors.accent
                                font.pixelSize: UIScale.fontSmall
                                font.weight: Font.DemiBold
                            }
                        }

                        HoverHandler {
                            id: jumpHov
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: HomePanelService.requestedSection = "calendar"
                        }
                    }
                }
            }
        }
    }
}
