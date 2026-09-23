import QtQuick
import Quickshell

Shell {
    PanelWindow {
        active: true
        wantsFocus: true
        
        anchors.fill: parent

        // استدعاء المكون المحلي مباشرة بدون تعقيد مسارات
        GuidePopup {
            anchors.fill: parent
        }
    }
}
