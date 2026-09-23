import QtQuick
import QtQuick.Layouts
import "../../"
import "../shared"

Item {
    id: root

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        PanelHeader {
            Layout.fillWidth: true
            breadcrumb: I18n.t("brightness.breadcrumb")
            title: I18n.t("brightness.title")
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.leftMargin: UIScale.spacingMd
            Layout.rightMargin: UIScale.spacingMd
            Layout.topMargin: UIScale.spacingSm
            Layout.bottomMargin: UIScale.spacingLg
            spacing: UIScale.spacingSm

            Rectangle {
                Layout.fillWidth: true
                radius: UIScale.radiusMd
                color: Colors.surface
                implicitHeight: card.implicitHeight + Math.round(24 * UIScale.value)

                ColumnLayout {
                    id: card
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: UIScale.radiusMd
                    }
                    spacing: UIScale.spacingSm

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: {
                                var p = BrightnessService.percent;
                                if (p >= 80)
                                    return "󰃠";
                                if (p >= 40)
                                    return "󰃟";
                                return "󰃞";
                            }
                            font.pixelSize: Math.round(20 * UIScale.value)
                            color: Colors.accent
                        }

                        Text {
                            text: I18n.t("brightness.title")
                            color: Colors.text
                            font.pixelSize: UIScale.fontBody
                            font.weight: Font.Bold
                            Layout.fillWidth: true
                        }

                        Text {
                            text: BrightnessService.available ? BrightnessService.percent + "%" : "-"
                            color: Colors.accent
                            font.pixelSize: UIScale.fontBody
                            font.weight: Font.Bold
                            font.family: "monospace"
                        }
                    }

                    SettingSlider {
                        Layout.fillWidth: true
                        from: 1
                        to: 100
                        step: 1
                        value: BrightnessService.percent
                        muted: !BrightnessService.available
                        onMoved: function (v) {
                            BrightnessService.set(v);
                        }
                        onWheeled: function (delta) {
                            BrightnessService.adjust(delta > 0 ? 5 : -5);
                        }
                    }
                }
            }

            Text {
                text: I18n.t("brightness.noBacklightDevice")
                color: Colors.textDim
                font.pixelSize: UIScale.fontSmall
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
                visible: !BrightnessService.available
            }

            Item {
                Layout.fillHeight: true
            }
        }
    }
}
