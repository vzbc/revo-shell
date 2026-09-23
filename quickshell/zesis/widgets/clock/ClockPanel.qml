pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "./"
import "../shared"
import "../../"

Item {
    id: root

    readonly property var _colonOptions: [
        {
            value: "breathe",
            label: I18n.t("clock.colonBreathing")
        },
        {
            value: "on",
            label: I18n.t("clock.colonAlwaysOn")
        },
        {
            value: "off",
            label: I18n.t("clock.colonAlwaysOff")
        },
        {
            value: "hidden",
            label: I18n.t("clock.colonHidden")
        }
    ]
    readonly property var _widthOptions: [
        {
            value: "fixed",
            label: I18n.t("clock.widthFixed")
        },
        {
            value: "fluid",
            label: I18n.t("clock.widthFluid")
        }
    ]
    readonly property var _showDateOptions: [
        {
            value: false,
            label: I18n.t("common.off")
        },
        {
            value: true,
            label: I18n.t("common.on")
        }
    ]
    readonly property var _formatOptions: [
        {
            value: false,
            label: I18n.t("clock.format24")
        },
        {
            value: true,
            label: I18n.t("clock.format12")
        }
    ]

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        PanelHeader {
            Layout.fillWidth: true
            breadcrumb: I18n.t("clock.breadcrumb")
            title: I18n.t("clock.title")
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: bodyCol.implicitHeight + UIScale.panelPad
            clip: true
            flickableDirection: Flickable.VerticalFlick

            ColumnLayout {
                id: bodyCol
                width: parent.width
                spacing: UIScale.spacingMd

                Item {
                    implicitHeight: UIScale.spacingXs
                }

                // Preview card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                    implicitHeight: Math.round(110 * UIScale.value)
                    radius: UIScale.radiusMd
                    color: Colors.withAlpha(Colors.text, 0.03)
                    border.color: Colors.withAlpha(Colors.text, 0.06)
                    border.width: 1

                    Clock {
                        id: preview
                        anchors.centerIn: parent
                    }

                    Text {
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                        anchors.margins: UIScale.spacingSm
                        text: I18n.t("clock.preview")
                        color: Colors.withAlpha(Colors.muted, 0.4)
                        font.pixelSize: UIScale.fontTiny
                        font.letterSpacing: 1.5
                        font.weight: Font.Bold
                    }
                }

                Text {
                    text: I18n.t("clock.appearanceSection")
                    color: Colors.muted
                    font.pixelSize: UIScale.fontTiny
                    font.weight: Font.Bold
                    font.letterSpacing: 1.5
                    Layout.leftMargin: UIScale.panelPad
                    Layout.topMargin: UIScale.spacingXs
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                    implicitHeight: Math.round(56 * UIScale.value)
                    radius: UIScale.radiusMd
                    color: Colors.withAlpha(Colors.text, 0.03)
                    border.color: Colors.withAlpha(Colors.text, 0.06)
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: UIScale.spacingMd
                        anchors.rightMargin: UIScale.spacingMd
                        spacing: UIScale.spacingSm

                        Column {
                            spacing: Math.round(2 * UIScale.value)
                            Text {
                                text: I18n.t("clock.colonLabel")
                                color: Colors.text
                                font.pixelSize: UIScale.fontSmall
                                font.weight: Font.DemiBold
                            }
                            Text {
                                text: I18n.t("clock.colonHint")
                                color: Colors.textDim
                                font.pixelSize: UIScale.fontTiny
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        StyledComboBox {
                            Layout.preferredWidth: Math.round(140 * UIScale.value)
                            model: root._colonOptions
                            selectedValue: ClockSettings.colonMode
                            onChosen: value => ClockSettings.writeColonMode(value)
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                    implicitHeight: Math.round(56 * UIScale.value)
                    radius: UIScale.radiusMd
                    color: Colors.withAlpha(Colors.text, 0.03)
                    border.color: Colors.withAlpha(Colors.text, 0.06)
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: UIScale.spacingMd
                        anchors.rightMargin: UIScale.spacingMd
                        spacing: UIScale.spacingSm

                        Column {
                            spacing: Math.round(2 * UIScale.value)
                            Text {
                                text: I18n.t("clock.widthLabel")
                                color: Colors.text
                                font.pixelSize: UIScale.fontSmall
                                font.weight: Font.DemiBold
                            }
                            Text {
                                text: I18n.t("clock.widthHint")
                                color: Colors.textDim
                                font.pixelSize: UIScale.fontTiny
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        StyledComboBox {
                            Layout.preferredWidth: Math.round(140 * UIScale.value)
                            model: root._widthOptions
                            selectedValue: ClockSettings.widthMode
                            onChosen: value => ClockSettings.writeWidthMode(value)
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                    implicitHeight: Math.round(56 * UIScale.value)
                    radius: UIScale.radiusMd
                    color: Colors.withAlpha(Colors.text, 0.03)
                    border.color: Colors.withAlpha(Colors.text, 0.06)
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: UIScale.spacingMd
                        anchors.rightMargin: UIScale.spacingMd
                        spacing: UIScale.spacingSm

                        Column {
                            spacing: Math.round(2 * UIScale.value)
                            Text {
                                text: I18n.t("clock.showDateLabel")
                                color: Colors.text
                                font.pixelSize: UIScale.fontSmall
                                font.weight: Font.DemiBold
                            }
                            Text {
                                text: I18n.t("clock.showDateHint")
                                color: Colors.textDim
                                font.pixelSize: UIScale.fontTiny
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        StyledComboBox {
                            Layout.preferredWidth: Math.round(140 * UIScale.value)
                            model: root._showDateOptions
                            selectedValue: ClockSettings.showDate
                            onChosen: value => ClockSettings.writeShowDate(value)
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                    implicitHeight: Math.round(56 * UIScale.value)
                    radius: UIScale.radiusMd
                    color: Colors.withAlpha(Colors.text, 0.03)
                    border.color: Colors.withAlpha(Colors.text, 0.06)
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: UIScale.spacingMd
                        anchors.rightMargin: UIScale.spacingMd
                        spacing: UIScale.spacingSm

                        Column {
                            spacing: Math.round(2 * UIScale.value)
                            Text {
                                text: I18n.t("clock.hourFormatLabel")
                                color: Colors.text
                                font.pixelSize: UIScale.fontSmall
                                font.weight: Font.DemiBold
                            }
                            Text {
                                text: I18n.t("clock.hourFormatHint")
                                color: Colors.textDim
                                font.pixelSize: UIScale.fontTiny
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        StyledComboBox {
                            Layout.preferredWidth: Math.round(140 * UIScale.value)
                            model: root._formatOptions
                            selectedValue: ClockSettings.use12Hour
                            onChosen: value => ClockSettings.writeUse12Hour(value)
                        }
                    }
                }

                Text {
                    text: I18n.t("clock.animationTestSection")
                    color: Colors.muted
                    font.pixelSize: UIScale.fontTiny
                    font.weight: Font.Bold
                    font.letterSpacing: 1.5
                    Layout.leftMargin: UIScale.panelPad
                    Layout.topMargin: UIScale.spacingXs
                }

                // Snap row, instantly set what the clock displays
                Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                    implicitHeight: Math.round(56 * UIScale.value)
                    radius: UIScale.radiusMd
                    color: Colors.withAlpha(Colors.text, 0.03)
                    border.color: Colors.withAlpha(Colors.text, 0.06)
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: UIScale.spacingMd
                        anchors.rightMargin: UIScale.spacingMd
                        spacing: UIScale.spacingSm

                        Column {
                            spacing: Math.round(2 * UIScale.value)
                            Layout.preferredWidth: Math.round(52 * UIScale.value)
                            Text {
                                text: I18n.t("clock.snapToLabel")
                                color: Colors.text
                                font.pixelSize: UIScale.fontSmall
                                font.weight: Font.DemiBold
                            }
                            Text {
                                text: I18n.t("clock.snapToHint")
                                color: Colors.textDim
                                font.pixelSize: UIScale.fontTiny
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        TimeSpinner {
                            id: snapH
                            maxVal: 23
                            value: 9
                        }

                        Text {
                            text: ":"
                            color: Colors.muted
                            font.pixelSize: UIScale.fontSubhead
                            font.bold: true
                            verticalAlignment: Text.AlignVCenter
                        }

                        TimeSpinner {
                            id: snapM
                            maxVal: 59
                            value: 59
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        ActionButton {
                            label: I18n.t("clock.snapButton")
                            onActivated: preview.snapTo(snapH.value, snapM.value)
                        }
                    }
                }

                // Animate row, trigger the typewriter animation
                Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                    implicitHeight: Math.round(56 * UIScale.value)
                    radius: UIScale.radiusMd
                    color: Colors.withAlpha(Colors.text, 0.03)
                    border.color: Colors.withAlpha(Colors.text, 0.06)
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: UIScale.spacingMd
                        anchors.rightMargin: UIScale.spacingMd
                        spacing: UIScale.spacingSm

                        Column {
                            spacing: Math.round(2 * UIScale.value)
                            Layout.preferredWidth: Math.round(52 * UIScale.value)
                            Text {
                                text: I18n.t("clock.animateToLabel")
                                color: Colors.text
                                font.pixelSize: UIScale.fontSmall
                                font.weight: Font.DemiBold
                            }
                            Text {
                                text: I18n.t("clock.typewriterHint")
                                color: Colors.textDim
                                font.pixelSize: UIScale.fontTiny
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        TimeSpinner {
                            id: animH
                            maxVal: 23
                            value: 10
                        }

                        Text {
                            text: ":"
                            color: Colors.muted
                            font.pixelSize: UIScale.fontSubhead
                            font.bold: true
                            verticalAlignment: Text.AlignVCenter
                        }

                        TimeSpinner {
                            id: animM
                            maxVal: 59
                            value: 0
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        ActionButton {
                            label: I18n.t("clock.goButton")
                            onActivated: preview.simulateTo(animH.value, animM.value)
                        }
                    }
                }

                // Alt mode test card
                // Rectangle {
                //     Layout.fillWidth: true
                //     Layout.leftMargin: UIScale.panelPad
                //     Layout.rightMargin: UIScale.panelPad
                //     implicitHeight: Math.round(56 * UIScale.value)
                //     radius: UIScale.radiusMd
                //     color: Colors.withAlpha(Colors.accent, 0.04)
                //     border.color: Colors.withAlpha(Colors.accent, 0.14)
                //     border.width: 1

                //     RowLayout {
                //         anchors.fill: parent
                //         anchors.leftMargin: UIScale.spacingMd
                //         anchors.rightMargin: UIScale.spacingMd
                //         spacing: UIScale.spacingSm

                //         Column {
                //             spacing: Math.round(2 * UIScale.value)
                //             Text {
                //                 text: "Alt mode"
                //                 color: Colors.text
                //                 font.pixelSize: UIScale.fontSmall
                //                 font.weight: Font.DemiBold
                //             }
                //             Text {
                //                 text: "Alternate display"
                //                 color: Colors.textDim
                //                 font.pixelSize: UIScale.fontTiny
                //             }
                //         }

                //         Item {
                //             Layout.fillWidth: true
                //         }

                //         Item {
                //             Layout.preferredWidth: UIScale.spacingSm
                //         }

                //         ActionButton {
                //             label: "Trigger"
                //             onActivated: ClockSettings.altModeRequested()
                //         }
                //     }
                // }

                Text {
                    text: I18n.t("clock.desktopClockSection")
                    color: Colors.muted
                    font.pixelSize: UIScale.fontTiny
                    font.weight: Font.Bold
                    font.letterSpacing: 1.5
                    Layout.leftMargin: UIScale.panelPad
                    Layout.topMargin: UIScale.spacingXs
                }

                // Dark preview card so white text is visible
                Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                    implicitHeight: Math.round(140 * UIScale.value)
                    radius: UIScale.radiusMd
                    color: Qt.rgba(0.07, 0.07, 0.09, 1)
                    border.color: Colors.withAlpha(Colors.text, 0.08)
                    border.width: 1

                    DesktopClock {
                        id: desktopPreview
                        anchors.centerIn: parent
                    }

                    Text {
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                        anchors.margins: UIScale.spacingSm
                        text: I18n.t("clock.preview")
                        color: Qt.rgba(1, 1, 1, 0.18)
                        font.pixelSize: UIScale.fontTiny
                        font.letterSpacing: 1.5
                        font.weight: Font.Bold
                    }
                }

                // Desktop clock, midnight rollover test (snap to 23:59 then chain date->time)
                Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: UIScale.panelPad
                    Layout.rightMargin: UIScale.panelPad
                    implicitHeight: Math.round(56 * UIScale.value)
                    radius: UIScale.radiusMd
                    color: Colors.withAlpha(Colors.text, 0.03)
                    border.color: Colors.withAlpha(Colors.text, 0.06)
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: UIScale.spacingMd
                        anchors.rightMargin: UIScale.spacingMd
                        spacing: UIScale.spacingSm

                        Column {
                            spacing: Math.round(2 * UIScale.value)
                            Layout.preferredWidth: Math.round(52 * UIScale.value)
                            Text {
                                text: I18n.t("clock.midnightLabel")
                                color: Colors.text
                                font.pixelSize: UIScale.fontSmall
                                font.weight: Font.DemiBold
                            }
                            Text {
                                text: I18n.t("clock.midnightHint")
                                color: Colors.textDim
                                font.pixelSize: UIScale.fontTiny
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        TimeSpinner {
                            id: dayMonth
                            maxVal: 12
                            value: 6
                        }

                        Text {
                            text: "/"
                            color: Colors.muted
                            font.pixelSize: UIScale.fontSubhead
                            font.bold: true
                            verticalAlignment: Text.AlignVCenter
                        }

                        TimeSpinner {
                            id: dayDay
                            maxVal: 31
                            value: 27
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        ActionButton {
                            label: I18n.t("clock.goButton")
                            onActivated: desktopPreview.simulateMidnight(dayMonth.value - 1, dayDay.value)
                        }
                    }
                }

                Item {
                    implicitHeight: UIScale.spacingXs
                }
            }
        }
    }

    // +/- spinner for a bounded integer value
    component TimeSpinner: RowLayout {
        id: ts
        property int value: 0
        property int maxVal: 23

        spacing: Math.round(3 * UIScale.value)

        Rectangle {
            implicitWidth: Math.round(26 * UIScale.value)
            implicitHeight: Math.round(28 * UIScale.value)
            radius: UIScale.radiusSm
            color: decHov.hovered ? Colors.withAlpha(Colors.text, 0.1) : Colors.surfaceHigh
            Behavior on color {
                ColorAnimation {
                    duration: Anim.fast
                }
            }
            Text {
                anchors.centerIn: parent
                text: "−"
                color: Colors.textDim
                font.pixelSize: UIScale.fontBody
                font.bold: true
            }
            HoverHandler {
                id: decHov
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: ts.value = (ts.value - 1 + ts.maxVal + 1) % (ts.maxVal + 1)
            }
        }

        Rectangle {
            implicitWidth: Math.round(34 * UIScale.value)
            implicitHeight: Math.round(28 * UIScale.value)
            radius: UIScale.radiusSm
            color: Colors.withAlpha(Colors.text, 0.05)
            Text {
                anchors.centerIn: parent
                text: ts.value.toString().padStart(2, "0")
                color: Colors.accent
                font.pixelSize: UIScale.fontSmall
                font.bold: true
                font.family: "monospace"
            }
        }

        Rectangle {
            implicitWidth: Math.round(26 * UIScale.value)
            implicitHeight: Math.round(28 * UIScale.value)
            radius: UIScale.radiusSm
            color: incHov.hovered ? Colors.withAlpha(Colors.text, 0.1) : Colors.surfaceHigh
            Behavior on color {
                ColorAnimation {
                    duration: Anim.fast
                }
            }
            Text {
                anchors.centerIn: parent
                text: "+"
                color: Colors.textDim
                font.pixelSize: UIScale.fontBody
                font.bold: true
            }
            HoverHandler {
                id: incHov
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: ts.value = (ts.value + 1) % (ts.maxVal + 1)
            }
        }
    }
}
