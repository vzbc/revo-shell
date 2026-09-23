pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../shared"
import "../../"

// Note: Claude Clode helped me initially figuring out how to do dynamic changes in size in this file.
// This was a sort of testing ground to see if dynamic resizing even worked in QML, and it helped me find
// documentation, writing independent tests, brainstorming and worked out the data/structure together.

// I have written extensive documentation, so that it's easier to come back to in the future, or for someone
// new to understand how this dynamic resizing works.

Item {
    id: root

    property int activeTab: 0
    property bool _hourlyExpanded: false
    property bool _showSettings: false

    // Divide out UIScale.value first, fonts/rows/icons all grow with it, so the
    // threshold needs the same logical units or it drifts once UIScale != 1.
    readonly property bool compact: width > 0 && (width / UIScale.value) < 200
    // Plenty of width: put the display+tabs on the left and let the list use the full
    // height on the right, instead of stacking everything and starving the list's height.
    // This one stays a tuned constant on purpose, "wide enough to justify a split layout"
    // is a design call, not something derivable from content the way the others below are.
    readonly property bool sideBySide: width > 0 && (width / UIScale.value) > 580

    // How much vertical room displayBlock + the tab bar actually need, measured directly
    readonly property bool shortHeight: height > 0 && height < (displayBlock.implicitHeight + tabBarBlock.implicitHeight)

    // Padding is handled via anchors margins below (dividerGap, sidePad), not baked in
    // here, that would leave no slack for WeatherDisplay's own centering to breathe.
    readonly property real sideColumnWidth: displayBlock.implicitWidth
    // Indents the left column to line up with PanelHeader's own left inset above it
    readonly property real sidePad: UIScale.panelPad
    // Small gap between the column content and the divider line, on both sides of it
    readonly property real dividerGap: UIScale.spacingMd

    // How many hourly rows actually fit contentBlock's real height,
    // a tall side-by-side column should show as many as it has room for.
    readonly property int _hourlyRowSlotHeight: Math.round(42 * UIScale.value) + Math.round(2 * UIScale.value)
    readonly property int _hourlyMoreRowHeight: Math.round(34 * UIScale.value)

    // Purely geometric row count, accounts for the "+more" link's own height eating
    // into the budget once everything doesn't fit, independent of chip/vertical mode.
    // Used only to decide listNeedsChips itself, the "real" _visibleHourlyCount below
    // reuses this rather than recomputing it, so the two can't disagree with each other.
    readonly property int _hourlyFitCount: {
        if (root._hourlyRowSlotHeight <= 0)
            return WeatherService.hourly.length;
        var fitAll = Math.floor(contentBlock.height / root._hourlyRowSlotHeight);
        if (fitAll >= WeatherService.hourly.length)
            return WeatherService.hourly.length;
        return Math.floor((contentBlock.height - root._hourlyMoreRowHeight) / root._hourlyRowSlotHeight);
    }

    // Whether the list itself (not the whole widget) has room for stacked rows. In
    // side-by-side mode contentBlock gets the full container height regardless of
    // root.shortHeight, so measure contentBlock directly rather than reusing shortHeight,
    // otherwise a short-but-wide container needlessly collapses a list that has plenty
    // of room to spare in its own column. A single row with a "+N more" link below it
    // reads as broken, not compact, so chips kick in below 2 rows rather than 0.
    readonly property bool listNeedsChips: contentBlock.height > 0 && root._hourlyFitCount < 2

    readonly property int _visibleHourlyCount: root.listNeedsChips ? WeatherService.hourly.length : root._hourlyFitCount

    // Vertical row delegate for hourly, one row per hour, full width
    Component {
        id: hourlyRowDelegate
        Item {
            id: hourRow
            required property var modelData
            required property int index

            width: ListView.view.width
            implicitHeight: Math.round(42 * UIScale.value)

            Rectangle {
                anchors {
                    fill: parent
                    leftMargin: UIScale.spacingMd
                    rightMargin: UIScale.spacingMd
                }
                radius: UIScale.radiusSm
                color: hourRow.modelData.isCurrent ? Colors.withAlpha(Colors.accent, 0.08) : "transparent"

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: UIScale.spacingSm
                        rightMargin: UIScale.spacingSm
                    }
                    spacing: UIScale.spacingSm

                    Text {
                        text: hourRow.modelData.timeLabel
                        font.pixelSize: UIScale.fontSmall
                        font.weight: hourRow.modelData.isCurrent ? Font.DemiBold : Font.Normal
                        color: hourRow.modelData.isCurrent ? Colors.accent : Colors.text
                        Layout.preferredWidth: Math.round((root.compact ? 40 : 52) * UIScale.value)
                    }

                    Text {
                        text: WeatherService.weatherIcon(hourRow.modelData.weatherCode, hourRow.modelData.hour >= 6 && hourRow.modelData.hour < 20)
                        font.pixelSize: Math.round(18 * UIScale.value)
                        color: Colors.text
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        visible: hourRow.modelData.precipProb > 10 && !root.compact
                        implicitWidth: hourPrecipTxt.implicitWidth + Math.round(8 * UIScale.value)
                        implicitHeight: Math.round(16 * UIScale.value)
                        radius: Math.round(4 * UIScale.value)
                        color: Colors.withAlpha("#4A9EFF", 0.15)

                        Text {
                            id: hourPrecipTxt
                            anchors.centerIn: parent
                            text: hourRow.modelData.precipProb + "%"
                            font.pixelSize: UIScale.fontTiny
                            color: "#4A9EFF"
                        }
                    }

                    Text {
                        text: hourRow.modelData.temperature + "°"
                        font.pixelSize: UIScale.fontSmall
                        color: Colors.text
                        Layout.preferredWidth: Math.round((root.compact ? 30 : 36) * UIScale.value)
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }
        }
    }

    // Horizontal chip delegate for hourly, used when there isn't enough height for stacked rows
    Component {
        id: hourlyChipDelegate
        Item {
            id: hourChip
            required property var modelData
            required property int index

            width: Math.round(56 * UIScale.value)
            height: ListView.view.height

            Rectangle {
                anchors.fill: parent
                anchors.margins: Math.round(3 * UIScale.value)
                radius: UIScale.radiusSm
                color: hourChip.modelData.isCurrent ? Colors.withAlpha(Colors.accent, 0.08) : "transparent"

                Column {
                    anchors.centerIn: parent
                    spacing: Math.round(3 * UIScale.value)

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: hourChip.modelData.timeLabel
                        font.pixelSize: UIScale.fontTiny
                        font.weight: hourChip.modelData.isCurrent ? Font.DemiBold : Font.Normal
                        color: hourChip.modelData.isCurrent ? Colors.accent : Colors.textDim
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: WeatherService.weatherIcon(hourChip.modelData.weatherCode, hourChip.modelData.hour >= 6 && hourChip.modelData.hour < 20)
                        font.pixelSize: Math.round(18 * UIScale.value)
                        color: Colors.text
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: hourChip.modelData.temperature + "°"
                        font.pixelSize: UIScale.fontSmall
                        font.weight: hourChip.modelData.isCurrent ? Font.DemiBold : Font.Normal
                        color: hourChip.modelData.isCurrent ? Colors.accent : Colors.text
                    }
                }
            }
        }
    }

    // Vertical row delegate for weekly, one row per day, full width
    Component {
        id: weeklyRowDelegate
        Item {
            id: dayRow
            required property var modelData
            required property int index

            width: ListView.view.width
            implicitHeight: Math.round(42 * UIScale.value)

            Rectangle {
                anchors {
                    fill: parent
                    leftMargin: UIScale.spacingMd
                    rightMargin: UIScale.spacingMd
                }
                radius: UIScale.radiusSm
                color: dayRow.index === 0 ? Colors.withAlpha(Colors.accent, 0.08) : "transparent"

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: UIScale.spacingSm
                        rightMargin: UIScale.spacingSm
                    }
                    spacing: UIScale.spacingSm

                    Text {
                        text: dayRow.modelData.label
                        font.pixelSize: UIScale.fontSmall
                        font.weight: dayRow.index === 0 ? Font.DemiBold : Font.Normal
                        color: Colors.text
                        Layout.preferredWidth: Math.round((root.compact ? 54 : 72) * UIScale.value)
                    }

                    Text {
                        text: WeatherService.weatherIcon(dayRow.modelData.weatherCode, true)
                        font.pixelSize: Math.round(18 * UIScale.value)
                        color: Colors.text
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        visible: dayRow.modelData.precipProb > 10 && !root.compact
                        implicitWidth: dayPrecipTxt.implicitWidth + Math.round(8 * UIScale.value)
                        implicitHeight: Math.round(16 * UIScale.value)
                        radius: Math.round(4 * UIScale.value)
                        color: Colors.withAlpha("#4A9EFF", 0.15)

                        Text {
                            id: dayPrecipTxt
                            anchors.centerIn: parent
                            text: dayRow.modelData.precipProb + "%"
                            font.pixelSize: UIScale.fontTiny
                            color: "#4A9EFF"
                        }
                    }

                    Text {
                        text: dayRow.modelData.tempMax + "° / " + dayRow.modelData.tempMin + "°"
                        font.pixelSize: UIScale.fontSmall
                        color: Colors.text
                        Layout.preferredWidth: Math.round((root.compact ? 56 : 68) * UIScale.value)
                        horizontalAlignment: Text.AlignRight
                    }
                }
            }
        }
    }

    // Horizontal chip delegate for weekly, used when there isn't enough height for stacked rows
    Component {
        id: weeklyChipDelegate
        Item {
            id: dayChip
            required property var modelData
            required property int index

            width: Math.round(64 * UIScale.value)
            height: ListView.view.height

            Rectangle {
                anchors.fill: parent
                anchors.margins: Math.round(3 * UIScale.value)
                radius: UIScale.radiusSm
                color: dayChip.index === 0 ? Colors.withAlpha(Colors.accent, 0.08) : "transparent"

                Column {
                    anchors.centerIn: parent
                    spacing: Math.round(3 * UIScale.value)

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: dayChip.modelData.label
                        font.pixelSize: UIScale.fontTiny
                        font.weight: dayChip.index === 0 ? Font.DemiBold : Font.Normal
                        color: Colors.text
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: WeatherService.weatherIcon(dayChip.modelData.weatherCode, true)
                        font.pixelSize: Math.round(18 * UIScale.value)
                        color: Colors.text
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: dayChip.modelData.tempMax + "°/" + dayChip.modelData.tempMin + "°"
                        font.pixelSize: UIScale.fontTiny
                        color: Colors.textDim
                    }
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        PanelHeader {
            id: header
            Layout.fillWidth: true
            breadcrumb: root._showSettings ? I18n.t("weather.breadcrumbSettings") : (WeatherService.locationName !== "" ? WeatherService.locationName.toUpperCase() : I18n.t("weather.breadcrumbWeather"))
            title: root._showSettings ? I18n.t("weather.settings") : WeatherService.conditionText(WeatherService.weatherCode)
        }

        // Body: display, tab bar and tab content, positioned with plain anchors rather
        // than swapped between two Layout containers via LayoutItemProxy. Anchors are
        // simple and deterministic: stacked vs side-by-side is just which anchor targets are active.
        Item {
            id: body
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !root._showSettings

            WeatherDisplay {
                id: displayBlock
                // Only hide for height when stacked, it's freeing room for the list below it.
                // In side-by-side the list lives in its own column with the full container
                // height regardless, so there's nothing to free up by hiding this.
                visible: root.sideBySide || !root.shortHeight
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.leftMargin: root.sideBySide ? root.sidePad : 0
                width: root.sideBySide ? root.sideColumnWidth : parent.width
            }

            Item {
                id: tabBarBlock
                anchors.top: displayBlock.visible ? displayBlock.bottom : parent.top
                anchors.left: parent.left
                anchors.leftMargin: root.sideBySide ? root.sidePad : 0
                width: root.sideBySide ? root.sideColumnWidth : parent.width
                implicitHeight: Math.round(32 * UIScale.value)
                height: implicitHeight

                Row {
                    anchors.centerIn: parent
                    spacing: UIScale.spacingXs

                    Rectangle {
                        implicitWidth: hourlyLabel.implicitWidth + Math.round(18 * UIScale.value)
                        implicitHeight: Math.round(26 * UIScale.value)
                        radius: UIScale.radiusSm
                        color: root.activeTab === 0 ? Colors.withAlpha(Colors.accent, 0.15) : "transparent"
                        border.color: root.activeTab === 0 ? Colors.withAlpha(Colors.accent, 0.3) : "transparent"
                        border.width: 1
                        Behavior on color {
                            ColorAnimation {
                                duration: Anim.fast
                            }
                        }

                        Text {
                            id: hourlyLabel
                            anchors.centerIn: parent
                            text: I18n.t("weather.hourly")
                            font.pixelSize: UIScale.fontSmall
                            font.weight: root.activeTab === 0 ? Font.DemiBold : Font.Normal
                            color: root.activeTab === 0 ? Colors.accent : Colors.textDim
                            Behavior on color {
                                ColorAnimation {
                                    duration: Anim.fast
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.activeTab = 0
                        }
                    }

                    Rectangle {
                        implicitWidth: weeklyLabel.implicitWidth + Math.round(18 * UIScale.value)
                        implicitHeight: Math.round(26 * UIScale.value)
                        radius: UIScale.radiusSm
                        color: root.activeTab === 1 ? Colors.withAlpha(Colors.accent, 0.15) : "transparent"
                        border.color: root.activeTab === 1 ? Colors.withAlpha(Colors.accent, 0.3) : "transparent"
                        border.width: 1
                        Behavior on color {
                            ColorAnimation {
                                duration: Anim.fast
                            }
                        }

                        Text {
                            id: weeklyLabel
                            anchors.centerIn: parent
                            text: I18n.t("weather.weekly")
                            font.pixelSize: UIScale.fontSmall
                            font.weight: root.activeTab === 1 ? Font.DemiBold : Font.Normal
                            color: root.activeTab === 1 ? Colors.accent : Colors.textDim
                            Behavior on color {
                                ColorAnimation {
                                    duration: Anim.fast
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.activeTab = 1
                        }
                    }
                }
            }

            Rectangle {
                id: infoDivider
                visible: root.sideBySide
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.leftMargin: root.sidePad + root.sideColumnWidth + root.dividerGap
                implicitWidth: 1
                color: Colors.withAlpha(Colors.outline, 0.4)
            }

            Item {
                id: contentBlock
                anchors.top: root.sideBySide ? parent.top : tabBarBlock.bottom
                anchors.bottom: parent.bottom
                anchors.left: root.sideBySide ? infoDivider.right : parent.left
                anchors.leftMargin: root.sideBySide ? root.dividerGap : 0
                anchors.right: parent.right
                anchors.rightMargin: root.sideBySide ? root.sidePad : 0

                // Hourly list + "more" row
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0
                    visible: root.activeTab === 0

                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        orientation: root.listNeedsChips ? ListView.Horizontal : ListView.Vertical
                        topMargin: root.listNeedsChips ? 0 : UIScale.spacingXs
                        bottomMargin: root.listNeedsChips ? 0 : UIScale.spacingXs
                        leftMargin: root.listNeedsChips ? UIScale.spacingMd : 0
                        rightMargin: root.listNeedsChips ? UIScale.spacingMd : 0
                        clip: true
                        // Horizontal mode has room to scroll through everything, no need to gate behind "expand"
                        model: root.listNeedsChips ? WeatherService.hourly : (root._hourlyExpanded ? WeatherService.hourly : WeatherService.hourly.slice(0, root._visibleHourlyCount))
                        spacing: Math.round((root.listNeedsChips ? 4 : 2) * UIScale.value)
                        delegate: root.listNeedsChips ? hourlyChipDelegate : hourlyRowDelegate
                    }

                    // "More" row, only meaningful in vertical mode
                    Item {
                        Layout.fillWidth: true
                        implicitHeight: root._hourlyMoreRowHeight
                        visible: !root.listNeedsChips && !root._hourlyExpanded && WeatherService.hourly.length > root._visibleHourlyCount

                        Text {
                            anchors.centerIn: parent
                            text: "+" + (WeatherService.hourly.length - root._visibleHourlyCount) + " more hours"
                            font.pixelSize: UIScale.fontTiny
                            font.weight: Font.DemiBold
                            color: moreHov.hovered ? Colors.text : Colors.textDim
                            Behavior on color {
                                ColorAnimation {
                                    duration: Anim.fast
                                }
                            }
                        }

                        HoverHandler {
                            id: moreHov
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root._hourlyExpanded = true
                        }
                    }
                }

                // Weekly list
                ListView {
                    anchors.fill: parent
                    orientation: root.listNeedsChips ? ListView.Horizontal : ListView.Vertical
                    anchors.topMargin: root.listNeedsChips ? 0 : UIScale.spacingXs
                    anchors.bottomMargin: root.listNeedsChips ? 0 : UIScale.spacingXs
                    anchors.leftMargin: root.listNeedsChips ? UIScale.spacingMd : 0
                    anchors.rightMargin: root.listNeedsChips ? UIScale.spacingMd : 0
                    visible: root.activeTab === 1
                    clip: true
                    model: WeatherService.daily
                    spacing: Math.round((root.listNeedsChips ? 4 : 2) * UIScale.value)
                    delegate: root.listNeedsChips ? weeklyChipDelegate : weeklyRowDelegate
                }
            }
        }

        // Settings content
        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root._showSettings
            contentWidth: width
            contentHeight: settingsCol.implicitHeight + UIScale.panelPad
            clip: true
            flickableDirection: Flickable.VerticalFlick

            TapHandler {
                onTapped: root.forceActiveFocus()
            }

            ColumnLayout {
                id: settingsCol
                width: parent.width
                spacing: UIScale.spacingMd

                Item {
                    implicitHeight: UIScale.spacingXs
                }

                Text {
                    text: I18n.t("weather.location")
                    color: Colors.muted
                    font.pixelSize: UIScale.fontTiny
                    font.weight: Font.Bold
                    font.letterSpacing: 1.5
                    Layout.leftMargin: UIScale.panelPad
                }

                OptionRow {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                    model: [I18n.t("weather.modeAuto"), I18n.t("weather.modeManual")]
                    currentIndex: WeatherService.locationMode === "manual" ? 1 : 0
                    onActivated: index => {
                        WeatherService.saveLocationMode(index === 1 ? "manual" : "auto");
                        if (index === 0)
                            WeatherService.refresh();
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                    visible: WeatherService.locationMode === "manual"
                    spacing: UIScale.spacingXs

                    Text {
                        text: I18n.t("weather.city")
                        color: Colors.text
                        font.pixelSize: UIScale.fontSmall
                        font.weight: Font.DemiBold
                    }

                    StyledTextInput {
                        Layout.fillWidth: true
                        placeholder: I18n.t("weather.cityPlaceholder")
                        text: WeatherService.manualCity
                        onAccepted: {
                            var city = field.text.trim();
                            if (city.length > 0) {
                                WeatherService.saveManualCity(city);
                                WeatherService.refresh();
                            }
                            root.forceActiveFocus();
                        }
                        field.onActiveFocusChanged: {
                            if (!field.activeFocus) {
                                var city = field.text.trim();
                                if (city.length > 0) {
                                    WeatherService.saveManualCity(city);
                                    WeatherService.refresh();
                                }
                            }
                        }
                    }
                }
            }
        }

        // Error strip
        Text {
            text: WeatherService.error
            color: Colors.textDim
            font.pixelSize: UIScale.fontTiny
            visible: WeatherService.error !== ""
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: UIScale.spacingSm
        }
    }

    // Action buttons overlaid on the header area, outside any Component so root is in scope
    Row {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: UIScale.panelPad
        height: header.height
        spacing: Math.round(14 * UIScale.value)
        z: 1

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: ""
            font.pixelSize: Math.round(16 * UIScale.value)
            color: root._showSettings ? Colors.accent : (settingsHov.hovered ? Colors.text : Colors.textDim)
            Behavior on color {
                ColorAnimation {
                    duration: Anim.fast
                }
            }
            HoverHandler {
                id: settingsHov
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root._showSettings = !root._showSettings
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "󰑓"
            font.pixelSize: Math.round(16 * UIScale.value)
            color: refreshHov.hovered ? Colors.text : Colors.textDim
            Behavior on color {
                ColorAnimation {
                    duration: Anim.fast
                }
            }
            RotationAnimator on rotation {
                running: WeatherService.loading
                from: 0
                to: 360
                duration: 800
                loops: Animation.Infinite
            }
            HoverHandler {
                id: refreshHov
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: WeatherService.refresh()
            }
        }
    }
}
