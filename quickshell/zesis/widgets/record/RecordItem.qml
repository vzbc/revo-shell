pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../../"
import "../shared"

Item {
    id: root
    implicitWidth: Math.round(30 * UIScale.value)
    implicitHeight: Math.round(30 * UIScale.value)

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: function (mouse) {
            if (mouse.button === Qt.RightButton)
                popup.visible ? popup.close() : popup.open();
            else
                RecordService.toggle();
        }
    }

    Text {
        id: icon
        anchors.centerIn: parent
        text: RecordService.recording ? "󰑈" : "󰻃"
        font.pixelSize: Math.round(15 * UIScale.value)
        color: RecordService.recording ? "#e05555" : (ma.containsMouse || popup.visible ? Colors.accent : Colors.text)
        Behavior on color {
            ColorAnimation {
                duration: Anim.fast
            }
        }
    }

    SequentialAnimation {
        running: RecordService.recording
        loops: Animation.Infinite
        onStopped: icon.opacity = 1.0
        NumberAnimation {
            target: icon
            property: "opacity"
            to: 0.35
            duration: 700
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: icon
            property: "opacity"
            to: 1.0
            duration: 700
            easing.type: Easing.InOutSine
        }
    }

    AnimatedPopup {
        id: popup
        anchorItem: root
        implicitWidth: Math.round(280 * UIScale.value)
        implicitHeight: Math.round(380 * UIScale.value)
        content: Component {
            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                PanelHeader {
                    Layout.fillWidth: true
                    breadcrumb: I18n.t("record.breadcrumb")
                    title: I18n.t("record.title")
                }

                Flickable {
                    id: flick
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentWidth: width
                    contentHeight: col.implicitHeight
                    clip: true
                    flickableDirection: Flickable.VerticalFlick

                    ColumnLayout {
                        id: col
                        width: flick.width
                        spacing: UIScale.spacingSm

                        Item {
                            Layout.fillWidth: true
                            implicitHeight: UIScale.spacingSm
                        }

                        SectionLabel {
                            text: I18n.t("record.encodeDevice")
                            Layout.leftMargin: UIScale.spacingMd
                        }

                        StyledComboBox {
                            id: deviceBox
                            Layout.fillWidth: true
                            Layout.leftMargin: UIScale.spacingMd
                            Layout.rightMargin: UIScale.spacingMd
                            model: {
                                var m = [
                                    {
                                        label: I18n.t("record.autoRecommended"),
                                        value: ""
                                    }
                                ];
                                for (var i = 0; i < RecordService.gpuDevices.length; i++)
                                    m.push(RecordService.gpuDevices[i]);
                                m.push({
                                    label: I18n.t("record.softwareCpu"),
                                    value: "software"
                                });
                                return m;
                            }
                            selectedValue: RecordSettings.device
                            onChosen: value => RecordSettings.setDevice(value)
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: UIScale.spacingMd
                            Layout.rightMargin: UIScale.spacingMd
                            Layout.topMargin: UIScale.spacingXs
                            spacing: UIScale.spacingSm

                            SectionLabel {
                                text: I18n.t("record.quality")
                                Layout.fillWidth: true
                            }

                            StyledTextInput {
                                id: qpInput
                                Layout.fillWidth: false
                                Layout.preferredWidth: Math.round(56 * UIScale.value)
                                field.horizontalAlignment: TextInput.AlignHCenter
                                field.validator: IntValidator {
                                    bottom: 0
                                    top: 51
                                }
                                text: String(RecordSettings.qp)
                                onAccepted: {
                                    if (text.length > 0)
                                        RecordSettings.setQp(parseInt(text));
                                    field.focus = false;
                                }
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            Layout.leftMargin: UIScale.spacingMd
                            Layout.rightMargin: UIScale.spacingMd
                            text: I18n.t("record.qualityHint")
                            color: Colors.muted
                            font.pixelSize: UIScale.fontTiny
                            wrapMode: Text.WordWrap
                        }

                        SectionLabel {
                            text: I18n.t("record.framerateCap")
                            Layout.leftMargin: UIScale.spacingMd
                            Layout.topMargin: UIScale.spacingXs
                        }

                        OptionRow {
                            Layout.fillWidth: true
                            Layout.leftMargin: UIScale.spacingMd
                            Layout.rightMargin: UIScale.spacingMd
                            model: [I18n.t("record.uncapped"), "30", "60"]
                            currentIndex: RecordSettings.fpsCap === 30 ? 1 : (RecordSettings.fpsCap === 60 ? 2 : 0)
                            onActivated: index => RecordSettings.setFpsCap(index === 1 ? 30 : (index === 2 ? 60 : 0))
                        }

                        ActionButton {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.topMargin: UIScale.spacingSm
                            label: I18n.t("record.recordRegion")
                            onActivated: {
                                RecordService.startRegion();
                                popup.close();
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                            implicitHeight: UIScale.spacingSm
                        }
                    }
                }
            }
        }
    }
}
