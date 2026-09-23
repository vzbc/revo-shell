pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../calendar"
import "../home"
import "../shared"
import "../../"

Item {
    id: root

    implicitWidth: clockWidget.implicitWidth
    implicitHeight: clockWidget.implicitHeight

    Clock {
        id: clockWidget
        anchors.fill: parent
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: popup.visible ? popup.close() : popup.open()
    }

    AnimatedPopup {
        id: popup
        anchorItem: root
        grabFocus: false
        implicitWidth: Math.round(264 * UIScale.value)
        implicitHeight: Math.round(346 * UIScale.value)
        content: Component {
            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                CalendarMiniGrid {
                    Layout.fillWidth: true
                }

                Divider {
                    Layout.topMargin: UIScale.spacingXs
                }

                Item {
                    Layout.fillWidth: true
                    Layout.topMargin: UIScale.spacingXs
                    Layout.bottomMargin: UIScale.spacingXs
                    implicitHeight: Math.round(32 * UIScale.value)

                    Rectangle {
                        anchors {
                            fill: parent
                            leftMargin: UIScale.panelPad
                            rightMargin: UIScale.panelPad
                        }
                        radius: UIScale.radiusSm
                        color: openHov.hovered ? Colors.withAlpha(Colors.text, 0.08) : "transparent"
                        Behavior on color {
                            ColorAnimation {
                                duration: Anim.fast
                            }
                        }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: UIScale.spacingXs

                            Text {
                                text: ""
                                font.family: "Material Icons"
                                font.pixelSize: Math.round(15 * UIScale.value)
                                color: Colors.textDim
                            }
                            Text {
                                text: I18n.t("clock.openCalendar")
                                color: Colors.textDim
                                font.pixelSize: UIScale.fontSmall
                            }
                        }

                        HoverHandler {
                            id: openHov
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                HomePanelService.requestedSection = "calendar";
                                HomePanelService.open = true;
                                popup.close();
                            }
                        }
                    }
                }
            }
        }
    }
}
