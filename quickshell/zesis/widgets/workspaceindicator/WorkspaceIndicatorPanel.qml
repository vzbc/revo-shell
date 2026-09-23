import QtQuick
import QtQuick.Layouts
import "./disc"
import "../shared"
import "../../"

Item {
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        PanelHeader {
            Layout.fillWidth: true
            breadcrumb: I18n.t("workspaceindicator.breadcrumb")
            title: I18n.t("workspaceindicator.title")
        }

        WorkspaceDiscPanel {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
