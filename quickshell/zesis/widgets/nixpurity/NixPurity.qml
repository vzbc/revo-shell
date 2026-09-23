pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../../"
import "../shared"

Item {
    id: root

    readonly property var svc: NixPurityService
    readonly property var tier: root.svc.currentTier

    readonly property color _barColor: {
        var p = root.svc.purity;
        // blend from reddish (#e06c75) at 0% to accent at 100%
        return Qt.rgba((1 - p) * 0.88 + p * Colors.accent.r, (1 - p) * 0.43 + p * Colors.accent.g, (1 - p) * 0.46 + p * Colors.accent.b, 1);
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        PanelHeader {
            Layout.fillWidth: true
            breadcrumb: I18n.t("nixpurity.breadcrumb")
            title: I18n.t("nixpurity.title")
        }

        // Scanning spinner
        Item {
            visible: root.svc.scanning
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                anchors.centerIn: parent
                spacing: UIScale.spacingMd

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: I18n.t("nixpurity.auditing")
                    color: Colors.textDim
                    font.pixelSize: UIScale.fontBody
                    font.italic: true
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: I18n.t("nixpurity.pureDirtyCounter", [root.svc.pureCount, root.svc.dirtyCount])
                    color: Colors.muted
                    font.pixelSize: UIScale.fontCaption
                    font.family: "monospace"
                }
            }
        }

        // Results
        Item {
            visible: root.svc.isNixOS && !root.svc.scanning
            Layout.fillWidth: true
            Layout.fillHeight: true

            Flickable {
                anchors.fill: parent
                contentHeight: resultCol.implicitHeight
                clip: true

                ColumnLayout {
                    id: resultCol
                    width: parent.width
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: UIScale.panelPad
                    anchors.rightMargin: UIScale.panelPad
                    spacing: UIScale.spacingMd

                    // Top padding
                    Item {
                        implicitHeight: UIScale.spacingLg
                    }

                    // Tier name
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.tier?.greek ?? ""
                        color: root._barColor
                        font.pixelSize: Math.round(34 * UIScale.value)
                        font.weight: Font.Bold
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.tier?.title ?? ""
                        color: Colors.text
                        font.pixelSize: UIScale.fontTitle
                        font.weight: Font.ExtraBold
                    }

                    // Purity bar
                    Item {
                        Layout.fillWidth: true
                        implicitHeight: Math.round(8 * UIScale.value)
                        Layout.topMargin: UIScale.spacingSm

                        Rectangle {
                            anchors.fill: parent
                            radius: height / 2
                            color: Colors.withAlpha(Colors.text, 0.07)
                        }

                        Rectangle {
                            width: parent.width * root.svc.purity
                            height: parent.height
                            radius: height / 2
                            color: root._barColor

                            Behavior on width {
                                NumberAnimation {
                                    duration: 600
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                    }

                    // Score
                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: I18n.t("nixpurity.percentPure", [Math.round(root.svc.displayPurity * 100)])
                            color: root._barColor
                            font.pixelSize: UIScale.fontSubhead
                            font.weight: Font.DemiBold
                            font.family: "monospace"
                        }
                        Rectangle {
                            visible: root.svc.usesHjem
                            implicitWidth: hjemLabel.implicitWidth + Math.round(12 * UIScale.value)
                            implicitHeight: Math.round(18 * UIScale.value)
                            radius: height / 2
                            color: Colors.withAlpha(Colors.accent, 0.12)
                            border.color: Colors.withAlpha(Colors.accent, 0.28)
                            border.width: 1

                            Text {
                                id: hjemLabel
                                anchors.centerIn: parent
                                text: I18n.t("nixpurity.hjemBadge")
                                color: Colors.accent
                                font.pixelSize: UIScale.fontTiny
                                font.weight: Font.Medium
                            }
                        }
                        Item {
                            Layout.fillWidth: true
                        }
                        Text {
                            text: I18n.t("nixpurity.managedTotal", [root.svc.pureCount, root.svc.pureCount + root.svc.dirtyCount])
                            color: Colors.muted
                            font.pixelSize: UIScale.fontCaption
                            font.family: "monospace"
                        }
                    }

                    // Taunt
                    Text {
                        Layout.fillWidth: true
                        text: root.tier?.taunt ?? ""
                        color: Colors.textDim
                        font.pixelSize: UIScale.fontBody
                        font.italic: true
                        wrapMode: Text.WordWrap
                        Layout.topMargin: UIScale.spacingXs
                    }

                    Divider {
                        Layout.topMargin: UIScale.spacingSm
                    }

                    // Top offenders breakdown
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: UIScale.spacingXs
                        visible: root.svc.topOffenders.length > 0

                        Text {
                            text: I18n.t("nixpurity.topOffenders")
                            color: Colors.muted
                            font.pixelSize: UIScale.fontTiny
                            font.weight: Font.Bold
                            font.letterSpacing: 1.5
                        }

                        Repeater {
                            model: root.svc.topOffenders
                            delegate: RowLayout {
                                id: offenderRow
                                required property var modelData
                                Layout.fillWidth: true
                                spacing: UIScale.spacingSm

                                Text {
                                    text: offenderRow.modelData[0]
                                    color: Colors.textDim
                                    font.pixelSize: UIScale.fontCaption
                                    font.family: "monospace"
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                                Text {
                                    text: offenderRow.modelData[1]
                                    color: Colors.withAlpha(Colors.muted, 0.8)
                                    font.pixelSize: UIScale.fontCaption
                                    font.family: "monospace"
                                }
                                Rectangle {
                                    implicitWidth: Math.round(46 * UIScale.value)
                                    implicitHeight: Math.round(18 * UIScale.value)
                                    radius: UIScale.radiusSm
                                    color: ignoreHover.hovered ? Colors.withAlpha(Colors.muted, 0.18) : Colors.withAlpha(Colors.muted, 0.07)
                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 100
                                        }
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: I18n.t("nixpurity.ignoreAction")
                                        color: ignoreHover.hovered ? Colors.textDim : Colors.muted
                                        font.pixelSize: UIScale.fontTiny
                                        Behavior on color {
                                            ColorAnimation {
                                                duration: 100
                                            }
                                        }
                                    }
                                    HoverHandler {
                                        id: ignoreHover
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: NixPurityService.ignore(offenderRow.modelData[0])
                                    }
                                }
                            }
                        }
                    }

                    // Ignored apps, always visible so user can restore even at 100%
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: UIScale.spacingXs
                        visible: root.svc.ignoredApps.length > 0

                        Text {
                            text: I18n.t("nixpurity.ignoredHeader")
                            color: Colors.withAlpha(Colors.muted, 0.5)
                            font.pixelSize: UIScale.fontTiny
                            font.weight: Font.Bold
                            font.letterSpacing: 1.5
                        }

                        Repeater {
                            model: root.svc.ignoredApps
                            delegate: RowLayout {
                                id: ignoredRow
                                required property string modelData
                                Layout.fillWidth: true
                                spacing: UIScale.spacingSm

                                Text {
                                    text: ignoredRow.modelData
                                    color: Colors.withAlpha(Colors.textDim, 0.4)
                                    font.pixelSize: UIScale.fontCaption
                                    font.family: "monospace"
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                    font.strikeout: true
                                }
                                Rectangle {
                                    implicitWidth: Math.round(46 * UIScale.value)
                                    implicitHeight: Math.round(18 * UIScale.value)
                                    radius: UIScale.radiusSm
                                    color: restoreHover.hovered ? Colors.withAlpha(Colors.accent, 0.15) : Colors.withAlpha(Colors.muted, 0.07)
                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 100
                                        }
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: I18n.t("nixpurity.restoreAction")
                                        color: restoreHover.hovered ? Colors.accent : Colors.muted
                                        font.pixelSize: UIScale.fontTiny
                                        Behavior on color {
                                            ColorAnimation {
                                                duration: 100
                                            }
                                        }
                                    }
                                    HoverHandler {
                                        id: restoreHover
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: NixPurityService.unignore(ignoredRow.modelData)
                                    }
                                }
                            }
                        }
                    }

                    Divider {}

                    // Dirty files list
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: UIScale.spacingXs
                        visible: root.svc.dirtyCount > 0

                        Text {
                            text: I18n.t("nixpurity.impureFiles")
                            color: Colors.muted
                            font.pixelSize: UIScale.fontTiny
                            font.weight: Font.Bold
                            font.letterSpacing: 1.5
                        }

                        Repeater {
                            model: root.svc.dirtyFiles
                            delegate: Text {
                                required property string modelData
                                Layout.fillWidth: true
                                text: modelData
                                color: Colors.withAlpha(Colors.textDim, 0.7)
                                font.pixelSize: UIScale.fontCaption
                                font.family: "monospace"
                                elide: Text.ElideMiddle
                            }
                        }

                        Text {
                            visible: root.svc.dirtyCount > root.svc.dirtyFiles.length
                            text: I18n.t("nixpurity.andMoreForShame", [root.svc.dirtyCount - root.svc.dirtyFiles.length])
                            color: Colors.withAlpha(Colors.muted, 0.7)
                            font.pixelSize: UIScale.fontCaption
                            font.italic: true
                        }
                    }

                    Text {
                        visible: root.svc.dirtyCount === 0 && root.svc.pureCount > 0
                        Layout.fillWidth: true
                        text: I18n.t("nixpurity.noImpureFiles")
                        color: Colors.withAlpha(Colors.textDim, 0.6)
                        font.pixelSize: UIScale.fontBody
                        font.italic: true
                        horizontalAlignment: Text.AlignHCenter
                    }

                    // Re-scan button
                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: UIScale.spacingSm
                        Layout.bottomMargin: UIScale.spacingLg
                        implicitHeight: Math.round(32 * UIScale.value)
                        implicitWidth: Math.round(100 * UIScale.value)
                        radius: UIScale.radiusMd
                        color: rescanHover.hovered ? Colors.withAlpha(Colors.accent, 0.18) : Colors.withAlpha(Colors.text, 0.06)
                        border.color: rescanHover.hovered ? Colors.withAlpha(Colors.accent, 0.4) : Colors.withAlpha(Colors.text, 0.08)
                        border.width: 1

                        Behavior on color {
                            ColorAnimation {
                                duration: 120
                            }
                        }
                        Behavior on border.color {
                            ColorAnimation {
                                duration: 120
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: I18n.t("nixpurity.rescan")
                            color: rescanHover.hovered ? Colors.accent : Colors.textDim
                            font.pixelSize: UIScale.fontSmall
                            font.weight: Font.Medium
                            Behavior on color {
                                ColorAnimation {
                                    duration: 120
                                }
                            }
                        }

                        HoverHandler {
                            id: rescanHover
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: NixPurityService.scan()
                        }
                    }
                }
            }
        }
    }
}
