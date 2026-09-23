import QtQuick
import QtQuick.Layouts
import "../../"
import "../shared"

Item {
    id: root

    function _timeStr(hours) {
        if (hours < 0)
            return "";
        var h = Math.floor(hours);
        var m = Math.round((hours - h) * 60);
        if (h > 0 && m > 0)
            return h + "h " + m + "m";
        if (h > 0)
            return h + "h";
        return m + "m";
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        PanelHeader {
            Layout.fillWidth: true
            breadcrumb: I18n.t("battery.breadcrumb")
            title: I18n.t("battery.title")
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: UIScale.spacingMd
            Layout.rightMargin: UIScale.spacingMd
            Layout.topMargin: UIScale.spacingSm
            Layout.bottomMargin: UIScale.spacingLg
            spacing: UIScale.spacingSm

            // Main status card
            Rectangle {
                Layout.fillWidth: true
                radius: UIScale.radiusMd
                color: Colors.surface
                implicitHeight: mainInner.implicitHeight + Math.round(24 * UIScale.value)

                ColumnLayout {
                    id: mainInner
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: UIScale.radiusMd
                    }
                    spacing: UIScale.spacingXs

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: UIScale.spacingSm

                        Text {
                            text: BatteryService.icon
                            font.pixelSize: Math.round(28 * UIScale.value)
                            color: {
                                if (!BatteryService.available)
                                    return Colors.muted;
                                if (BatteryService.charging || BatteryService.full)
                                    return Colors.accent;
                                if (BatteryService.percent <= 15)
                                    return "#e05c5c";
                                return Colors.text;
                            }
                        }

                        Column {
                            Layout.fillWidth: true
                            spacing: Math.round(2 * UIScale.value)

                            Text {
                                text: BatteryService.available ? BatteryService.percent + "%" : I18n.t("battery.noBattery")
                                color: Colors.text
                                font.pixelSize: UIScale.fontHero
                                font.weight: Font.ExtraBold
                            }

                            Text {
                                text: {
                                    if (!BatteryService.available)
                                        return I18n.t("battery.notDetected");
                                    if (BatteryService.full)
                                        return I18n.t("battery.fullyCharged");
                                    var t = root._timeStr(BatteryService.hoursRemaining);
                                    if (BatteryService.charging)
                                        return t ? I18n.t("battery.untilFull", [t]) : I18n.t("battery.charging");
                                    return t ? I18n.t("battery.remaining", [t]) : BatteryService.status;
                                }
                                color: Colors.textDim
                                font.pixelSize: UIScale.fontSmall
                            }
                        }
                    }

                    // Progress bar
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: UIScale.spacingSm
                        radius: UIScale.spacingXs
                        color: Colors.surfaceHigh
                        visible: BatteryService.available

                        Rectangle {
                            width: parent.width * (BatteryService.percent / 100)
                            height: parent.height
                            radius: parent.radius
                            color: {
                                if (BatteryService.charging || BatteryService.full)
                                    return Colors.accent;
                                if (BatteryService.percent <= 15)
                                    return "#e05c5c";
                                if (BatteryService.percent <= 30)
                                    return "#e0a85c";
                                return Colors.accent;
                            }
                            Behavior on width {
                                NumberAnimation {
                                    duration: Anim.slow
                                    easing.type: Easing.OutCubic
                                }
                            }
                            Behavior on color {
                                ColorAnimation {
                                    duration: Anim.fast
                                }
                            }
                        }
                    }
                }
            }

            // Detail row
            Rectangle {
                Layout.fillWidth: true
                radius: UIScale.radiusMd
                color: Colors.surface
                implicitHeight: Math.round(44 * UIScale.value)
                visible: BatteryService.available

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: UIScale.spacingMd
                    anchors.rightMargin: UIScale.spacingMd

                    Text {
                        text: I18n.t("battery.statusLabel")
                        color: Colors.textDim
                        font.pixelSize: UIScale.fontTiny
                        font.weight: Font.Medium
                        Layout.fillWidth: true
                    }

                    Text {
                        text: BatteryService.status
                        color: Colors.text
                        font.pixelSize: UIScale.fontTiny
                        font.weight: Font.DemiBold
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                radius: UIScale.radiusMd
                color: Colors.surface
                implicitHeight: Math.round(44 * UIScale.value)
                visible: BatteryService.available && BatteryService.powerW > 0

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: UIScale.spacingMd
                    anchors.rightMargin: UIScale.spacingMd

                    Text {
                        text: BatteryService.charging ? I18n.t("battery.chargingRate") : I18n.t("battery.powerDraw")
                        color: Colors.textDim
                        font.pixelSize: UIScale.fontTiny
                        font.weight: Font.Medium
                        Layout.fillWidth: true
                    }

                    Text {
                        text: BatteryService.powerW.toFixed(2) + " W"
                        color: Colors.text
                        font.pixelSize: UIScale.fontTiny
                        font.weight: Font.DemiBold
                        font.family: "monospace"
                    }
                }
            }

            Item {
                Layout.fillHeight: true
            }
        }
    }
}
