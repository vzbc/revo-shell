import QtQuick
import QtQuick.Layouts
import "../../"
import "../shared"

// Right-side companion to CommunityPanel's settingsCard, aggregate,
// read-only network stats pulled from diaspora's public GET /stats (see
// DiasporaStatsService).
// Note: Nothing here is really personal. Every number is already
// derivable by just counting GET /locations yourself (see diaspora's
// README "Stats"), this panel just saves the arithmetic and the
// bandwidth.
Rectangle {
    id: root

    width: Math.round(260 * UIScale.value)
    height: column.implicitHeight + UIScale.spacingMd * 2
    radius: UIScale.radiusMd
    color: Colors.withAlpha(Colors.bg, 0.8)
    border.color: Colors.outline
    border.width: 1
    clip: true

    function _fmt(n) {
        var s = String(Math.round(n));
        return s.replace(/\B(?=(\d{3})+(?!\d))/g, ",");
    }

    readonly property real _activePct: DiasporaStatsService.totalEntries > 0 ? (DiasporaStatsService.activeEntries / DiasporaStatsService.totalEntries * 100) : 0

    ColumnLayout {
        id: column
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: UIScale.spacingMd
        spacing: UIScale.spacingMd

        RowLayout {
            Layout.fillWidth: true
            spacing: UIScale.spacingSm

            Text {
                Layout.fillWidth: true
                text: I18n.t("diaspora.network")
                color: Colors.accent
                font.pixelSize: UIScale.fontTiny
                font.capitalization: Font.AllUppercase
                font.letterSpacing: 1.5
            }

            Text {
                visible: DiasporaStatsService.lastFetchFailed
                text: I18n.t("diaspora.offline")
                color: Colors.textDim
                font.pixelSize: UIScale.fontTiny
            }
        }

        // Empty/first-load state
        Text {
            Layout.fillWidth: true
            visible: DiasporaStatsService.totalEntries === 0 && DiasporaStatsService.loading
            text: I18n.t("diaspora.loadingNetworkStats")
            color: Colors.textDim
            font.pixelSize: UIScale.fontSmall
        }

        ColumnLayout {
            Layout.fillWidth: true
            visible: !(DiasporaStatsService.totalEntries === 0 && DiasporaStatsService.loading)
            spacing: UIScale.spacingMd

            // Headline count
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    text: root._fmt(DiasporaStatsService.totalEntries)
                    color: Colors.text
                    font.pixelSize: UIScale.fontHero
                    font.weight: Font.Bold
                }
                Text {
                    text: I18n.t("diaspora.dotsOnTheMap")
                    color: Colors.textDim
                    font.pixelSize: UIScale.fontSmall
                }
            }

            // Verified/active + donut
            RowLayout {
                Layout.fillWidth: true
                spacing: UIScale.spacingMd

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: UIScale.spacingSm

                    RowLayout {
                        spacing: UIScale.spacingSm
                        Text {
                            text: root._fmt(DiasporaStatsService.verifiedEntries)
                            color: Colors.text
                            font.pixelSize: UIScale.fontSubhead
                            font.weight: Font.DemiBold
                        }
                        Text {
                            text: I18n.t("diaspora.verified")
                            color: Colors.textDim
                            font.pixelSize: UIScale.fontSmall
                        }
                    }

                    RowLayout {
                        spacing: UIScale.spacingSm
                        Text {
                            text: root._fmt(DiasporaStatsService.activeEntries)
                            color: Colors.text
                            font.pixelSize: UIScale.fontSubhead
                            font.weight: Font.DemiBold
                        }
                        Text {
                            text: I18n.t("diaspora.active")
                            color: Colors.textDim
                            font.pixelSize: UIScale.fontSmall
                        }
                    }
                }

                DonutChart {
                    Layout.preferredWidth: Math.round(76 * UIScale.value)
                    Layout.preferredHeight: Math.round(76 * UIScale.value)
                    segments: [
                        {
                            color: Colors.accent,
                            value: root._activePct
                        }
                    ]
                    total: 100
                    centerText: Math.round(root._activePct) + "%"
                    subText: I18n.t("diaspora.active")
                }
            }

            // Shell breakdown
            ColumnLayout {
                Layout.fillWidth: true
                visible: DiasporaStatsService.shellStats.length > 0
                spacing: UIScale.spacingSm

                Text {
                    text: I18n.t("diaspora.shells")
                    color: Colors.accent
                    font.pixelSize: UIScale.fontTiny
                    font.capitalization: Font.AllUppercase
                    font.letterSpacing: 1.5
                }

                Repeater {
                    model: DiasporaStatsService.shellStats

                    ColumnLayout {
                        id: shellRow
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: Math.round(3 * UIScale.value)

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                Layout.fillWidth: true
                                text: shellRow.modelData.value
                                color: Colors.text
                                font.pixelSize: UIScale.fontSmall
                                elide: Text.ElideRight
                            }
                            Text {
                                text: root._fmt(shellRow.modelData.total)
                                color: Colors.textDim
                                font.pixelSize: UIScale.fontSmall
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: Math.round(4 * UIScale.value)
                            radius: Math.round(2 * UIScale.value)
                            color: Colors.surfaceHigh

                            Rectangle {
                                width: parent.width * (DiasporaStatsService.totalEntries > 0 ? shellRow.modelData.total / DiasporaStatsService.totalEntries : 0)
                                height: parent.height
                                radius: parent.radius
                                color: Colors.accent
                                Behavior on width {
                                    NumberAnimation {
                                        duration: Anim.fast
                                        easing.type: Easing.OutQuad
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
