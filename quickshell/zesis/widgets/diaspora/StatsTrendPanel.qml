import QtQuick
import QtQuick.Layouts
import "../../"

// Bottom-anchored companion to StatsPanel same data source
// as StatsPanel (see DiasporaStatsService).
Rectangle {
    id: root

    width: Math.round(520 * UIScale.value)
    height: column.implicitHeight + UIScale.spacingMd * 2
    radius: UIScale.radiusMd
    color: Colors.withAlpha(Colors.bg, 0.8)
    border.color: Colors.outline
    border.width: 1
    clip: true
    visible: DiasporaStatsService.dailyHistory.length > 1

    function _dayLabel(unixSecs) {
        return Qt.formatDateTime(new Date(unixSecs * 1000), "MMM d");
    }

    ColumnLayout {
        id: column
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: UIScale.spacingMd
        spacing: UIScale.spacingSm

        Text {
            text: I18n.t("diaspora.trend")
            color: Colors.accent
            font.pixelSize: UIScale.fontTiny
            font.capitalization: Font.AllUppercase
            font.letterSpacing: 1.5
        }

        DailyStatsChart {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.round(64 * UIScale.value)
            points: DiasporaStatsService.dailyHistory
        }

        RowLayout {
            Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                text: DiasporaStatsService.dailyHistory.length > 0 ? root._dayLabel(DiasporaStatsService.dailyHistory[0].dayStartUnix) : ""
                color: Colors.textDim
                font.pixelSize: UIScale.fontCaption
            }
            Text {
                text: DiasporaStatsService.dailyHistory.length > 0 ? root._dayLabel(DiasporaStatsService.dailyHistory[DiasporaStatsService.dailyHistory.length - 1].dayStartUnix) : ""
                color: Colors.textDim
                font.pixelSize: UIScale.fontCaption
            }
        }
    }
}
