pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../"
import "../bar"

Item {
    id: root

    readonly property bool available: AirPodsService.connected
    visible: available
    implicitWidth: available ? pill.implicitWidth : 0
    implicitHeight: Math.round(30 * UIScale.value)

    // bar indicator

    Rectangle {
        id: pill
        anchors.centerIn: parent
        implicitWidth: pillRow.implicitWidth + UIScale.spacingMd
        implicitHeight: Math.round(22 * UIScale.value)
        radius: 100
        color: pillHover.hovered || apPopup.visible ? Colors.withAlpha(Colors.text, 0.1) : "transparent"
        Behavior on color {
            ColorAnimation {
                duration: Anim.fast
            }
        }

        RowLayout {
            id: pillRow
            anchors.centerIn: parent
            spacing: Math.round(5 * UIScale.value)

            Text {
                text: "󱡏"
                font.pixelSize: Math.round(14 * UIScale.value)
                color: Colors.accent
            }

            // Left pod %
            Text {
                visible: !BarConfig.isVertical
                text: AirPodsService.leftLevel + "%"
                font.pixelSize: UIScale.fontTiny
                font.weight: Font.DemiBold
                color: AirPodsService.leftCharging ? Colors.accent : Colors.text
                opacity: AirPodsService.leftEar ? 1.0 : 0.35
                Behavior on opacity {
                    NumberAnimation {
                        duration: Anim.fast
                    }
                }
                Behavior on color {
                    ColorAnimation {
                        duration: Anim.fast
                    }
                }
            }

            // Right pod %
            Text {
                visible: !BarConfig.isVertical
                text: AirPodsService.rightLevel + "%"
                font.pixelSize: UIScale.fontTiny
                font.weight: Font.DemiBold
                color: AirPodsService.rightCharging ? Colors.accent : Colors.text
                opacity: AirPodsService.rightEar ? 1.0 : 0.35
                Behavior on opacity {
                    NumberAnimation {
                        duration: Anim.fast
                    }
                }
                Behavior on color {
                    ColorAnimation {
                        duration: Anim.fast
                    }
                }
            }
        }

        HoverHandler {
            id: pillHover
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: apPopup.visible ? apPopup.close() : apPopup.open()
        }
    }

    // popup

    PopupWindow {
        id: apPopup
        anchor.item: root
        anchor.rect.x: {
            if (BarConfig.side === "left")
                return root.width;
            if (BarConfig.side === "right")
                return -apPopup.implicitWidth;
            return root.width / 2 - apPopup.implicitWidth / 2;
        }
        anchor.rect.y: {
            if (BarConfig.side === "bottom")
                return -apPopup.implicitHeight;
            if (BarConfig.isVertical)
                return root.height / 2 - apPopup.implicitHeight / 2;
            return root.height;
        }
        grabFocus: true
        visible: false
        color: "transparent"

        property string _barSide: BarConfig.side
        on_BarSideChanged: apPopup.close()
        implicitWidth: Math.round(260 * UIScale.value)
        implicitHeight: apContent.implicitHeight

        function open() {
            if (!visible) {
                apContent.scale = 0;
                apContent.opacity = 0;
                visible = true;
            }
            apShowAnim.start();
        }

        function close() {
            if (!visible)
                return;
            apShowAnim.stop();
            visible = false;
        }

        onVisibleChanged: {
            if (!visible) {
                apContent.scale = 0;
                apContent.opacity = 0;
            }
        }

        ParallelAnimation {
            id: apShowAnim
            NumberAnimation {
                target: apContent
                property: "scale"
                to: 1
                duration: Anim.slow
                easing.type: Easing.OutBack
                easing.overshoot: 1.4
            }
            NumberAnimation {
                target: apContent
                property: "opacity"
                to: 1
                duration: Anim.medium
                easing.type: Easing.OutCubic
            }
        }

        Item {
            id: apContent
            anchors.left: parent.left
            anchors.right: parent.right
            implicitHeight: popupCol.implicitHeight
            scale: 0
            opacity: 0
            transformOrigin: {
                if (BarConfig.side === "bottom")
                    return Item.Bottom;
                if (BarConfig.side === "left")
                    return Item.Left;
                if (BarConfig.side === "right")
                    return Item.Right;
                return Item.Top;
            }

            Rectangle {
                anchors.fill: parent
                radius: UIScale.radiusLg
                topLeftRadius: (BarConfig.side === "top" || BarConfig.side === "left") ? 0 : UIScale.radiusLg
                topRightRadius: (BarConfig.side === "top" || BarConfig.side === "right") ? 0 : UIScale.radiusLg
                bottomLeftRadius: (BarConfig.side === "bottom" || BarConfig.side === "left") ? 0 : UIScale.radiusLg
                bottomRightRadius: (BarConfig.side === "bottom" || BarConfig.side === "right") ? 0 : UIScale.radiusLg
                color: Colors.bg
                border.color: Colors.outline
                border.width: 1
            }

            ColumnLayout {
                id: popupCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: UIScale.spacingMd
                spacing: UIScale.spacingSm

                // Header
                RowLayout {
                    Layout.fillWidth: true
                    spacing: UIScale.spacingSm

                    Text {
                        text: "󰋋"
                        font.pixelSize: Math.round(22 * UIScale.value)
                        color: Colors.accent
                    }

                    Column {
                        Layout.fillWidth: true
                        spacing: Math.round(2 * UIScale.value)

                        Text {
                            text: AirPodsService.deviceName || "AirPods"
                            color: Colors.text
                            font.pixelSize: UIScale.fontSmall
                            font.weight: Font.Bold
                        }

                        Text {
                            text: {
                                const l = AirPodsService.leftEar;
                                const r = AirPodsService.rightEar;
                                if (l && r)
                                    return I18n.t("airpods.bothInEar");
                                if (l)
                                    return I18n.t("airpods.leftInEar");
                                if (r)
                                    return I18n.t("airpods.rightInEar");
                                return I18n.t("airpods.notInEar");
                            }
                            color: Colors.textDim
                            font.pixelSize: UIScale.fontTiny
                        }
                    }
                }

                // Divider
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: Colors.outline
                }

                // Battery rows
                BatteryRow {
                    Layout.fillWidth: true
                    label: I18n.t("airpods.left")
                    level: AirPodsService.leftLevel
                    charging: AirPodsService.leftCharging
                    inEar: AirPodsService.leftEar
                }

                BatteryRow {
                    Layout.fillWidth: true
                    label: I18n.t("airpods.right")
                    level: AirPodsService.rightLevel
                    charging: AirPodsService.rightCharging
                    inEar: AirPodsService.rightEar
                }

                BatteryRow {
                    Layout.fillWidth: true
                    label: I18n.t("airpods.case")
                    level: AirPodsService.caseLevel
                    charging: AirPodsService.caseCharging
                    inEar: true
                    visible: AirPodsService.caseLevel > 0
                }

                Item {
                    implicitHeight: UIScale.spacingXs
                }
            }
        }
    }

    // battery row component

    component BatteryRow: ColumnLayout {
        property string label: ""
        property int level: 0
        property bool charging: false
        property bool inEar: true

        spacing: Math.round(3 * UIScale.value)

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: parent.parent.label
                color: parent.parent.inEar ? Colors.text : Colors.textDim
                font.pixelSize: UIScale.fontTiny
                font.weight: Font.Medium
                Layout.fillWidth: true
                Behavior on color {
                    ColorAnimation {
                        duration: Anim.fast
                    }
                }
            }

            Text {
                text: parent.parent.charging ? "󱐋 " + parent.parent.level + "%" : parent.parent.level + "%"
                color: parent.parent.charging ? Colors.accent : Colors.text
                font.pixelSize: UIScale.fontTiny
                font.weight: Font.DemiBold
                font.family: "monospace"
                Behavior on color {
                    ColorAnimation {
                        duration: Anim.fast
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: Math.round(4 * UIScale.value)
            radius: 2
            color: Colors.surfaceHigh

            Rectangle {
                width: parent.width * (parent.parent.level / 100)
                height: parent.height
                radius: parent.radius
                color: {
                    if (parent.parent.charging)
                        return Colors.accent;
                    if (parent.parent.level <= 15)
                        return "#e05c5c";
                    if (parent.parent.level <= 30)
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
