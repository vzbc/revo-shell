import QtQuick
import "../../"
import "../bar"
import "../shared"

BarButton {
    id: root
    icon: MicService.muted ? "󰍭" : "󰍬"
    active: popup.visible
    onClicked: popup.visible ? popup.close() : popup.open()

    WheelHandler {
        onWheel: function (w) {
            var audio = MicService.source?.audio;
            if (!audio)
                return;
            audio.volume = Math.max(0, Math.min(1.0, audio.volume + w.angleDelta.y / 1200.0));
        }
    }

    AnimatedPopup {
        id: popup
        anchorItem: root
        implicitWidth: Math.round(300 * UIScale.value)
        implicitHeight: Math.round(340 * UIScale.value)
        content: Component {
            Mic {}
        }
    }
}
