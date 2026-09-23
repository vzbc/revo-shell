import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import Quickshell
import ".."

Item {
    id: root

    readonly property real cardMargin: Config.cardMargin !== undefined ? Config.cardMargin : 12

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: parent.width
            spacing: root.cardMargin

            // ==========================================
            // HEADER & DESCRIPTION
            // ==========================================
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    text: "LOCATION & WEATHER"
                    color: Config.textMain
                    font.family: Config.sysFont
                    font.pixelSize: Config.size(Config.fontSubhead)
                    font.bold: true
                }

                Text {
                    text: "Configure geolocation override for meteorological forecast telemetry, manage weather refresh, and monitor live conditions."
                    color: Config.textMuted
                    font.family: Config.sysFont
                    font.pixelSize: Config.size(Config.fontCaption)
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }
            }

            // ==========================================
            // 1. HERO LIVE WEATHER CARD
            // ==========================================
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: heroCol.implicitHeight + 28
                radius: Config.cornerRadius
                color: Qt.rgba(255, 255, 255, 0.05)
                border.width: 1
                border.color: Qt.rgba(255, 255, 255, 0.1)
                clip: true

                // Dynamic Graphic Watermark
                Watermark {
                    icon: Config.weather.glyph
                    iconSize: 150
                    baseRotation: 12
                    seed: 26
                }

                ColumnLayout {
                    id: heroCol
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 14

                    // Hero Row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 14

                        // Weather Icon Badge
                        Rectangle {
                            implicitWidth: 44
                            implicitHeight: 44
                            radius: 22
                            color: Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.2)
                            border.width: 1.5
                            border.color: Config.accent

                            Text {
                                anchors.centerIn: parent
                                text: Config.weather.glyph
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: 24
                                color: Config.accent
                            }
                        }

                        // Weather Details
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            RowLayout {
                                spacing: 8
                                Text {
                                    text: Config.weather.temp !== "--" ? `${Config.weather.temp} • ${Config.weather.desc}` : "Weather Forecast"
                                    font.family: Config.sysFont
                                    font.bold: true
                                    color: Config.textMain
                                    font.pixelSize: Config.size(Config.fontBody)
                                }

                                Rectangle {
                                    implicitWidth: statusPillText.implicitWidth + 10
                                    implicitHeight: 18
                                    radius: 9
                                    color: Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.2)
                                    border.width: 1
                                    border.color: Config.accent

                                    Text {
                                        id: statusPillText
                                        anchors.centerIn: parent
                                        text: "LIVE FORECAST"
                                        font.family: Config.sysFont
                                        font.pixelSize: 9
                                        font.bold: true
                                        color: Config.accent
                                    }
                                }
                            }

                            Text {
                                text: (Config.weather.areaName ? (Config.weather.areaName + " • ") : "") + (Config.locationQuery ? ("Custom: " + Config.locationQuery) : "Auto IP Geolocation")
                                font.family: Config.sysFont
                                color: Config.textMuted
                                font.pixelSize: Config.size(Config.fontCaption)
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        // Spacer to push refresh button to the right
                        Item { Layout.fillWidth: true }

                        // REFRESH BUTTON
                        Rectangle {
                            Layout.alignment: Qt.AlignRight
                            implicitWidth: refreshRow.implicitWidth + 18
                            implicitHeight: 32
                            radius: 16
                            color: refreshHover.hovered ? Qt.rgba(255, 255, 255, 0.12) : Qt.rgba(255, 255, 255, 0.06)
                            border.width: 1
                            border.color: Qt.rgba(255, 255, 255, 0.12)

                            Behavior on color { ColorAnimation { duration: 150 } }

                            RowLayout {
                                id: refreshRow
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    id: refreshIcon
                                    text: "refresh"
                                    font.family: "Material Symbols Outlined"
                                    font.pixelSize: 16
                                    color: refreshHover.hovered ? Config.accent : Config.textMain

                                    NumberAnimation on rotation {
                                        running: Config.weather.isFetching
                                        from: 0
                                        to: 360
                                        duration: 800
                                        loops: Animation.Infinite
                                    }
                                }

                                Text {
                                    text: "Sync"
                                    font.family: Config.sysFont
                                    font.pixelSize: Config.size(Config.fontCaption)
                                    font.bold: true
                                    color: refreshHover.hovered ? Config.accent : Config.textMain
                                }
                            }

                            TapHandler {
                                onTapped: {
                                    Config.weather.fetchWeather(true)
                                }
                            }
                            HoverHandler { id: refreshHover; cursorShape: Qt.PointingHandCursor }
                        }
                    }

                    // Live Telemetry Badges Row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        // Humidity Badge
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 32
                            radius: 8
                            color: Qt.rgba(255, 255, 255, 0.04)
                            border.width: 1
                            border.color: Qt.rgba(255, 255, 255, 0.08)

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6
                                Text { text: "water_drop"; font.family: "Material Symbols Outlined"; font.pixelSize: 14; color: Config.accent }
                                Text { text: `Humidity: ${Config.weather.humidity}`; font.family: Config.sysFont; font.pixelSize: Config.size(Config.fontCaption); color: Config.textMain }
                            }
                        }

                        // Wind Speed Badge
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 32
                            radius: 8
                            color: Qt.rgba(255, 255, 255, 0.04)
                            border.width: 1
                            border.color: Qt.rgba(255, 255, 255, 0.08)

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6
                                Text { text: "air"; font.family: "Material Symbols Outlined"; font.pixelSize: 14; color: Config.accent }
                                Text { text: `Wind: ${Config.weather.windSpeed}`; font.family: Config.sysFont; font.pixelSize: Config.size(Config.fontCaption); color: Config.textMain }
                            }
                        }

                        // UV Index Badge
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 32
                            radius: 8
                            color: Qt.rgba(255, 255, 255, 0.04)
                            border.width: 1
                            border.color: Qt.rgba(255, 255, 255, 0.08)

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6
                                Text { text: "wb_sunny"; font.family: "Material Symbols Outlined"; font.pixelSize: 14; color: Config.accent }
                                Text { text: `UV Index: ${Config.weather.uvIndex}`; font.family: Config.sysFont; font.pixelSize: Config.size(Config.fontCaption); color: Config.textMain }
                            }
                        }
                    }
                }
            }

            // ==========================================
            // 2. LOCATION & GEOLOCATION OVERRIDE CARD
            // ==========================================
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: locCol.implicitHeight + 28
                radius: Config.cornerRadius
                color: Qt.rgba(255, 255, 255, 0.05)
                border.width: 1
                border.color: Qt.rgba(255, 255, 255, 0.1)

                ColumnLayout {
                    id: locCol
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: "LOCATION QUERY & OVERRIDE"
                            font.family: Config.sysFont
                            font.bold: true
                            font.pixelSize: Config.size(Config.fontBody)
                            color: Config.textMain
                        }

                        Text {
                            text: "Specify a city, zipcode (e.g. 90210), or airport code to override IP-based geolocation. Leave empty for automatic IP lookup."
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontCaption)
                            color: Config.textMuted
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }

                    // Input Box with Search Icon and Clear Button
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 42
                        radius: 10
                        color: Qt.rgba(0, 0, 0, 0.25)
                        border.width: 1
                        border.color: zipInput.activeFocus ? Config.accent : Qt.rgba(255, 255, 255, 0.12)

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 10
                            spacing: 8

                            Text {
                                text: "search"
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: 18
                                color: zipInput.activeFocus ? Config.accent : Config.textMuted
                            }

                            TextInput {
                                id: zipInput
                                Layout.fillWidth: true
                                verticalAlignment: Text.AlignVCenter
                                color: Config.textMain
                                font.family: Config.sysFont
                                font.pixelSize: Config.size(Config.fontBody)
                                text: Config.locationQuery
                                selectByMouse: true

                                Connections {
                                    target: Config
                                    function onLocationQueryChanged() {
                                        if (zipInput.text !== Config.locationQuery) {
                                            zipInput.text = Config.locationQuery
                                        }
                                    }
                                }

                                HoverHandler { cursorShape: Qt.IBeamCursor }

                                Text {
                                    anchors.fill: parent
                                    verticalAlignment: Text.AlignVCenter
                                    text: "e.g., 90210, London, Tokyo, or leave blank for Auto IP..."
                                    color: Config.textMuted
                                    font.family: Config.sysFont
                                    font.pixelSize: Config.size(Config.fontBody)
                                    visible: zipInput.text === ""
                                }

                                onEditingFinished: {
                                    if (Config.isLoaded) {
                                        Config.locationQuery = zipInput.text.trim()
                                        Config.weather.fetchWeather(true)
                                    }
                                }
                            }

                            // Clear / Reset Button
                            Rectangle {
                                visible: zipInput.text !== ""
                                implicitWidth: 24
                                implicitHeight: 24
                                radius: 12
                                color: clearHover.hovered ? Qt.rgba(255, 255, 255, 0.15) : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: "close"
                                    font.family: "Material Symbols Outlined"
                                    font.pixelSize: 15
                                    color: Config.textMuted
                                }

                                TapHandler {
                                    onTapped: {
                                        zipInput.text = ""
                                        if (Config.isLoaded) {
                                            Config.locationQuery = ""
                                            Config.weather.fetchWeather(true)
                                        }
                                    }
                                }
                                HoverHandler { id: clearHover; cursorShape: Qt.PointingHandCursor }
                            }
                        }
                    }

                    // Quick Location Preset Chips
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Text {
                            text: "Presets:"
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontMicro)
                            font.bold: true
                            color: Config.textMuted
                        }

                        Repeater {
                            model: [
                                { label: "Auto (IP)", query: "" },
                                { label: "New York", query: "New York" },
                                { label: "London", query: "London" },
                                { label: "Tokyo", query: "Tokyo" },
                                { label: "Paris", query: "Paris" }
                            ]

                            delegate: Rectangle {
                                implicitWidth: chipText.implicitWidth + 14
                                implicitHeight: 24
                                radius: 12
                                color: (Config.locationQuery === modelData.query)
                                    ? Qt.rgba(Config.accent.r, Config.accent.g, Config.accent.b, 0.25)
                                    : (chipHover.hovered ? Qt.rgba(255, 255, 255, 0.1) : Qt.rgba(255, 255, 255, 0.05))
                                border.width: 1
                                border.color: (Config.locationQuery === modelData.query) ? Config.accent : Qt.rgba(255, 255, 255, 0.1)

                                Text {
                                    id: chipText
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    font.family: Config.sysFont
                                    font.pixelSize: 10
                                    font.bold: true
                                    color: (Config.locationQuery === modelData.query) ? Config.accent : Config.textMain
                                }

                                TapHandler {
                                    onTapped: {
                                        if (Config.isLoaded) {
                                            Config.locationQuery = modelData.query
                                            zipInput.text = modelData.query
                                            Config.weather.fetchWeather(true)
                                        }
                                    }
                                }
                                HoverHandler { id: chipHover; cursorShape: Qt.PointingHandCursor }
                            }
                        }
                    }
                }
            }

            // ==========================================
            // 3. SERVICE TELEMETRY & INFO CARD
            // ==========================================
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: infoRow.implicitHeight + 20
                radius: Config.cornerRadius
                color: Qt.rgba(255, 255, 255, 0.03)
                border.width: 1
                border.color: Qt.rgba(255, 255, 255, 0.06)

                RowLayout {
                    id: infoRow
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    Text {
                        text: "info"
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 20
                        color: Config.accent
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: "AUTOMATIC TELEMETRY REFRESH"
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontMicro)
                            font.bold: true
                            color: Config.textMain
                        }

                        Text {
                            text: "Weather metrics automatically synchronize every 15 minutes via wttr.in and update the calendar, desktop widgets, and status bar."
                            font.family: Config.sysFont
                            font.pixelSize: Config.size(Config.fontMicro)
                            color: Config.textMuted
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }
                }
            }
        }
    }
}