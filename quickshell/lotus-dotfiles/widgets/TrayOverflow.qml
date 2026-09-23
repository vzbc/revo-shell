import "../components" as Ui
import QtQuick
import QtQuick.Layouts
import Quickshell

FocusScope {
    id: root

    required property QtObject theme
    required property QtObject trayService
    required property var parentWindow
    readonly property var items: trayService.overflowItems(4)
    readonly property int visibleRows: Math.max(1, Math.min(6, items.length))

    signal closeRequested()

    implicitWidth: 288
    implicitHeight: headerRow.implicitHeight + visibleRows * 48 + theme.space3 * 2 + theme.shadowOffset
    focus: true
    Keys.onEscapePressed: root.closeRequested()

    Ui.RaisedSurface {
        anchors.fill: parent
        theme: root.theme
        fill: root.theme.surface
        surfaceRadius: root.theme.radiusPanel
        padding: root.theme.space3

        ColumnLayout {
            anchors.fill: parent
            spacing: root.theme.space2

            RowLayout {
                id: headerRow

                Layout.fillWidth: true
                spacing: root.theme.space2

                Text {
                    Layout.fillWidth: true
                    text: "Tray items"
                    color: root.theme.ink
                    font.family: root.theme.fontFamily
                    font.pixelSize: root.theme.textMd
                    font.weight: Font.Bold
                }

                Ui.IconButton {
                    theme: root.theme
                    controlSize: 30
                    iconSource: Quickshell.shellDir + "/assets/icons/close.svg"
                    accessibleName: "Close tray overflow"
                    fill: root.theme.surfaceRaised
                    onClicked: root.closeRequested()
                }

            }

            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: root.theme.space1
                boundsBehavior: Flickable.StopAtBounds

                model: ScriptModel {
                    values: root.items
                }

                delegate: Rectangle {
                    id: row

                    required property var modelData

                    width: ListView.view.width
                    height: 44
                    radius: root.theme.radiusControl
                    color: rowPointer.containsMouse ? root.theme.alpha(root.theme.green, 0.42) : root.theme.surfaceRaised
                    border.width: root.theme.borderWidth
                    border.color: root.theme.ink

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: root.theme.space1
                        spacing: root.theme.space2

                        TrayItemButton {
                            theme: root.theme
                            trayService: root.trayService
                            trayItem: row.modelData
                            parentWindow: root.parentWindow
                            controlSize: 32
                            onActivated: root.closeRequested()
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Text {
                                Layout.fillWidth: true
                                text: root.trayService.title(row.modelData)
                                elide: Text.ElideRight
                                color: root.theme.ink
                                font.family: root.theme.fontFamily
                                font.pixelSize: root.theme.textXs
                                font.weight: Font.Bold
                            }

                            Text {
                                visible: root.trayService.description(row.modelData).length > 0
                                Layout.fillWidth: true
                                text: root.trayService.description(row.modelData)
                                elide: Text.ElideRight
                                color: root.theme.inkMuted
                                font.family: root.theme.fontFamily
                                font.pixelSize: 8
                            }

                        }

                    }

                    MouseArea {
                        id: rowPointer

                        anchors.fill: parent
                        anchors.leftMargin: 40
                        hoverEnabled: true
                        onClicked: {
                            if (row.modelData.onlyMenu && row.modelData.hasMenu) {
                                const point = row.mapToItem(null, row.width / 2, row.height);
                                row.modelData.display(root.parentWindow, Math.round(point.x), Math.round(point.y));
                            } else {
                                row.modelData.activate();
                                root.closeRequested();
                            }
                        }
                    }

                }

            }

        }

    }

}
