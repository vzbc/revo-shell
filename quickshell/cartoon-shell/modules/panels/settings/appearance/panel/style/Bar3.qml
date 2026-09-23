import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components
import qs.commons

Item {
    id: root
    Layout.fillWidth: true
    Layout.preferredHeight: ScalerService.s(50)
    CustomRectangle {
        id: container
        anchors.fill: parent
        radius: ScalerService.s(12)
        anchors.margins: ScalerService.s(2)

        color: {
            if (Settings.bar.style === "style3") {
                return Qt.alpha(theme.button.text, 0.15);
            }
            return mouseArea.containsMouse ? Qt.alpha(theme.button.background_select, 0.4) : Qt.alpha(theme.button.background, 0.2);
        }
        border.width: Settings.appearance.enableBorder ? ScalerService.s(2) : 0

        RowLayout {
            anchors.margins: ScalerService.s(5)
            spacing: ScalerService.s(8)
            anchors.fill: parent
            opacity: Settings.bar.style === "style3" ? 0.6 : 1
            CustomRectangle {
                anchors.fill: parent
                color: theme.primary.background
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: ScalerService.s(5)
                    Item {
                        Layout.fillHeight: true
                        Layout.preferredWidth: ScalerService.s(25)
                        IconImage {
                            path: "launcher/win11.svg"
                            anchors.centerIn: parent
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Item {
                        Layout.fillHeight: true
                        Layout.preferredWidth: ScalerService.s(70)
                        ColumnLayout {
                            anchors.centerIn: parent
                            CustomText {
                                name: "18:39"
                                size: "xs"
                                Layout.alignment: Qt.AlignHCenter
                            }
                            CustomText {
                                name: "24/01/2034"
                                size: "xs"
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }
                }
            }
        }

        border.color: {
            if (Settings.bar.style === "style3") {
                return Qt.alpha(theme.button.text, 0.8);
            }
            return mouseArea.containsPress ? Qt.alpha(theme.button.border_select, 0.6) : Qt.alpha(theme.button.border, 0.3);
        }

        Behavior on color {
            ColorAnimation {
                duration: 200
            }
        }
        Behavior on border.color {
            ColorAnimation {
                duration: 200
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onClicked: {
                SoundService.playSound("pick");
                Settings.bar.style = "style3";
                Settings.bar.styleWorkspace = "icon";
                Settings.bar.iconWorkspace = "pac_man";
            }
        }

        SequentialAnimation on opacity {
            running: root.animationProgress > 0.1
            NumberAnimation {
                from: 0
                to: 1
                duration: 300
                easing.type: Easing.OutCubic
            }
        }

        SequentialAnimation on scale {
            running: root.animationProgress > 0.1
            NumberAnimation {
                from: 0.5
                to: 1.0
                duration: 400
                easing.type: Easing.OutBack
            }
        }
    }
}
