import QtQuick
import Quickshell
import "./guide" // تحديد المسار النسبي المباشر من نفس المجلد

Shell {
    PanelWindow {
        active: true
        wantsFocus: true
        
        // الطريقة الصحيحة لملء الشاشة في Quickshell
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        GuidePopup {
            anchors.fill: parent
        }
    }
}
