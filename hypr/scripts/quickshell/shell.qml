import QtQuick
import Quickshell
import "guide"

Quickshell.Shell {
    PanelWindow {
        active: true
        wantsFocus: true
        
        // الطريقة الصحيحة في كويك شيل لجعل النافذة ملء الشاشة (Fullscreen)
        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        anchors.right: true

        GuidePopup {
            anchors.fill: parent
        }
    }
}
